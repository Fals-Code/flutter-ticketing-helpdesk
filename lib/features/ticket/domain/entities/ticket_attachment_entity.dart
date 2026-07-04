import 'package:equatable/equatable.dart';

enum TicketAttachmentKind {
  image,
  document,
  unknown;

  static TicketAttachmentKind fromMimeType(String? mimeType) {
    final normalized = mimeType?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return TicketAttachmentKind.unknown;
    }
    if (normalized.startsWith('image/')) {
      return TicketAttachmentKind.image;
    }
    if (normalized == 'application/pdf' ||
        normalized == 'text/plain' ||
        normalized == 'application/msword' ||
        normalized ==
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document') {
      return TicketAttachmentKind.document;
    }
    return TicketAttachmentKind.unknown;
  }
}

class TicketAttachmentEntity extends Equatable {
  final String id;
  final String ticketId;
  final String? storagePath;
  final String fileName;
  final String mimeType;
  final String extension;
  final int sizeBytes;
  final String uploadedBy;
  final DateTime createdAt;
  final TicketAttachmentKind kind;
  final String? accessUrl;
  final bool isLegacyImage;

  const TicketAttachmentEntity({
    required this.id,
    required this.ticketId,
    required this.storagePath,
    required this.fileName,
    required this.mimeType,
    required this.extension,
    required this.sizeBytes,
    required this.uploadedBy,
    required this.createdAt,
    this.kind = TicketAttachmentKind.unknown,
    this.accessUrl,
    this.isLegacyImage = false,
  });

  bool get hasPersistedStoragePath =>
      storagePath != null && storagePath!.trim().isNotEmpty;

  bool get hasAccessUrl => accessUrl != null && accessUrl!.trim().isNotEmpty;

  bool get isImageLike {
    final normalizedMime = mimeType.trim().toLowerCase();
    if (normalizedMime.startsWith('image/')) {
      return true;
    }

    return switch (extension.trim().toLowerCase()) {
      'jpg' || 'jpeg' || 'png' || 'webp' || 'gif' || 'heic' || 'heif' => true,
      _ => false,
    };
  }

  bool get isDocumentLike {
    if (isImageLike) {
      return false;
    }

    final normalizedMime = mimeType.trim().toLowerCase();
    if (switch (normalizedMime) {
      'application/pdf' ||
      'text/plain' ||
      'application/msword' ||
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document' =>
        true,
      _ => false,
    }) {
      return true;
    }

    return switch (extension.trim().toLowerCase()) {
      'pdf' || 'txt' || 'doc' || 'docx' => true,
      _ => false,
    };
  }

  TicketAttachmentEntity copyWith({
    String? id,
    String? ticketId,
    String? storagePath,
    String? fileName,
    String? mimeType,
    String? extension,
    int? sizeBytes,
    String? uploadedBy,
    DateTime? createdAt,
    TicketAttachmentKind? kind,
    String? accessUrl,
    bool? isLegacyImage,
  }) {
    return TicketAttachmentEntity(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      storagePath: storagePath ?? this.storagePath,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      extension: extension ?? this.extension,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
      kind: kind ?? this.kind,
      accessUrl: accessUrl ?? this.accessUrl,
      isLegacyImage: isLegacyImage ?? this.isLegacyImage,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ticketId,
        storagePath,
        fileName,
        mimeType,
        extension,
        sizeBytes,
        uploadedBy,
        createdAt,
        kind,
        accessUrl,
        isLegacyImage,
      ];
}
