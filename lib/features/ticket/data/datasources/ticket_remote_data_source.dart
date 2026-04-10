import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart' as sup;
import 'package:uuid/uuid.dart';
import '../models/ticket_model.dart';
import '../models/comment_model.dart';
import '../models/ticket_activity_model.dart';

abstract class TicketRemoteDataSource {
  Future<List<TicketModel>> getTickets(int page, int limit);
  Future<List<TicketModel>> getAllTickets(int page, int limit, {String? status});
  Future<List<Map<String, dynamic>>> getStaffUsers();
  Future<TicketModel> createTicket(TicketModel ticket, List<String> imagePaths);
  Future<TicketModel> getTicketDetail(String ticketId);
  Future<List<CommentModel>> getTicketComments(String ticketId);
  Future<CommentModel> addComment(CommentModel comment);
  Future<TicketModel> updateTicketStatus(String ticketId, String status);
  Future<TicketModel> assignTicket(String ticketId, String technicianId);
  Future<List<TicketActivityModel>> getTicketActivities(String ticketId);
  Future<List<TicketActivityModel>> getAllActivities();
}

class SupabaseTicketRemoteDataSourceImpl implements TicketRemoteDataSource {
  final sup.SupabaseClient supabaseClient;
  static const String _bucketName = 'tickets';

  SupabaseTicketRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<List<TicketModel>> getTickets(int page, int limit) async {
    final from = page * limit;
    final to = from + limit - 1;

    final response = await supabaseClient
        .from('tickets')
        .select('*, assigned_profiles:assigned_to(full_name)')
        .eq('user_id', supabaseClient.auth.currentUser!.id)
        .order('created_at', ascending: false)
        .range(from, to);

    return (response as List).map((json) => TicketModel.fromJson(json)).toList();
  }

  @override
  Future<List<TicketModel>> getAllTickets(int page, int limit, {String? status}) async {
    final from = page * limit;
    final to = from + limit - 1;

    var query = supabaseClient
        .from('tickets')
        .select('*, assigned_profiles:assigned_to(full_name)');
    
    if (status != null) {
      query = query.eq('status', status.toLowerCase());
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
    
    // Log Activity
    await _logActivity(
      ticketId: newTicket.id,
      activityType: 'created',
      description: 'Tiket berhasil dibuat',
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

    // Log Activity
    await _logActivity(
      ticketId: ticketId,
      activityType: 'status_updated',
      description: 'Status berubah menjadi ${status.toUpperCase()}',
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

    // Log Activity
    await _logActivity(
      ticketId: ticketId,
      activityType: 'assigned',
      description: 'Tiket ditugaskan kepada petugas baru',
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
  Future<List<TicketActivityModel>> getTicketActivities(String ticketId) async {
    final response = await supabaseClient
        .from('ticket_activities')
        .select('*, profiles(full_name)')
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => TicketActivityModel.fromJson(json)).toList();
  }

  @override
  Future<List<TicketActivityModel>> getAllActivities() async {
    final response = await supabaseClient
        .from('ticket_activities')
        .select('*, profiles(full_name)')
        .order('created_at', ascending: false)
        .limit(50);
    
    return (response as List).map((json) => TicketActivityModel.fromJson(json)).toList();
  }

  // Helper methods
  Future<void> _logActivity({
    required String ticketId,
    required String activityType,
    required String description,
  }) async {
    try {
      await supabaseClient.from('ticket_activities').insert({
        'ticket_id': ticketId,
        'user_id': supabaseClient.auth.currentUser!.id,
        'activity_type': activityType,
        'description': description,
      });
    } catch (e) {
      // Ignored: Activity logging shouldn't break the main flow
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
