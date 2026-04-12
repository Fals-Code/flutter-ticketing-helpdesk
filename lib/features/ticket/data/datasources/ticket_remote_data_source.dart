import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sup;
import 'package:uuid/uuid.dart';
import '../models/ticket_model.dart';
import '../models/comment_model.dart';
import '../models/ticket_history_model.dart';
import 'package:uts/core/constants/enums.dart';

abstract class TicketRemoteDataSource {
  Future<List<TicketModel>> getTickets(int page, int limit, {String? searchQuery, String? category, String? status});
  Future<List<TicketModel>> getAllTickets(int page, int limit, {String? status, String? searchQuery, String? category, String? assignedToId});
  Future<List<Map<String, dynamic>>> getStaffUsers();
  Future<TicketModel> createTicket(TicketModel ticket, List<String> imagePaths);
  Future<TicketModel> getTicketDetail(String ticketId);
  Future<List<CommentModel>> getTicketComments(String ticketId);
  Future<CommentModel> addComment(CommentModel comment);
  Future<TicketModel> updateTicketStatus(String ticketId, TicketStatus status);
  Future<TicketModel> assignTicket(String ticketId, String technicianId);
  Future<List<TicketHistoryModel>> getTicketHistory(String ticketId);
  Future<List<TicketHistoryModel>> getAllTicketHistory({String? changedBy});
  Future<Map<String, int>> getTicketStats({String? assignedToId});
  Stream<List<TicketModel>> watchTickets({String? userId, String? assignedToId});
}

class SupabaseTicketRemoteDataSourceImpl implements TicketRemoteDataSource {
  final sup.SupabaseClient supabaseClient;
  static const String _bucketName = 'tickets';

  SupabaseTicketRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<Map<String, int>> getTicketStats({String? assignedToId}) async {
    try {
      final List<dynamic> response = await supabaseClient.rpc(
        'get_ticket_stats',
        params: assignedToId != null ? {'for_staff_id': assignedToId} : {},
      );
      
      final Map<String, int> stats = {
        'total': 0,
        'open': 0,
        'in_progress': 0,
        'resolved': 0,
        'closed': 0,
      };

      for (var row in response) {
        final String status = (row['status'] as String).toLowerCase();
        final int count = row['count'] as int;
        
        if (stats.containsKey(status)) {
          stats[status] = count;
        }
        stats['total'] = (stats['total'] ?? 0) + count;
      }

      return stats;
    } on sup.PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch stats: $e');
    }
  }

  @override
  Future<List<TicketModel>> getTickets(int page, int limit, {String? searchQuery, String? category, String? status}) async {
    final from = page * limit;
    final to = from + limit - 1;

    var query = supabaseClient
        .from('tickets')
        .select('*, profiles:user_id(*), technician:assigned_to(*)')
        .eq('user_id', supabaseClient.auth.currentUser!.id);

    if (status != null && status != 'all') {
      if (status.contains(',')) {
        query = query.inFilter('status', status.split(',').map((s) => s.trim().toLowerCase()).toList());
      } else {
        query = query.eq('status', status.toLowerCase());
      }
    }
    if (category != null) {
      query = query.eq('category', category);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or('title.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(from, to);

    return (response as List).map((json) {
      try {
        return TicketModel.fromJson(json);
      } catch (e) {
        debugPrint('Error parsing ticket: $e');
        return null;
      }
    }).whereType<TicketModel>().toList();
  }

  @override
  Future<List<TicketModel>> getAllTickets(int page, int limit, {String? status, String? searchQuery, String? category, String? assignedToId}) async {
    final from = page * limit;
    final to = from + limit - 1;

    var query = supabaseClient
        .from('tickets')
        .select('*, profiles:user_id(*), technician:assigned_to(*)');

    if (assignedToId != null) {
      query = query.eq('assigned_to', assignedToId);
    }
    
    if (status != null && status != 'all') {
      if (status.contains(',')) {
        query = query.inFilter('status', status.split(',').map((s) => s.trim().toLowerCase()).toList());
      } else {
        query = query.eq('status', status.toLowerCase());
      }
    }
    if (category != null) {
      query = query.eq('category', category);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or('title.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(from, to);

    return (response as List).map((json) {
      try {
        return TicketModel.fromJson(json);
      } catch (e) {
        debugPrint('Error parsing ticket: $e');
        return null;
      }
    }).whereType<TicketModel>().toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getStaffUsers() async {
    final response = await supabaseClient
        .from('profiles')
        .select('id, full_name, email, role')
        .eq('role', 2);
    
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<TicketModel> createTicket(TicketModel ticket, List<String> imagePaths) async {
    List<String> uploadedUrls = [];

    // Upload images to Supabase Storage
    for (var path in imagePaths) {
      final file = File(path);
      final fileExt = path.split('.').last;
      final fileName = '${const Uuid().v4()}.$fileExt';
      final storagePath = 'ticket_images/$fileName';

      await supabaseClient.storage.from(_bucketName).upload(storagePath, file);
      final url = supabaseClient.storage.from(_bucketName).getPublicUrl(storagePath);
      uploadedUrls.add(url);
    }

    final ticketData = ticket.toJson();
    // Injection of current authenticated user ID
    ticketData['user_id'] = supabaseClient.auth.currentUser!.id;
    ticketData['images'] = uploadedUrls;

    final response = await supabaseClient
        .from('tickets')
        .insert(ticketData)
        .select('*, profiles:user_id(*), technician:assigned_to(*)')
        .single();

    final newTicket = TicketModel.fromJson(response);
    
    // History is handled by DB Trigger usually, but if manual:
    await _logHistory(
      ticketId: newTicket.id,
      newStatus: 'open',
      changedBy: supabaseClient.auth.currentUser!.id,
    );

    return newTicket;
  }

  @override
  Future<TicketModel> getTicketDetail(String ticketId) async {
    final response = await supabaseClient
        .from('tickets')
        .select('*, profiles:user_id(*), technician:assigned_to(*)')
        .eq('id', ticketId)
        .single();

    return TicketModel.fromJson(response);
  }

  @override
  Future<TicketModel> updateTicketStatus(String ticketId, TicketStatus status) async {
    final response = await supabaseClient
        .from('tickets')
        .update({
          'status': status.dbValue,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', ticketId)
        .select('*, profiles:user_id(*), technician:assigned_to(*)')
        .single();
    
    final updatedTicket = TicketModel.fromJson(response);

    // History is handled by DB Trigger, but we can verify or manual log if trigger doesn't exist
    await _logHistory(
      ticketId: ticketId,
      newStatus: status.dbValue,
      changedBy: supabaseClient.auth.currentUser!.id,
    );

    // Notify User
    await _notifyUser(
      userId: updatedTicket.userId,
      title: 'Update Tiket #${ticketId.substring(0, 8).toUpperCase()}',
      message: 'Status tiket Anda kini ${status.label.toUpperCase()}',
      ticketId: ticketId,
    );

    return updatedTicket;
  }

  @override
  Future<TicketModel> assignTicket(String ticketId, String technicianId) async {
    final response = await supabaseClient
        .from('tickets')
        .update({
          'assigned_to': technicianId,
          'status': 'in_progress', // Auto update status to In Progress when assigned
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', ticketId)
        .select('*, profiles:user_id(*), technician:assigned_to(*)')
        .single();
    
    final updatedTicket = TicketModel.fromJson(response);

    // History
    await _logHistory(
      ticketId: ticketId,
      newStatus: 'in_progress',
      changedBy: supabaseClient.auth.currentUser!.id,
    );

    // Notify User
    await _notifyUser(
      userId: updatedTicket.userId,
      title: 'Update Penanganan Tiket',
      message: 'Petugas sedang memproses tiket Anda.',
      ticketId: ticketId,
    );

    return updatedTicket;
  }

  @override
  Future<List<TicketHistoryModel>> getTicketHistory(String ticketId) async {
    try {
      final response = await supabaseClient
          .from('ticket_history')
          .select('*, profiles!ticket_history_changed_by_fkey(full_name)')
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: false);
      
      return (response as List).map((json) => TicketHistoryModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<TicketHistoryModel>> getAllTicketHistory({String? changedBy}) async {
    try {
      var query = supabaseClient
          .from('ticket_history')
          .select('*, profiles:ticket_history_changed_by_fkey(full_name)');
      
      if (changedBy != null) {
        query = query.eq('changed_by', changedBy);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(50);
      
      return (response as List).map((json) => TicketHistoryModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<List<TicketModel>> watchTickets({String? userId, String? assignedToId}) {
    // We use a broader stream and filter on the client to avoid type errors 
    // with SupabaseStreamFilterBuilder which often breaks during assignment.
    return supabaseClient
        .from('tickets')
        .stream(primaryKey: ['id'])
        .map((data) {
          var filtered = data;
          
          if (userId != null) {
            filtered = filtered.where((row) => row['user_id'] == userId).toList();
          }
          
          if (assignedToId != null) {
            filtered = filtered.where((row) => row['assigned_to'] == assignedToId).toList();
          }

          // Sort by created_at descending (newest first)
          filtered.sort((a, b) {
            final aTime = DateTime.parse(a['created_at']);
            final bTime = DateTime.parse(b['created_at']);
            return bTime.compareTo(aTime);
          });

          return filtered.map((json) {
            try {
              return TicketModel.fromJson(json);
            } catch (e) {
              debugPrint('Stream Mapping Error: $e');
              return null;
            }
          }).whereType<TicketModel>().toList();
        });
  }

  // Helper methods
  Future<void> _logHistory({
    required String ticketId,
    required String newStatus,
    required String changedBy,
    String? oldStatus,
  }) async {
    try {
      await supabaseClient.from('ticket_history').insert({
        'ticket_id': ticketId,
        'old_status': oldStatus,
        'new_status': newStatus,
        'changed_by': changedBy,
      });
    } catch (e) {
      // Ignored: History logging issues shouldn't break the main flow if triggers fail
    }
  }

  Future<void> _notifyUser({
    required String userId,
    required String title,
    required String message,
    String? ticketId,
  }) async {
    try {
      await supabaseClient.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'ticket_id': ticketId,
        'is_read': false,
      });
    } catch (e) {
      // Ignored: Notifying shouldn't break the main flow
    }
  }

  @override
  Future<List<CommentModel>> getTicketComments(String ticketId) async {
    final response = await supabaseClient
        .from('comments')
        .select('*, profiles(full_name, role)')
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: true);

    return (response as List).map((json) => CommentModel.fromJson(json)).toList();
  }

  @override
  Future<CommentModel> addComment(CommentModel comment) async {
    final commentData = comment.toJson();
    // Injection of current authenticated user ID
    commentData['user_id'] = supabaseClient.auth.currentUser!.id;
    
    final response = await supabaseClient
        .from('comments')
        .insert(commentData)
        .select('*, profiles(full_name, role)')
        .single();

    return CommentModel.fromJson(response);
  }
}
