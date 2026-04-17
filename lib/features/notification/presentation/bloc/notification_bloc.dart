import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;
import 'package:equatable/equatable.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/notification_usecases.dart';
import '../../domain/usecases/delete_notification_usecases.dart';
import 'package:uts/core/services/local_notification_service.dart';

// Events
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class FetchNotificationsRequested extends NotificationEvent {}

class MarkReadRequested extends NotificationEvent {
  final String notificationId;
  const MarkReadRequested(this.notificationId);
  @override
  List<Object?> get props => [notificationId];
}

class StartNotificationSubscription extends NotificationEvent {}

class NotificationStreamUpdated extends NotificationEvent {
  final List<NotificationEntity> notifications;
  const NotificationStreamUpdated(this.notifications);
  @override
  List<Object?> get props => [notifications];
}

class MarkAllReadRequested extends NotificationEvent {}

class ResetNotificationState extends NotificationEvent {}

// New Selection Events
class ToggleSelectionModeRequested extends NotificationEvent {}

class ToggleNotificationSelectionRequested extends NotificationEvent {
  final String notificationId;
  const ToggleNotificationSelectionRequested(this.notificationId);
  @override
  List<Object?> get props => [notificationId];
}

class SelectAllNotificationsRequested extends NotificationEvent {}

class DeleteSelectedNotificationsRequested extends NotificationEvent {}

class DeleteAllNotificationsRequested extends NotificationEvent {}

// State
class NotificationState extends Equatable {
  final bool isLoading;
  final List<NotificationEntity> notifications;
  final String? errorMessage;
  final String? successMessage;
  final bool selectionMode;
  final Set<String> selectedIds;

  const NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.errorMessage,
    this.successMessage,
    this.selectionMode = false,
    this.selectedIds = const {},
  });

  NotificationState copyWith({
    bool? isLoading,
    List<NotificationEntity>? notifications,
    String? errorMessage,
    String? successMessage,
    bool? selectionMode,
    Set<String>? selectedIds,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      selectionMode: selectionMode ?? this.selectionMode,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }

  @override
  List<Object?> get props => [isLoading, notifications, errorMessage, successMessage, selectionMode, selectedIds];
}

