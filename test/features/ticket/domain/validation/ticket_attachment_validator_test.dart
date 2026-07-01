import 'package:flutter_test/flutter_test.dart';
import 'package:uts/features/ticket/domain/entities/local_attachment_candidate.dart';
import 'package:uts/features/ticket/domain/validation/ticket_attachment_validator.dart';

void main() {
  const validator = TicketAttachmentValidator();

  LocalAttachmentCandidate candidate({
    required String path,
    required String fileName,
    required String mimeType,
    required String extension,
    required int sizeBytes,
    LocalAttachmentSource source = LocalAttachmentSource.gallery,
  }) {
    return LocalAttachmentCandidate(
      localPath: path,
      fileName: fileName,
      mimeType: mimeType,
      extension: extension,
      sizeBytes: sizeBytes,
      source: source,
    );
  }

  group('TicketAttachmentValidator', () {
    test('accepts valid JPEG', () {
      final result = validator.validateSingle(candidate(
        path: 'C:/tmp/file.jpg',
        fileName: 'file.jpg',
        mimeType: 'image/jpeg',
        extension: 'jpg',
        sizeBytes: 1024,
      ));

      expect(result.isValid, isTrue);
    });

    test('accepts valid PNG', () {
      final result = validator.validateSingle(candidate(
        path: 'C:/tmp/file.png',
        fileName: 'file.png',
        mimeType: 'image/png',
        extension: 'png',
        sizeBytes: 1024,
      ));

      expect(result.isValid, isTrue);
    });

    test('accepts valid PDF', () {
      final result = validator.validateSingle(candidate(
        path: 'C:/tmp/file.pdf',
        fileName: 'file.pdf',
        mimeType: 'application/pdf',
        extension: 'pdf',
        sizeBytes: 1024,
        source: LocalAttachmentSource.document,
      ));

      expect(result.isValid, isTrue);
    });

    test('rejects file too large', () {
      final result = validator.validateSingle(candidate(
        path: 'C:/tmp/file.jpg',
        fileName: 'file.jpg',
        mimeType: 'image/jpeg',
        extension: 'jpg',
        sizeBytes: TicketAttachmentConstraints.maxAttachmentSizeBytes + 1,
      ));

      expect(result.errorCode, AttachmentValidationErrorCode.fileTooLarge);
    });

    test('rejects MIME type not allowed', () {
      final result = validator.validateSingle(candidate(
        path: 'C:/tmp/file.jpg',
        fileName: 'file.jpg',
        mimeType: 'image/heic',
        extension: 'jpg',
        sizeBytes: 1024,
      ));

      expect(
          result.errorCode, AttachmentValidationErrorCode.mimeTypeNotAllowed);
    });

    test('rejects extension not allowed', () {
      final result = validator.validateSingle(candidate(
        path: 'C:/tmp/file.exe',
        fileName: 'file.exe',
        mimeType: 'application/octet-stream',
        extension: 'exe',
        sizeBytes: 1024,
      ));

      expect(
          result.errorCode, AttachmentValidationErrorCode.extensionNotAllowed);
    });

    test('rejects zero-byte file', () {
      final result = validator.validateSingle(candidate(
        path: 'C:/tmp/file.jpg',
        fileName: 'file.jpg',
        mimeType: 'image/jpeg',
        extension: 'jpg',
        sizeBytes: 0,
      ));

      expect(result.errorCode, AttachmentValidationErrorCode.zeroByteFile);
    });

    test('rejects missing path', () {
      final result = validator.validateSingle(candidate(
        path: '',
        fileName: 'file.jpg',
        mimeType: 'image/jpeg',
        extension: 'jpg',
        sizeBytes: 1024,
      ));

      expect(result.errorCode, AttachmentValidationErrorCode.missingPath);
    });

    test('rejects empty filename', () {
      final result = validator.validateSingle(candidate(
        path: 'C:/tmp/file.jpg',
        fileName: '',
        mimeType: 'image/jpeg',
        extension: 'jpg',
        sizeBytes: 1024,
      ));

      expect(result.errorCode, AttachmentValidationErrorCode.emptyFileName);
    });

    test('rejects attachment count over limit', () {
      final items = List.generate(
        TicketAttachmentConstraints.maxAttachmentCount + 1,
        (index) => candidate(
          path: 'C:/tmp/file_$index.jpg',
          fileName: 'file_$index.jpg',
          mimeType: 'image/jpeg',
          extension: 'jpg',
          sizeBytes: 1024,
        ),
      );

      final result = validator.validateAll(items);

      expect(
          result.errorCode, AttachmentValidationErrorCode.tooManyAttachments);
    });

    test('rejects duplicate attachment', () {
      final file = candidate(
        path: 'C:/tmp/file.jpg',
        fileName: 'file.jpg',
        mimeType: 'image/jpeg',
        extension: 'jpg',
        sizeBytes: 1024,
      );

      final result = validator.validateAll([file, file]);

      expect(
          result.errorCode, AttachmentValidationErrorCode.duplicateAttachment);
    });

    test('rejects MIME and extension mismatch', () {
      final result = validator.validateSingle(candidate(
        path: 'C:/tmp/file.pdf',
        fileName: 'file.pdf',
        mimeType: 'image/jpeg',
        extension: 'pdf',
        sizeBytes: 1024,
      ));

      expect(
        result.errorCode,
        AttachmentValidationErrorCode.mimeExtensionMismatch,
      );
    });
  });
}
