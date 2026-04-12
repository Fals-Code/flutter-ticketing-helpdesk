import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications();
  Future<void> markAsRead(String notificationId);
  Stream<List<NotificationModel>> watchNotifications();
}

class SupabaseNotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final SupabaseClient supabaseClient;

  SupabaseNotificationRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await supabaseClient
          .from('notifications')
          .select('*')
          .eq('user_id', supabaseClient.auth.currentUser!.id)
          .order('created_at', ascending: false);
      
      return (response as List).map((json) => NotificationModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      if (e.code == '42P01') {
        // Table doesn't exist yet, return empty list gracefully
        return [];
      }
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      return []; // Fallback for any other unexpected errors during initial setup
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await supabaseClient
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  @override
  Stream<List<NotificationModel>> watchNotifications() {
    try {
      return supabaseClient
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', supabaseClient.auth.currentUser!.id)
          .order('created_at', ascending: false)
          .map((data) => data.map((json) => NotificationModel.fromJson(json)).toList());
    } catch (e) {
      // Return empty stream if table missing or subscription fails
      return Stream.value([]);
    }
  }
}
