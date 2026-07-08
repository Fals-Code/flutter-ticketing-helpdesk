import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications();
  Future<void> markAsRead(String notificationId);
  Stream<List<NotificationModel>> watchNotifications();
  Future<void> deleteNotification(String notificationId);
  Future<void> deleteNotifications(List<String> notificationIds);
  Future<void> deleteAllNotifications();
}

class SupabaseNotificationRemoteDataSourceImpl
    implements NotificationRemoteDataSource {
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

      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      if (e.code == '42P01') {
        return [];
      }
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      final currentUserId = supabaseClient.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User belum login.');
      }

      final response = await supabaseClient
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', currentUserId)
          .select();

      if ((response as List).isEmpty) {
        throw Exception(
          'No rows updated. Check RLS policies for notifications table.',
        );
      }
    } on PostgrestException catch (e) {
      throw Exception(
        'Database error marking read: ${e.message} (code: ${e.code})',
      );
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  @override
  Stream<List<NotificationModel>> watchNotifications() {
    try {
      final currentUserId = supabaseClient.auth.currentUser?.id;
      if (currentUserId == null) {
        return Stream.value([]);
      }

      return supabaseClient
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false)
          .map((data) => (data as List)
              .map((json) => NotificationModel.fromJson(json))
              .toList());
    } catch (e) {
      return Stream.value([]);
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      final currentUserId = supabaseClient.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User belum login.');
      }

      final response = await supabaseClient
          .from('notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', currentUserId)
          .select();

      if ((response as List).isEmpty) {
        throw Exception(
          'Notifikasi tidak ditemukan atau izin dihapus ditolak (RLS).',
        );
      }
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message} (code: ${e.code})');
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  @override
  Future<void> deleteNotifications(List<String> notificationIds) async {
    try {
      final currentUserId = supabaseClient.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User belum login.');
      }

      final response = await supabaseClient
          .from('notifications')
          .delete()
          .inFilter('id', notificationIds)
          .eq('user_id', currentUserId)
          .select();

      if ((response as List).isEmpty) {
        throw Exception(
          'Tidak ada notifikasi yang berhasil dihapus. Cek izin RLS.',
        );
      }
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message} (code: ${e.code})');
    } catch (e) {
      throw Exception('Failed to delete notifications: $e');
    }
  }

  @override
  Future<void> deleteAllNotifications() async {
    try {
      final currentUserId = supabaseClient.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User belum login.');
      }

      await supabaseClient
          .from('notifications')
          .delete()
          .eq('user_id', currentUserId);
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message} (code: ${e.code})');
    } catch (e) {
      throw Exception('Failed to delete all notifications: $e');
    }
  }
}
