import 'package:equatable/equatable.dart';

enum DeleteTicketCleanupStatus {
  deletedAndCleaned,
  deletedWithCleanupPending,
}

class DeleteTicketResult extends Equatable {
  final String ticketId;
  final DeleteTicketCleanupStatus cleanupStatus;
  final List<String> storagePaths;
  final List<String> failedPaths;

  const DeleteTicketResult({
    required this.ticketId,
    required this.cleanupStatus,
    this.storagePaths = const [],
    this.failedPaths = const [],
  });

  bool get hasCleanupPending =>
      cleanupStatus == DeleteTicketCleanupStatus.deletedWithCleanupPending;

  @override
  List<Object?> get props => [
        ticketId,
        cleanupStatus,
        storagePaths,
        failedPaths,
      ];
}
