import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications();
  Future<void> markAsRead(String notificationId);
}

class SupabaseNotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final SupabaseClient supabaseClient;

  SupabaseNotificationRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<List<NotificationModel>> getNotifications() async {
    final response = await supabaseClient
        .from('notifications')
        .select('*')
        .eq('user_id', supabaseClient.auth.currentUser!.id)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => NotificationModel.fromJson(json)).toList();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await supabaseClient
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }
}
