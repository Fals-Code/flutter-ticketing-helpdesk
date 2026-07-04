import 'package:supabase_flutter/supabase_flutter.dart' as sup;
import 'package:uts/core/error/failures.dart';

class TicketCreateException implements Exception {
  final TicketFailureType type;
  final String message;
  final int? code;
  final String? debugMessage;
  final List<String> failedStoragePaths;

  const TicketCreateException({
    required this.type,
    required this.message,
    this.code,
    this.debugMessage,
    this.failedStoragePaths = const [],
  });

  @override
  String toString() => message;
}

abstract final class TicketCreateFailureMapper {
  static TicketFailureType typeFromPostgrest(sup.PostgrestException error) {
    return switch (error.code) {
      '42501' => TicketFailureType.authorization,
      '23502' ||
      '23503' ||
      '23505' ||
      '23514' ||
      '22023' ||
      '22P02' =>
        TicketFailureType.validation,
      'PGRST202' || '42883' => TicketFailureType.databaseCreate,
      _ => TicketFailureType.databaseCreate,
    };
  }

  static bool isMissingCreateTicketRpc(sup.PostgrestException error) {
    final message = error.message.toLowerCase();
    return (error.code == 'PGRST202' || error.code == '42883') &&
        message.contains('create_ticket_with_attachments');
  }

  static bool canUseDirectInsertFallback({
    required sup.PostgrestException error,
    required int attachmentCount,
  }) {
    return attachmentCount == 0 && isMissingCreateTicketRpc(error);
  }

  static int? numericCode(sup.PostgrestException error) {
    final code = error.code;
    return code == null ? null : int.tryParse(code);
  }

  static String safeMessageFromPostgrest(sup.PostgrestException error) {
    return switch (error.code) {
      '42501' => 'Akun Anda tidak memiliki izin membuat tiket.',
      '23502' ||
      '23503' ||
      '23505' ||
      '23514' ||
      '22023' ||
      '22P02' =>
        'Data tiket tidak valid. Periksa kembali isian tiket.',
      'PGRST202' ||
      '42883' =>
        'Layanan pembuatan tiket belum siap. Coba lagi beberapa saat.',
      _ => 'Tiket belum dapat disimpan. Coba lagi beberapa saat.',
    };
  }

  static String debugSummaryFromPostgrest(sup.PostgrestException error) {
    return [
      'type=${error.runtimeType}',
      'code=${_sanitize(error.code)}',
      'message=${_sanitize(error.message)}',
      'details=${_sanitizeDetails(error.details)}',
      'hint=${_sanitize(error.hint)}',
    ].join(' ');
  }

  static String _sanitize(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return '-';
    }
    return text.replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _sanitizeDetails(Object? value) {
    final text = _sanitize(value);
    if (text == '-') {
      return text;
    }
    if (text.toLowerCase().contains('failing row contains')) {
      return '<redacted-row>';
    }
    return text;
  }
}
