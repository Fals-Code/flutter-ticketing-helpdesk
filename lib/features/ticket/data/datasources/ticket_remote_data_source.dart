import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sup;
import 'package:uuid/uuid.dart';
import '../models/ticket_model.dart';
import '../models/comment_model.dart';
import '../models/ticket_history_model.dart';
import 'package:uts/core/constants/enums.dart';

abstract class TicketRemoteDataSource {
  Future<List<TicketModel>> getTickets(int page, int limit, {String? searchQuery, String? category, String? status, DateTime? startDate, DateTime? endDate});
  Future<List<TicketModel>> getAllTickets(int page, int limit, {String? status, String? searchQuery, String? category, String? assignedToId, DateTime? startDate, DateTime? endDate});
  Future<List<Map<String, dynamic>>> getStaffUsers();
  Future<TicketModel> createTicket(TicketModel ticket, List<String> imagePaths);
  Future<TicketModel> getTicketDetail(String ticketId);
  Future<List<CommentModel>> getTicketComments(String ticketId);
  Future<CommentModel> addComment(CommentModel comment);
  Future<TicketModel> updateTicketStatus(String ticketId, TicketStatus status);
  Future<TicketModel> assignTicket(String ticketId, String technicianId);
  Future<TicketModel> submitRating(String ticketId, int rating, String feedback);
  Future<List<TicketHistoryModel>> getTicketHistory(String ticketId);
  Future<List<TicketHistoryModel>> getAllTicketHistory({String? changedBy, DateTime? startDate, DateTime? endDate});
  Future<Map<String, int>> getTicketStats({String? assignedToId});
  Stream<List<TicketModel>> watchTickets({String? userId, String? assignedToId});
  Stream<List<CommentModel>> watchTicketComments(String ticketId);
}

