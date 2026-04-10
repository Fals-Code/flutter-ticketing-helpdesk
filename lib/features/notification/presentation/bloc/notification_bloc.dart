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

  NotificationBloc({
    required this.getNotifications,
    required this.markNotificationAsRead,
  }) : super(const NotificationState()) {
    on<FetchNotificationsRequested>(_onFetchNotifications);
    on<MarkReadRequested>(_onMarkRead);
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
}
