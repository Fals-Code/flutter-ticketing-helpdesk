import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/notification_usecases.dart';

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
  final WatchNotifications watchNotifications;
  StreamSubscription? _notificationSubscription;

  NotificationBloc({
    required this.getNotifications,
    required this.markNotificationAsRead,
    required this.watchNotifications,
  }) : super(const NotificationState()) {
    on<FetchNotificationsRequested>(_onFetchNotifications);
    on<MarkReadRequested>(_onMarkRead);
    on<StartNotificationSubscription>(_onStartSubscription);
    on<NotificationStreamUpdated>(_onStreamUpdated);
    on<MarkAllReadRequested>(_onMarkAllRead);
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
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: 'Gagal mengambil notifikasi')),
      (notifications) => emit(state.copyWith(isLoading: false, notifications: notifications)),
    );
  }

  Future<void> _onMarkRead(
    MarkReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await markNotificationAsRead(event.notificationId);
    result.fold(
      (failure) => null, // Silently fail or handle error
      (_) {
        final updatedList = state.notifications.map((n) {
          if (n.id == event.notificationId) {
            return NotificationEntity(
              id: n.id,
              userId: n.userId,
              title: n.title,
              message: n.message,
              ticketId: n.ticketId,
              isRead: true,
              createdAt: n.createdAt,
            );
          }
          return n;
        }).toList();
        emit(state.copyWith(notifications: updatedList));
      },
    );
  }

  Future<void> _onMarkAllRead(
    MarkAllReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final unreadIds = state.notifications.where((n) => !n.isRead).map((n) => n.id).toList();
    if (unreadIds.isEmpty) return;

    // Instant local feedback
    final updatedList = state.notifications.map((n) {
      if (!n.isRead) return n.copyWith(isRead: true);
      return n;
    }).toList();
    emit(state.copyWith(notifications: updatedList));

    // Persist in background
    for (var id in unreadIds) {
      await markNotificationAsRead(id);
    }
  }

  Future<void> _onResetState(
    ResetNotificationState event,
    Emitter<NotificationState> emit,
  ) async {
    _notificationSubscription?.cancel();
    emit(const NotificationState());
  }
}