class SupabaseTicketRemoteDataSourceImpl implements TicketRemoteDataSource {
  final sup.SupabaseClient supabaseClient;
  static const String _bucketName = 'tickets';
  final Map<String, Map<String, dynamic>> _profileCache = {};

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
  Future<List<TicketModel>> getTickets(int page, int limit, {String? searchQuery, String? category, String? status, DateTime? startDate, DateTime? endDate}) async {
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
    if (startDate != null) {
      query = query.gte('created_at', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('created_at', endDate.toIso8601String());
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
  Future<List<TicketModel>> getAllTickets(int page, int limit, {String? status, String? searchQuery, String? category, String? assignedToId, DateTime? startDate, DateTime? endDate}) async {
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
    if (startDate != null) {
      query = query.gte('created_at', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('created_at', endDate.toIso8601String());
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
    try {
      for (var path in imagePaths) {
        final file = File(path);
        final fileExt = path.split('.').last;
        final fileName = '${const Uuid().v4()}.$fileExt';
        final storagePath = 'ticket_images/$fileName';

        await supabaseClient.storage.from(_bucketName).upload(storagePath, file);
        final url = supabaseClient.storage.from(_bucketName).getPublicUrl(storagePath);
        uploadedUrls.add(url);
      }
    } catch (e) {
      // If upload fails, we should ideally delete the ones already uploaded
      // but for now we just throw a descriptive error to prevent DB insertion
      throw Exception('Gagal mengunggah foto: $e');
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
    // 1. Get current status to check if closed
    final currentTicket = await getTicketDetail(ticketId);
    if (currentTicket.status == TicketStatus.closed) {
      throw Exception('Tiket yang sudah ditutup tidak dapat didelegasikan ulang.');
    }

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
  Future<TicketModel> submitRating(String ticketId, int rating, String feedback) async {
    try {
      final response = await supabaseClient
          .from('tickets')
          .update({
            'rating': rating,
            'feedback': feedback,
            'status': 'closed', // Auto close ticket after rating
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', ticketId)
          .select('*, profiles:user_id(*), technician:assigned_to(*)')
          .single();
      
      final updatedTicket = TicketModel.fromJson(response);

      // Notify User
      await _notifyUser(
        userId: updatedTicket.userId,
        title: 'Tiket Ditutup',
        message: 'Terima kasih atas penilaian Anda. Tiket ini telah ditutup.',
        ticketId: ticketId,
      );

      return updatedTicket;
    } on sup.PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to submit rating: $e');
    }
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
  Future<List<TicketHistoryModel>> getAllTicketHistory({String? changedBy, DateTime? startDate, DateTime? endDate}) async {
    try {
      var query = supabaseClient
          .from('ticket_history')
          .select('*, profiles:ticket_history_changed_by_fkey(full_name)');
      
      if (changedBy != null) {
        query = query.eq('changed_by', changedBy);
      }
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
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
    dynamic query = supabaseClient.from('tickets').stream(primaryKey: ['id']);

    if (userId != null) {
      query = query.eq('user_id', userId);
    }
    
    if (assignedToId != null) {
      query = query.eq('assigned_to', assignedToId);
    }

    return query.asyncMap((data) async {
      if (data.isEmpty) return [];

      // Hydration: Fetch profile information for the tickets in the stream
      final userIds = data
          .map((e) => e['user_id'] as String)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      if (userIds.isNotEmpty) {
        try {
          // Fetch profiles in batch
          final List<dynamic> profilesResponse = await supabaseClient
              .from('profiles')
              .select('id, full_name, role')
              .inFilter('id', userIds);

          final profileMap = {
            for (var profile in profilesResponse) profile['id']: profile
          };

          // Cache profiles while we are at it
          for (var profile in profilesResponse) {
            _profileCache[profile['id']] = profile;
          }

          return data.map((json) {
            final profile = profileMap[json['user_id']];
            if (profile != null) {
              json['profiles'] = profile;
            } else if (_profileCache.containsKey(json['user_id'])) {
              json['profiles'] = _profileCache[json['user_id']];
            }
            
            try {
              return TicketModel.fromJson(json);
            } catch (e) {
              debugPrint('Ticket Stream Mapping Error: $e');
              return null;
            }
          }).whereType<TicketModel>().toList();
        } catch (e) {
          debugPrint('Error hydrating ticket stream: $e');
        }
      }

      // Fallback if hydration fails or no user IDs
      return data.map((json) {
        try {
          return TicketModel.fromJson(json);
        } catch (e) {
          return null;
        }
      }).whereType<TicketModel>().toList();
    });
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

  @override
  Stream<List<CommentModel>> watchTicketComments(String ticketId) {
    return supabaseClient
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: true)
        .asyncMap((data) async {
          // 1. Parse raw comments
          final List<CommentModel> comments = data.map((json) {
            try {
              return CommentModel.fromJson(json);
            } catch (e) {
              debugPrint('Comment Stream Parsing Error: $e');
              return null;
            }
          }).whereType<CommentModel>().toList();

          if (comments.isEmpty) return comments;

          // 2. Identify unique user IDs that are not in cache
          final userIds = comments.map((c) => c.userId).toSet();
          final missingUserIds = userIds.where((id) => !_profileCache.containsKey(id)).toList();

          // 3. Fetch missing profiles
          if (missingUserIds.isNotEmpty) {
            try {
              final List<dynamic> profilesResponse = await supabaseClient
                  .from('profiles')
                  .select('id, full_name, role')
                  .inFilter('id', missingUserIds);
              
              for (var profile in profilesResponse) {
                _profileCache[profile['id']] = profile;
              }
            } catch (e) {
              debugPrint('Error fetching profiles for comments: $e');
            }
          }

          // 4. Enrich comments with cached profile data
          return comments.map((comment) {
            final profile = _profileCache[comment.userId];
            if (profile != null) {
              final roleInt = profile['role'] as int?;
              final roleName = roleInt != null 
                  ? UserRole.fromInt(roleInt).name 
                  : (profile['role']?.toString() ?? 'user');

              return comment.copyWith(
                userName: profile['full_name'] ?? 'Unknown',
                userRole: roleName,
              );
            }
            return comment;
          }).toList();
        });
  }
}
