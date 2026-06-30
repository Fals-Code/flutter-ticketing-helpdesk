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
    if (normalized == 'application/pdf') {
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
