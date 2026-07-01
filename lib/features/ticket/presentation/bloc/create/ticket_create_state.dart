import 'package:equatable/equatable.dart';

import '../../../domain/entities/local_attachment_candidate.dart';
import '../../../domain/entities/ticket_entity.dart';
import '../../../domain/entities/create_ticket_params.dart';

enum TicketCreateStatus {
  initial,
  editing,
  validating,
  uploading,
  creatingTicket,
  success,
  validationFailure,
  uploadFailure,
  createFailure,
  compensationFailure,
}

class TicketCreateState extends Equatable {
  final TicketCreateStatus status;
  final List<LocalAttachmentCandidate> attachments;
  final TicketEntity? ticket;
  final String? message;
  final String? currentFileName;
  final int uploadedCount;
  final int totalCount;

  const TicketCreateState({
    this.status = TicketCreateStatus.initial,
    this.attachments = const [],
    this.ticket,
    this.message,
    this.currentFileName,
    this.uploadedCount = 0,
    this.totalCount = 0,
  });

  bool get isBusy =>
      status == TicketCreateStatus.validating ||
      status == TicketCreateStatus.uploading ||
      status == TicketCreateStatus.creatingTicket;

  TicketCreateState copyWith({
    TicketCreateStatus? status,
    List<LocalAttachmentCandidate>? attachments,
    TicketEntity? ticket,
    String? message,
    String? currentFileName,
    int? uploadedCount,
    int? totalCount,
    bool clearTicket = false,
    bool clearMessage = false,
    bool clearCurrentFileName = false,
  }) {
    return TicketCreateState(
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
      ticket: clearTicket ? null : (ticket ?? this.ticket),
      message: clearMessage ? null : (message ?? this.message),
      currentFileName: clearCurrentFileName
          ? null
          : (currentFileName ?? this.currentFileName),
      uploadedCount: uploadedCount ?? this.uploadedCount,
      totalCount: totalCount ?? this.totalCount,
    );
  }

  TicketCreateState applyProgress(CreateTicketProgress progress) {
    return copyWith(
      status: switch (progress.stage) {
        CreateTicketProgressStage.validating => TicketCreateStatus.validating,
        CreateTicketProgressStage.uploading => TicketCreateStatus.uploading,
        CreateTicketProgressStage.creatingTicket =>
          TicketCreateStatus.creatingTicket,
      },
      currentFileName: progress.currentFileName,
      uploadedCount: progress.uploadedCount,
      totalCount: progress.totalCount,
      clearMessage: true,
    );
  }

  @override
  List<Object?> get props => [
        status,
        attachments,
        ticket,
        message,
        currentFileName,
        uploadedCount,
        totalCount,
      ];
}
