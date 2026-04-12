import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/admin_usecases.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final GetUsersUseCase getUsersUseCase;
  final UpdateUserRoleUseCase updateUserRoleUseCase;
  final GetAdminReportsUseCase getAdminReportsUseCase;

  AdminBloc({
    required this.getUsersUseCase,
    required this.updateUserRoleUseCase,
    required this.getAdminReportsUseCase,
  }) : super(const AdminState()) {
    on<FetchAllUsersRequested>(_onFetchUsers);
    on<UpdateUserRoleRequested>(_onUpdateUserRole);
    on<FetchAdminReportsRequested>(_onFetchReports);
  }

  Future<void> _onFetchUsers(
    FetchAllUsersRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(status: AdminStatus.loading));
    final result = await getUsersUseCase(const NoParams());
    result.fold(
      (failure) => emit(state.copyWith(status: AdminStatus.error, errorMessage: failure.message)),
      (users) => emit(state.copyWith(status: AdminStatus.success, users: users)),
    );
  }

  Future<void> _onUpdateUserRole(
    UpdateUserRoleRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(status: AdminStatus.loading));
    final result = await updateUserRoleUseCase(UpdateRoleParams(
      userId: event.userId,
      newRole: event.newRole,
    ));
    result.fold(
      (failure) => emit(state.copyWith(status: AdminStatus.error, errorMessage: failure.message)),
      (_) {
        emit(state.copyWith(status: AdminStatus.success, successMessage: 'Peran pengguna berhasil diperbarui'));
        add(const FetchAllUsersRequested()); // Refresh list
      },
    );
  }

  Future<void> _onFetchReports(
    FetchAdminReportsRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(status: AdminStatus.loading));
    final result = await getAdminReportsUseCase(const NoParams());
    result.fold(
      (failure) => emit(state.copyWith(status: AdminStatus.error, errorMessage: failure.message)),
      (report) => emit(state.copyWith(status: AdminStatus.success, report: report)),
    );
  }
}
