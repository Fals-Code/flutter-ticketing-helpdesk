import 'package:equatable/equatable.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

class FetchAllUsersRequested extends AdminEvent {
  const FetchAllUsersRequested();
}

class UpdateUserRoleRequested extends AdminEvent {
  final String userId;
  final int newRole;

  const UpdateUserRoleRequested({
    required this.userId,
    required this.newRole,
  });

  @override
  List<Object?> get props => [userId, newRole];
}

class FetchAdminReportsRequested extends AdminEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const FetchAdminReportsRequested({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}
