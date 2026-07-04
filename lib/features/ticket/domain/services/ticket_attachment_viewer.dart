import 'package:equatable/equatable.dart';

import '../entities/ticket_attachment_entity.dart';

enum TicketAttachmentActionStatus {
  opened,
  fileNotFound,
  accessDenied,
  offline,
  noAppFound,
  failed,
  unsupported,
  busy,
}

class TicketAttachmentActionResult extends Equatable {
  final TicketAttachmentActionStatus status;
  final String message;
  final String? localPath;

  const TicketAttachmentActionResult({
    required this.status,
    required this.message,
    this.localPath,
  });

  const TicketAttachmentActionResult.opened({
    String? localPath,
    String message = 'Lampiran dibuka.',
  }) : this(
          status: TicketAttachmentActionStatus.opened,
          message: message,
          localPath: localPath,
        );

  const TicketAttachmentActionResult.fileNotFound({
    String message = 'File tidak ditemukan.',
  }) : this(
          status: TicketAttachmentActionStatus.fileNotFound,
          message: message,
        );

  const TicketAttachmentActionResult.accessDenied({
    String message = 'Akses lampiran ditolak.',
  }) : this(
          status: TicketAttachmentActionStatus.accessDenied,
          message: message,
        );

  const TicketAttachmentActionResult.offline({
    String message = 'Anda sedang offline.',
  }) : this(
          status: TicketAttachmentActionStatus.offline,
          message: message,
        );

  const TicketAttachmentActionResult.noAppFound({
    String message = 'Tidak ada aplikasi pembuka yang tersedia.',
  }) : this(
          status: TicketAttachmentActionStatus.noAppFound,
          message: message,
        );

  const TicketAttachmentActionResult.failed({
    String message = 'Gagal membuka lampiran.',
  }) : this(
          status: TicketAttachmentActionStatus.failed,
          message: message,
        );

  const TicketAttachmentActionResult.unsupported({
    String message = 'Lampiran ini tidak didukung.',
  }) : this(
          status: TicketAttachmentActionStatus.unsupported,
          message: message,
        );

  const TicketAttachmentActionResult.busy({
    String message = 'Lampiran sedang diproses.',
  }) : this(
          status: TicketAttachmentActionStatus.busy,
          message: message,
        );

  bool get isSuccess => status == TicketAttachmentActionStatus.opened;

  @override
  List<Object?> get props => [status, message, localPath];
}

abstract class TicketAttachmentViewerDataSource {
  Future<List<Map<String, dynamic>>> hydrateAttachmentPayloads(
    List<Map<String, dynamic>> attachments, {
    Duration signedUrlTtl = const Duration(minutes: 12),
  });

  Future<TicketAttachmentActionResult> openAttachment(
    TicketAttachmentEntity attachment,
  );
}
