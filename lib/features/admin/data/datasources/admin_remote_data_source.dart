import 'package:supabase_flutter/supabase_flutter.dart' as sup;
import '../models/admin_report_model.dart';
import '../../../auth/data/models/user_model.dart';
import '../models/app_settings_model.dart';

abstract class AdminRemoteDataSource {
  Future<List<UserModel>> getUsers();
  Future<void> updateUserRole(String userId, int newRole);
  Future<AdminReportModel> getAdminReports({DateTime? startDate, DateTime? endDate});
  Future<AppSettingsModel> getAppSettings();
  Future<void> updateAppSettings(AppSettingsModel settings);
}

class SupabaseAdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final sup.SupabaseClient supabaseClient;

  SupabaseAdminRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<List<UserModel>> getUsers() async {
    try {
      final response = await supabaseClient
          .from('profiles')
          .select('id, full_name, role, email')
          .order('full_name');
      
      return (response as List).map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil daftar pengguna: $e');
    }
  }

  @override
  Future<void> updateUserRole(String userId, int newRole) async {
    try {
      await supabaseClient
          .from('profiles')
          .update({'role': newRole})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Gagal memperbarui peran pengguna: $e');
    }
  }

  @override
  Future<AdminReportModel> getAdminReports({DateTime? startDate, DateTime? endDate}) async {
    try {
      final response = await supabaseClient.rpc(
        'get_admin_reports',
        params: {
          if (startDate != null) 'p_start_date': startDate.toIso8601String(),
          if (endDate != null) 'p_end_date': endDate.toIso8601String(),
        },
      );
      return AdminReportModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal mengambil laporan admin: $e');
    }
  }

  @override
  Future<AppSettingsModel> getAppSettings() async {
    try {
      final response = await supabaseClient
          .from('configs')
          .select('value')
          .eq('key', 'app_settings')
          .maybeSingle();

      if (response == null) {
        return const AppSettingsModel(
          maintenanceMode: false,
          slaHours: 4,
          autoAssign: true,
          defaultPriority: 'Medium',
        );
      }

      return AppSettingsModel.fromJson(response['value']);
    } catch (e) {
      throw Exception('Gagal mengambil pengaturan aplikasi: $e');
    }
  }

  @override
  Future<void> updateAppSettings(AppSettingsModel settings) async {
    try {
      await supabaseClient
          .from('configs')
          .upsert({
            'key': 'app_settings',
            'value': settings.toJson(),
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'key');
    } catch (e) {
      throw Exception('Gagal memperbarui pengaturan aplikasi: $e');
    }
  }
}
