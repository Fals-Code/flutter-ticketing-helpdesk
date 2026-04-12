import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart' as sup;
import 'package:uuid/uuid.dart';
import '../models/ticket_model.dart';
import '../models/comment_model.dart';
import '../models/ticket_history_model.dart';

abstract class TicketRemoteDataSource {
  Future<List<TicketModel>> getTickets(int page, int limit, {String? searchQuery, String? category, String? status});
  Future<List<TicketModel>> getAllTickets(int page, int limit, {String? status, String? searchQuery, String? category});
  Future<List<Map<String, dynamic>>> getStaffUsers();
  Future<TicketModel> createTicket(TicketModel ticket, List<String> imagePaths);
  Future<TicketModel> getTicketDetail(String ticketId);
  Future<List<CommentModel>> getTicketComments(String ticketId);
  Future<CommentModel> addComment(CommentModel comment);
  Future<TicketModel> updateTicketStatus(String ticketId, String status);
  Future<TicketModel> assignTicket(String ticketId, String technicianId);
  Future<List<TicketHistoryModel>> getTicketHistory(String ticketId);
  Future<List<TicketHistoryModel>> getAllTicketHistory();
  Future<Map<String, int>> getTicketStats();
  Stream<List<TicketModel>> watchTickets();
}

class SupabaseTicketRemoteDataSourceImpl implements TicketRemoteDataSource {
  final sup.SupabaseClient supabaseClient;
  static const String _bucketName = 'tickets';

  SupabaseTicketRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<Map<String, int>> getTicketStats() async {
    try {
      final List<dynamic> response = await supabaseClient.rpc('get_ticket_stats');
      
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
        .select('*, assigned_profiles:assigned_to(full_name)')
        .eq('user_id', supabaseClient.auth.currentUser!.id);

    if (status != null && status != 'all') {
      query = query.eq('status', status.toLowerCase());
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

    return (response as List).map((json) => TicketModel.fromJson(json)).toList();
  }

  @override
  Future<List<TicketModel>> getAllTickets(int page, int limit, {String? status, String? searchQuery, String? category}) async {
    final from = page * limit;
    final to = from + limit - 1;

    var query = supabaseClient
        .from('tickets')
        .select('*, assigned_profiles:assigned_to(full_name)');
    
    if (status != null && status != 'all') {
      query = query.eq('status', status.toLowerCase());
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

    return (response as List).map((json) => TicketModel.fromJson(json)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getStaffUsers() async {
    final response = await supabaseClient
        .from('profiles')
        .select('id, full_name, email, role')
        .inFilter('role', ['technician', 'admin', 'helpdesk']);
    
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
    ticketData['images'] = uploadedUrls;

    final response = await supabaseClient
        .from('tickets')
        .insert(ticketData)
        .select()
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
        .select('*, assigned_profiles:assigned_to(full_name)')
        .eq('id', ticketId)
        .single();

    return TicketModel.fromJson(response);
  }

  @override
  Future<TicketModel> updateTicketStatus(String ticketId, String status) async {
    final response = await supabaseClient
        .from('tickets')
        .update({
          'status': status.toLowerCase(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', ticketId)
        .select('*, assigned_profiles:assigned_to(full_name)')
        .single();
    
    final updatedTicket = TicketModel.fromJson(response);

    // History is handled by DB Trigger, but we can verify or manual log if trigger doesn't exist
    await _logHistory(
      ticketId: ticketId,
      newStatus: status.toLowerCase(),
      changedBy: supabaseClient.auth.currentUser!.id,
    );

    // Notify User
    await _notifyUser(
      userId: updatedTicket.userId,
      title: 'Update Tiket #${ticketId.substring(0, 8).toUpperCase()}',
      message: 'Status tiket Anda kini ${status.toUpperCase()}',
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
        .select('*, assigned_profiles:assigned_to(full_name)')
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
          .select('*, profiles(full_name)')
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: false);
      
      return (response as List).map((json) => TicketHistoryModel.fromJson(json)).toList();
    }
  }

  @override
  Future<List<TicketHistoryModel>> getAllTicketHistory() async {
    try {
      final response = await supabaseClient
          .from('ticket_history')
          .select('*, profiles(full_name)')
          .order('created_at', ascending: false)
          .limit(50);
      
      return (response as List).map((json) => TicketHistoryModel.fromJson(json)).toList();
    } on sup.PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch global history: $e');
    }
  }

  @override
  Stream<List<TicketModel>> watchTickets() {
    return supabaseClient
        .from('tickets')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => TicketModel.fromJson(json)).toList());
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
    final response = await supabaseClient
        .from('comments')
        .insert(comment.toJson())
        .select('*, profiles(full_name, role)')
        .single();

    return CommentModel.fromJson(response);
  }
}
