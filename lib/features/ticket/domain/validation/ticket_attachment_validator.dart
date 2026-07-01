import '../entities/local_attachment_candidate.dart';

enum AttachmentValidationErrorCode {
  tooManyAttachments,
  fileTooLarge,
  totalSizeExceeded,
  mimeTypeNotAllowed,
  extensionNotAllowed,
  zeroByteFile,
  missingPath,
  emptyFileName,
  duplicateAttachment,
  mimeExtensionMismatch,
}

class AttachmentValidationResult {
  final bool isValid;
  final AttachmentValidationErrorCode? errorCode;
  final String? message;
  final LocalAttachmentCandidate? offendingFile;

  const AttachmentValidationResult._({
    required this.isValid,
    this.errorCode,
    this.message,
    this.offendingFile,
  });

  const AttachmentValidationResult.valid() : this._(isValid: true);

  const AttachmentValidationResult.invalid({
    required AttachmentValidationErrorCode errorCode,
    required String message,
    LocalAttachmentCandidate? offendingFile,
  }) : this._(
          isValid: false,
          errorCode: errorCode,
          message: message,
          offendingFile: offendingFile,
        );
}

abstract final class TicketAttachmentConstraints {
  static const int maxAttachmentCount = 5;
  static const int maxAttachmentSizeBytes = 10 * 1024 * 1024;
  static const int? maxTotalAttachmentSizeBytes = null;

  static const Set<String> allowedImageMimeTypes = {
    'image/jpeg',
    'image/png',
  };

  static const Set<String> allowedDocumentMimeTypes = {
    'application/pdf',
  };

  static const Set<String> allowedExtensions = {
    'jpg',
    'jpeg',
    'png',
    'pdf',
  };

  static const Map<String, Set<String>> extensionToMimeTypes = {
    'jpg': {'image/jpeg'},
    'jpeg': {'image/jpeg'},
    'png': {'image/png'},
    'pdf': {'application/pdf'},
  };

  static Set<String> get allowedMimeTypes => {
        ...allowedImageMimeTypes,
        ...allowedDocumentMimeTypes,
      };
}

class TicketAttachmentValidator {
  const TicketAttachmentValidator();

  AttachmentValidationResult validateAll(
    List<LocalAttachmentCandidate> attachments,
  ) {
    if (attachments.length > TicketAttachmentConstraints.maxAttachmentCount) {
      return const AttachmentValidationResult.invalid(
        errorCode: AttachmentValidationErrorCode.tooManyAttachments,
        message: 'Maksimal 5 lampiran diperbolehkan.',
      );
    }

    final totalSize = attachments.fold<int>(
      0,
      (sum, attachment) => sum + attachment.sizeBytes,
    );

    final maxTotal = TicketAttachmentConstraints.maxTotalAttachmentSizeBytes;
    if (maxTotal != null && totalSize > maxTotal) {
      return const AttachmentValidationResult.invalid(
        errorCode: AttachmentValidationErrorCode.totalSizeExceeded,
        message: 'Total ukuran lampiran melebihi batas yang diizinkan.',
      );
    }

    final seenKeys = <String>{};
    for (final attachment in attachments) {
      final singleResult = validateSingle(attachment);
      if (!singleResult.isValid) {
        return singleResult;
      }

      if (!seenKeys.add(attachment.duplicateKey)) {
        return AttachmentValidationResult.invalid(
          errorCode: AttachmentValidationErrorCode.duplicateAttachment,
          message: 'Lampiran duplikat tidak diperbolehkan.',
          offendingFile: attachment,
        );
      }
    }

    return const AttachmentValidationResult.valid();
  }

  AttachmentValidationResult validateSingle(
    LocalAttachmentCandidate attachment,
  ) {
    if (attachment.localPath.trim().isEmpty) {
      return AttachmentValidationResult.invalid(
        errorCode: AttachmentValidationErrorCode.missingPath,
        message: 'Path file lampiran tidak valid.',
        offendingFile: attachment,
      );
    }

    if (attachment.fileName.trim().isEmpty) {
      return AttachmentValidationResult.invalid(
        errorCode: AttachmentValidationErrorCode.emptyFileName,
        message: 'Nama file lampiran wajib diisi.',
        offendingFile: attachment,
      );
    }

    if (attachment.sizeBytes <= 0) {
      return AttachmentValidationResult.invalid(
        errorCode: AttachmentValidationErrorCode.zeroByteFile,
        message: 'File kosong tidak dapat diunggah.',
        offendingFile: attachment,
      );
    }

    if (attachment.sizeBytes >
        TicketAttachmentConstraints.maxAttachmentSizeBytes) {
      return AttachmentValidationResult.invalid(
        errorCode: AttachmentValidationErrorCode.fileTooLarge,
        message: 'Ukuran file melebihi batas 10 MB.',
        offendingFile: attachment,
      );
    }

    final normalizedExtension = attachment.extension.trim().toLowerCase();
    if (!TicketAttachmentConstraints.allowedExtensions
        .contains(normalizedExtension)) {
      return AttachmentValidationResult.invalid(
        errorCode: AttachmentValidationErrorCode.extensionNotAllowed,
        message: 'Ekstensi file tidak diizinkan.',
        offendingFile: attachment,
      );
    }

    final normalizedMimeType = attachment.mimeType.trim().toLowerCase();
    if (!TicketAttachmentConstraints.allowedMimeTypes
        .contains(normalizedMimeType)) {
      return AttachmentValidationResult.invalid(
        errorCode: AttachmentValidationErrorCode.mimeTypeNotAllowed,
        message: 'Tipe file tidak diizinkan.',
        offendingFile: attachment,
      );
    }

    final expectedMimeTypes =
        TicketAttachmentConstraints.extensionToMimeTypes[normalizedExtension];
    if (expectedMimeTypes == null ||
        !expectedMimeTypes.contains(normalizedMimeType)) {
      return AttachmentValidationResult.invalid(
        errorCode: AttachmentValidationErrorCode.mimeExtensionMismatch,
        message: 'MIME type tidak cocok dengan ekstensi file.',
        offendingFile: attachment,
      );
    }

    return const AttachmentValidationResult.valid();
  }
}
