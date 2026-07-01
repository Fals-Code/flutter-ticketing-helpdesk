import 'package:equatable/equatable.dart';

import '../../../domain/entities/local_attachment_candidate.dart';

abstract class TicketCreateEvent extends Equatable {
  const TicketCreateEvent();

  @override
  List<Object?> get props => [];
}

class SubmitTicketCreateRequested extends TicketCreateEvent {
  final String title;
  final String description;
  final String category;
  final List<LocalAttachmentCandidate> attachments;

  const SubmitTicketCreateRequested({
    required this.title,
    required this.description,
    required this.category,
    required this.attachments,
  });

  @override
  List<Object?> get props => [
        title,
        description,
        category,
        attachments,
      ];
}

class TicketCreateResetRequested extends TicketCreateEvent {
  const TicketCreateResetRequested();
}
