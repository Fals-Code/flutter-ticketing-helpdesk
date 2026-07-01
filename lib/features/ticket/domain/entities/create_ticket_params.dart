import 'package:equatable/equatable.dart';

import 'local_attachment_candidate.dart';

enum CreateTicketProgressStage {
  validating,
  uploading,
  creatingTicket,
}

class CreateTicketProgress extends Equatable {
  final CreateTicketProgressStage stage;
  final String? currentFileName;
  final int uploadedCount;
  final int totalCount;

  const CreateTicketProgress({
    required this.stage,
    this.currentFileName,
    this.uploadedCount = 0,
    this.totalCount = 0,
  });

  @override
  List<Object?> get props => [
        stage,
        currentFileName,
        uploadedCount,
        totalCount,
      ];
}

typedef CreateTicketProgressCallback = void Function(
  CreateTicketProgress progress,
);

class CreateTicketParams extends Equatable {
  final String title;
  final String description;
  final String category;
  final List<LocalAttachmentCandidate> attachments;
  final String? clientTicketId;
  final CreateTicketProgressCallback? onProgress;

  const CreateTicketParams({
    required this.title,
    required this.description,
    required this.category,
    this.attachments = const [],
    this.clientTicketId,
    this.onProgress,
  });

  String get trimmedTitle => title.trim();
  String get trimmedDescription => description.trim();
  String get trimmedCategory => category.trim();

  @override
  List<Object?> get props => [
        trimmedTitle,
        trimmedDescription,
        trimmedCategory,
        attachments,
        clientTicketId,
      ];
}