// Bloc
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotifications getNotifications;
  final MarkNotificationAsRead markNotificationAsRead;
  final WatchNotifications watchNotifications;
  final DeleteNotification deleteNotification;
  final DeleteMultipleNotifications deleteMultipleNotifications;
  final DeleteAllNotifications deleteAllNotifications;
  final LocalNotificationService localNotificationService;
  StreamSubscription? _notificationSubscription;

  NotificationBloc({
    required this.getNotifications,
    required this.markNotificationAsRead,
    required this.watchNotifications,
    required this.deleteNotification,
    required this.deleteMultipleNotifications,
    required this.deleteAllNotifications,
    required this.localNotificationService,
  }) : super(const NotificationState()) {
    on<FetchNotificationsRequested>(_onFetchNotifications);
    on<MarkReadRequested>(_onMarkRead);
    on<StartNotificationSubscription>(_onStartSubscription);
    on<NotificationStreamUpdated>(_onStreamUpdated);
    on<MarkAllReadRequested>(_onMarkAllRead);
    on<ResetNotificationState>(_onResetState);
    
    // Selection handlers
    on<ToggleSelectionModeRequested>(_onToggleSelectionMode);
    on<ToggleNotificationSelectionRequested>(_onToggleSelection);
    on<SelectAllNotificationsRequested>(_onSelectAll);
    on<DeleteSelectedNotificationsRequested>(_onDeleteSelected);
    on<DeleteAllNotificationsRequested>(_onDeleteAll);
  }

  void _onStartSubscription(
    StartNotificationSubscription event,
    Emitter<NotificationState> emit,
  ) {
    _notificationSubscription?.cancel();
    _notificationSubscription = watchNotifications().listen(
      (notifications) => add(NotificationStreamUpdated(notifications)),
    );
  }

  void _onStreamUpdated(
    NotificationStreamUpdated event,
    Emitter<NotificationState> emit,
  ) {
    final currentIds = state.notifications.map((n) => n.id).toSet();

    for (var notification in event.notifications) {
      if (!notification.isRead && !currentIds.contains(notification.id)) {
        localNotificationService.showNotification(
          id: notification.id.hashCode,
          title: notification.title,
          body: notification.message,
          payload: '${notification.id}|${notification.ticketId ?? ""}',
        );
      }
    }

    emit(state.copyWith(
      notifications: event.notifications,
      clearError: true, 
      clearSuccess: true,
    ));
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    return super.close();
  }

  Future<void> _onFetchNotifications(
    FetchNotificationsRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final result = await getNotifications();
    result.fold(
      (failure) => emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Gagal mengambil notifikasi')),
      (notifications) =>
          emit(state.copyWith(isLoading: false, notifications: notifications)),
    );
  }

  Future<void> _onMarkRead(
    MarkReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final originalList = state.notifications;
    final updatedList = originalList.map((n) {
      if (n.id == event.notificationId) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    emit(state.copyWith(notifications: updatedList));

    final result = await markNotificationAsRead(event.notificationId);
    result.fold(
      (failure) {
        developer.log('Failed to mark notification as read! ${failure.message}', name: 'NotificationBloc');
        emit(state.copyWith(notifications: originalList));
      },
      (_) {},
    );
  }

  Future<void> _onMarkAllRead(
    MarkAllReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final unreadIds = state.notifications
        .where((n) => !n.isRead)
        .map((n) => n.id)
        .toList();
    if (unreadIds.isEmpty) return;

    final updatedList = state.notifications.map((n) {
      if (!n.isRead) return n.copyWith(isRead: true);
      return n;
    }).toList();
    emit(state.copyWith(notifications: updatedList, successMessage: 'Semua notifikasi ditandai dibaca'));

    await Future.wait(
      unreadIds.map((id) => markNotificationAsRead(id)),
    );
  }

  // Selection Logic
  void _onToggleSelectionMode(ToggleSelectionModeRequested event, Emitter<NotificationState> emit) {
    final newMode = !state.selectionMode;
    emit(state.copyWith(
      selectionMode: newMode,
      selectedIds: newMode ? {} : {}, // Clear on close
    ));
  }

  void _onToggleSelection(ToggleNotificationSelectionRequested event, Emitter<NotificationState> emit) {
    final current = Set<String>.from(state.selectedIds);
    if (current.contains(event.notificationId)) {
      current.remove(event.notificationId);
    } else {
      current.add(event.notificationId);
    }
    emit(state.copyWith(selectedIds: current));
  }

  void _onSelectAll(SelectAllNotificationsRequested event, Emitter<NotificationState> emit) {
    if (state.selectedIds.length == state.notifications.length) {
      emit(state.copyWith(selectedIds: {}));
    } else {
      final allIds = state.notifications.map((n) => n.id).toSet();
      emit(state.copyWith(selectedIds: allIds));
    }
  }

  Future<void> _onDeleteSelected(DeleteSelectedNotificationsRequested event, Emitter<NotificationState> emit) async {
    if (state.selectedIds.isEmpty) return;
    
    final idsToDelete = List<String>.from(state.selectedIds);
    emit(state.copyWith(isLoading: true, clearSuccess: true, clearError: true));
    
    final result = await deleteMultipleNotifications(idsToDelete);
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (_) {
        emit(state.copyWith(
          isLoading: false,
          notifications: [], // Optimistically clear
          selectionMode: false,
          selectedIds: {},
          successMessage: '${idsToDelete.length} notifikasi berhasil dihapus',
        ));
        add(FetchNotificationsRequested());
      },
    );
  }

  Future<void> _onDeleteAll(DeleteAllNotificationsRequested event, Emitter<NotificationState> emit) async {
    emit(state.copyWith(isLoading: true, clearSuccess: true, clearError: true));
    final result = await deleteAllNotifications();
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (_) {
        emit(state.copyWith(
          isLoading: false,
          notifications: [], // Optimistically clear
          selectionMode: false,
          selectedIds: {},
          successMessage: 'Semua notifikasi berhasil dihapus',
        ));
        add(FetchNotificationsRequested());
      },
    );
  }

  Future<void> _onResetState(
    ResetNotificationState event,
    Emitter<NotificationState> emit,
  ) async {
    _notificationSubscription?.cancel();
    emit(const NotificationState());
  }
}
