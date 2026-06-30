import 'package:equatable/equatable.dart';

enum LocalAttachmentSource {
  camera,
  gallery,
  document,
}

class LocalAttachmentCandidate extends Equatable {
  final String localPath;
  final String fileName;
  final String mimeType;
  final String extension;
  final int sizeBytes;
  final LocalAttachmentSource source;

  const LocalAttachmentCandidate({
    required this.localPath,
    required this.fileName,
    required this.mimeType,
    required this.extension,
    required this.sizeBytes,
    required this.source,
  });

  factory LocalAttachmentCandidate.fromPath({
    required String localPath,
    required int sizeBytes,
    required LocalAttachmentSource source,
    String? fileName,
    String? mimeType,
  }) {
    final normalizedFileName = _resolveFileName(localPath, fileName);
    final extension = _resolveExtension(normalizedFileName);
    final normalizedMimeType =
        (mimeType ?? inferMimeTypeFromExtension(extension))
            .trim()
            .toLowerCase();

    return LocalAttachmentCandidate(
      localPath: localPath,
      fileName: normalizedFileName,
      mimeType: normalizedMimeType,
      extension: extension,
      sizeBytes: sizeBytes,
      source: source,
    );
  }

  String get normalizedFileName => fileName.trim().toLowerCase();

  String get duplicateKey =>
      '${localPath.trim().toLowerCase()}|$normalizedFileName|$sizeBytes';

  static String inferMimeTypeFromExtension(String extension) {
    switch (extension.trim().toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  static String _resolveFileName(String localPath, String? fileName) {
    final trimmedName = fileName?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) {
      return trimmedName;
    }

    final normalizedPath = localPath.replaceAll('\\', '/');
    final segments = normalizedPath.split('/');
    return segments.isNotEmpty ? segments.last : '';
  }

  static String _resolveExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == fileName.length - 1) {
      return '';
    }
    return fileName.substring(dotIndex + 1).trim().toLowerCase();
  }

  @override
  List<Object?> get props => [
        localPath,
        fileName,
        mimeType,
        extension,
        sizeBytes,
        source,
      ];
}
