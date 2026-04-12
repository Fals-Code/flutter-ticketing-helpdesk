import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/admin_report_entity.dart';

enum AdminStatus { initial, loading, success, error }

class AdminState extends Equatable {
  final AdminStatus status;
  final List<AuthUser> users;
  final AdminReport? report;
  final String? errorMessage;
  final String? successMessage;

  const AdminState({
    this.status = AdminStatus.initial,
    this.users = const [],
    this.report,
    this.errorMessage,
    this.successMessage,
  });

  AdminState copyWith({
    AdminStatus? status,
    List<AuthUser>? users,
    AdminReport? report,
    String? errorMessage,
    String? successMessage,
  }) {
    return AdminState(
      status: status ?? this.status,
      users: users ?? this.users,
      report: report ?? this.report,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [status, users, report, errorMessage, successMessage];
}
