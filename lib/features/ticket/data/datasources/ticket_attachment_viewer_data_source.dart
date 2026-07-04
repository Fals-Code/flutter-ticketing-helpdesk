import 'dart:async';
import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sup;

import '../../domain/entities/ticket_attachment_entity.dart';
import '../../domain/services/ticket_attachment_viewer.dart';

class SupabaseTicketAttachmentViewerDataSource
    implements TicketAttachmentViewerDataSource {
  static const String bucketName = 'tickets';
  static const Duration _defaultSignedUrlTtl = Duration(minutes: 12);

  final sup.SupabaseClient supabaseClient;
  final Map<String, Future<TicketAttachmentActionResult>> _inFlightActions = {};

  SupabaseTicketAttachmentViewerDataSource(this.supabaseClient);

  @override
  Future<List<Map<String, dynamic>>> hydrateAttachmentPayloads(
    List<Map<String, dynamic>> attachments, {
    Duration signedUrlTtl = _defaultSignedUrlTtl,
  }) async {
    if (attachments.isEmpty) {
      return const [];
    }

    final hydrated = <Map<String, dynamic>>[];
    for (final attachment in attachments) {
      hydrated.add(
        await _hydrateAttachmentPayload(
          Map<String, dynamic>.from(attachment),
          signedUrlTtl: signedUrlTtl,
        ),
      );
    }
    return hydrated;
  }

  @override
  Future<TicketAttachmentActionResult> openAttachment(
    TicketAttachmentEntity attachment,
  ) {
    final operationKey = attachment.storagePath ?? attachment.id;
    final active = _inFlightActions[operationKey];
    if (active != null) {
      return active;
    }

    final future = _openAttachmentInternal(attachment).whenComplete(() {
      _inFlightActions.remove(operationKey);
    });

    _inFlightActions[operationKey] = future;
    return future;
  }

  Future<Map<String, dynamic>> _hydrateAttachmentPayload(
    Map<String, dynamic> attachment, {
    required Duration signedUrlTtl,
  }) async {
    final existingUrl = _readFirstUrl(attachment);
    if (existingUrl != null) {
      return attachment;
    }

    final storagePath = _readNullableString(attachment['storage_path']);
    if (storagePath == null) {
      return attachment;
    }

    try {
      final signedUrl = await _createSignedUrl(
        storagePath,
        signedUrlTtl: signedUrlTtl,
      );
      if (signedUrl == null || signedUrl.isEmpty) {
        return attachment;
      }
      attachment['signed_url'] = signedUrl;
      attachment['access_url'] = signedUrl;
      return attachment;
    } catch (_) {
      return attachment;
    }
  }

  Future<TicketAttachmentActionResult> _openAttachmentInternal(
    TicketAttachmentEntity attachment,
  ) async {
    final storagePath = attachment.storagePath?.trim();
    if (storagePath == null || storagePath.isEmpty) {
      return const TicketAttachmentActionResult.unsupported(
        message: 'Lampiran tidak memiliki storage path.',
      );
    }

    try {
      final cacheFile = await _resolveCacheFile(attachment);
      if (!await cacheFile.exists() || await cacheFile.length() == 0) {
        final bytes =
            await supabaseClient.storage.from(bucketName).download(storagePath);
        await cacheFile.writeAsBytes(bytes, flush: true);
      }

      final result = await OpenFilex.open(cacheFile.path);
      final openType = result.type.toString().toLowerCase();
      if (openType.contains('done')) {
        return TicketAttachmentActionResult.opened(
          localPath: cacheFile.path,
        );
      }
      if (openType.contains('filenotfound')) {
        return const TicketAttachmentActionResult.fileNotFound();
      }
      if (openType.contains('noapp')) {
        return const TicketAttachmentActionResult.noAppFound();
      }
      if (openType.contains('permission')) {
        return const TicketAttachmentActionResult.accessDenied();
      }
      if (openType.contains('busy')) {
        return const TicketAttachmentActionResult.busy();
      }
      return TicketAttachmentActionResult.failed(
        message: _resultMessage(result.message),
      );
    } on sup.StorageException catch (error) {
      final statusCode = int.tryParse(error.statusCode ?? '');
      if (statusCode == 404) {
        return const TicketAttachmentActionResult.fileNotFound();
      }
      if (statusCode == 401 || statusCode == 403) {
        return const TicketAttachmentActionResult.accessDenied();
      }
      return TicketAttachmentActionResult.failed(
        message: _resultMessage(error.message),
      );
    } on SocketException {
      return const TicketAttachmentActionResult.offline();
    } on TimeoutException {
      return const TicketAttachmentActionResult.offline();
    } on FileSystemException {
      return const TicketAttachmentActionResult.failed();
    } catch (_) {
      return const TicketAttachmentActionResult.failed();
    }
  }

  Future<String?> _createSignedUrl(
    String storagePath, {
    required Duration signedUrlTtl,
  }) async {
    final response = await supabaseClient.storage
        .from(bucketName)
        .createSignedUrl(storagePath, signedUrlTtl.inSeconds);
    if (response.isEmpty) {
      return null;
    }
    return response;
  }

  Future<File> _resolveCacheFile(TicketAttachmentEntity attachment) async {
    final cacheDir = await getTemporaryDirectory();
    final attachmentsDir = Directory(
      '${cacheDir.path}${Platform.pathSeparator}ticket_attachments',
    );
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    final cacheName = _safeCacheFileName(attachment);
    return File('${attachmentsDir.path}${Platform.pathSeparator}$cacheName');
  }

  String _safeCacheFileName(TicketAttachmentEntity attachment) {
    final storageName =
        attachment.storagePath?.split('/').last ?? attachment.fileName.trim();
    final fileName = storageName.isEmpty ? attachment.fileName : storageName;
    final sanitized = fileName
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final prefix = '${attachment.ticketId}_${attachment.id}_';
    final maxLength = 140 - prefix.length;
    final trimmed = sanitized.length > maxLength
        ? sanitized.substring(0, maxLength)
        : sanitized;
    return '$prefix$trimmed';
  }

  String? _readFirstUrl(Map<String, dynamic> json) {
    return _readNullableString(
          json['access_url'],
        ) ??
        _readNullableString(json['signed_url']) ??
        _readNullableString(json['public_url']) ??
        _readNullableString(json['url']);
  }

  String? _readNullableString(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String _resultMessage(String message) {
    final text = message.trim();
    return text.isEmpty ? 'Gagal membuka lampiran.' : text;
  }
}
