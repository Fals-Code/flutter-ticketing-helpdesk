import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as sup;
import 'package:uts/core/error/failures.dart';
import 'package:uts/features/ticket/data/datasources/ticket_create_exceptions.dart';
import 'package:uts/features/ticket/domain/entities/local_attachment_candidate.dart';

class UploadedTicketAttachment {
  final String id;
  final String storagePath;
  final String fileName;
  final String mimeType;
  final String extension;
  final int sizeBytes;
  final LocalAttachmentSource source;

  const UploadedTicketAttachment({
    required this.id,
    required this.storagePath,
    required this.fileName,
    required this.mimeType,
    required this.extension,
    required this.sizeBytes,
    required this.source,
  });

  Map<String, dynamic> toManifestJson() {
    return {
      'id': id,
      'storage_path': storagePath,
      'file_name': fileName,
      'mime_type': mimeType,
      'extension': extension,
      'size_bytes': sizeBytes,
      'source': source.name,
    };
  }
}

abstract class TicketAttachmentStorageDataSource {
  String buildStoragePath({
    required String ticketId,
    required String userId,
    required String attachmentId,
    required LocalAttachmentCandidate candidate,
  });

  Future<UploadedTicketAttachment> upload({
    required String ticketId,
    required String userId,
    required String attachmentId,
    required LocalAttachmentCandidate candidate,
  });

  Future<void> deleteObject(String storagePath);

  Future<List<String>> deleteObjects(List<String> storagePaths);
}

class SupabaseTicketAttachmentStorageDataSource
    implements TicketAttachmentStorageDataSource {
  static const String bucketName = 'tickets';

  final sup.SupabaseClient supabaseClient;

  const SupabaseTicketAttachmentStorageDataSource(this.supabaseClient);

  @override
  String buildStoragePath({
    required String ticketId,
    required String userId,
    required String attachmentId,
    required LocalAttachmentCandidate candidate,
  }) {
    final fileName = _safeFileName(
      attachmentId: attachmentId,
      originalFileName: candidate.fileName,
      extension: candidate.extension,
    );
    return '$ticketId/$userId/$fileName';
  }

  @override
  Future<UploadedTicketAttachment> upload({
    required String ticketId,
    required String userId,
    required String attachmentId,
    required LocalAttachmentCandidate candidate,
  }) async {
    final file = File(candidate.localPath);
    if (!await file.exists()) {
      throw const TicketCreateException(
        type: TicketFailureType.fileUnreadable,
        message: 'File lampiran tidak ditemukan.',
      );
    }

    final storagePath = buildStoragePath(
      ticketId: ticketId,
      userId: userId,
      attachmentId: attachmentId,
      candidate: candidate,
    );
    final fileName = storagePath.split('/').last;

    try {
      await supabaseClient.storage.from(bucketName).upload(
            storagePath,
            file,
            fileOptions: sup.FileOptions(
              contentType: candidate.mimeType,
              upsert: false,
            ),
          );
    } on sup.StorageException catch (error) {
      throw TicketCreateException(
        type: TicketFailureType.upload,
        message: 'Gagal mengunggah lampiran.',
        code: int.tryParse(error.statusCode ?? ''),
      );
    } on TicketCreateException {
      rethrow;
    } catch (_) {
      throw const TicketCreateException(
        type: TicketFailureType.upload,
        message: 'Gagal mengunggah lampiran.',
      );
    }

    return UploadedTicketAttachment(
      id: attachmentId,
      storagePath: storagePath,
      fileName: fileName,
      mimeType: candidate.mimeType,
      extension: candidate.extension,
      sizeBytes: candidate.sizeBytes,
      source: candidate.source,
    );
  }

  @override
  Future<void> deleteObject(String storagePath) async {
    try {
      await supabaseClient.storage.from(bucketName).remove([storagePath]);
    } on sup.StorageException catch (error) {
      throw TicketCreateException(
        type: TicketFailureType.compensation,
        message: 'Cleanup lampiran gagal.',
        code: int.tryParse(error.statusCode ?? ''),
        failedStoragePaths: [storagePath],
      );
    } catch (_) {
      throw TicketCreateException(
        type: TicketFailureType.compensation,
        message: 'Cleanup lampiran gagal.',
        failedStoragePaths: [storagePath],
      );
    }
  }

  @override
  Future<List<String>> deleteObjects(List<String> storagePaths) async {
    final failedPaths = <String>[];
    for (final path in storagePaths) {
      try {
        await deleteObject(path);
      } on TicketCreateException {
        failedPaths.add(path);
      }
    }
    return failedPaths;
  }

  static String _safeFileName({
    required String attachmentId,
    required String originalFileName,
    required String extension,
  }) {
    final normalizedExtension = extension.trim().toLowerCase();
    final baseName = originalFileName
        .replaceAll('\\', '/')
        .split('/')
        .last
        .replaceFirst(RegExp(r'\.[^.]+$'), '')
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final safeBase = baseName.isEmpty ? 'attachment' : baseName;
    final suffix = normalizedExtension.isEmpty ? '' : '.$normalizedExtension';
    final maxBaseLength = 120 - attachmentId.length - suffix.length - 1;
    final truncatedBase = safeBase.length > maxBaseLength
        ? safeBase.substring(0, maxBaseLength)
        : safeBase;
    return '$attachmentId-$truncatedBase$suffix';
  }
}
