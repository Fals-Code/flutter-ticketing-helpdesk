import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;
import 'package:equatable/equatable.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/notification_usecases.dart';
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

class DeleteNotificationsRequested extends NotificationEvent {
  final List<String> notificationIds;
  const DeleteNotificationsRequested(this.notificationIds);
  @override
  List<Object?> get props => [notificationIds];
}

class ResetNotificationState extends NotificationEvent {}

// State
class NotificationState extends Equatable {
  final bool isLoading;
  final List<NotificationEntity> notifications;
  final String? errorMessage;

  const NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.errorMessage,
  });

  NotificationState copyWith({
    bool? isLoading,
    List<NotificationEntity>? notifications,
    String? errorMessage,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, notifications, errorMessage];
}

// Bloc
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotifications getNotifications;
  final MarkNotificationAsRead markNotificationAsRead;
  final DeleteNotifications deleteNotifications;
  final WatchNotifications watchNotifications;
  final LocalNotificationService localNotificationService;
  StreamSubscription? _notificationSubscription;

  NotificationBloc({
    required this.getNotifications,
    required this.markNotificationAsRead,
    required this.deleteNotifications,
    required this.watchNotifications,
    required this.localNotificationService,
  }) : super(const NotificationState()) {
    on<FetchNotificationsRequested>(_onFetchNotifications);
    on<MarkReadRequested>(_onMarkRead);
    on<StartNotificationSubscription>(_onStartSubscription);
    on<NotificationStreamUpdated>(_onStreamUpdated);
    on<MarkAllReadRequested>(_onMarkAllRead);
    on<DeleteNotificationsRequested>(_onDeleteNotifications);
    on<ResetNotificationState>(_onResetState);
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
    // Detect new unread notifications to show popup
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

    emit(state.copyWith(notifications: event.notifications));
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
    // Optimistic local update first
    final originalList = state.notifications;
    final updatedList = originalList.map((n) {
      if (n.id == event.notificationId) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    emit(state.copyWith(notifications: updatedList));

    // Persist to database
    final result = await markNotificationAsRead(event.notificationId);
    result.fold(
      (failure) {
        // Revert on failure
        developer.log('Failed to mark notification as read! ${failure.message}', name: 'NotificationBloc');
        emit(state.copyWith(notifications: originalList));
      },
      (_) {
        // Already updated optimistically, nothing else needed
      },
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

    // Instant local feedback
    final updatedList = state.notifications.map((n) {
      if (!n.isRead) return n.copyWith(isRead: true);
      return n;
    }).toList();
    emit(state.copyWith(notifications: updatedList));

    // Persist ALL unread to database concurrently
    await Future.wait(
      unreadIds.map((id) => markNotificationAsRead(id)),
    );
  }

  Future<void> _onDeleteNotifications(
    DeleteNotificationsRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final originalList = state.notifications;
    final updatedList = originalList
        .where((n) => !event.notificationIds.contains(n.id))
        .toList();
    emit(state.copyWith(notifications: updatedList));

    final result = await deleteNotifications(event.notificationIds);
    result.fold(
      (failure) {
        developer.log('Failed to delete notifications! ${failure.message}', name: 'NotificationBloc');
        emit(state.copyWith(notifications: originalList));
      },
      (_) {},
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
