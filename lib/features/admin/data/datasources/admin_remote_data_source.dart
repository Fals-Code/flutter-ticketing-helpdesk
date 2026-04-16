import 'package:supabase_flutter/supabase_flutter.dart' as sup;
import '../models/admin_report_model.dart';
import '../../../auth/data/models/user_model.dart';

abstract class AdminRemoteDataSource {
  Future<List<UserModel>> getUsers();
  Future<void> updateUserRole(String userId, int newRole);
  Future<AdminReportModel> getAdminReports({DateTime? startDate, DateTime? endDate});
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
}
