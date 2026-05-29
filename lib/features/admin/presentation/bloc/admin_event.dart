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

class UpdateUserDetailsRequested extends AdminEvent {
  final String userId;
  final String fullName;
  final String email;

  const UpdateUserDetailsRequested({
    required this.userId,
    required this.fullName,
    required this.email,
  });

  @override
  List<Object?> get props => [userId, fullName, email];
}

class FetchAdminReportsRequested extends AdminEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const FetchAdminReportsRequested({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}
