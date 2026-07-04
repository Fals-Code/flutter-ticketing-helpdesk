import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sup;
import 'package:uts/core/error/failures.dart';
import 'package:uts/features/ticket/data/datasources/ticket_create_exceptions.dart';

void main() {
  group('TicketCreateFailureMapper', () {
    test('maps RLS rejection to authorization failure and safe message', () {
      final error = sup.PostgrestException(
        message: 'new row violates row-level security policy',
        code: '42501',
        details: 'Failing row contains private payload',
      );

      expect(
        TicketCreateFailureMapper.typeFromPostgrest(error),
        TicketFailureType.authorization,
      );
      expect(
        TicketCreateFailureMapper.safeMessageFromPostgrest(error),
        'Akun Anda tidak memiliki izin membuat tiket.',
      );
    });

    test('maps database constraint errors to validation failure', () {
      final error = sup.PostgrestException(
        message: 'new row for relation "tickets" violates check constraint',
        code: '23514',
        details: 'tickets_required_text_check',
      );

      expect(
        TicketCreateFailureMapper.typeFromPostgrest(error),
        TicketFailureType.validation,
      );
      expect(
        TicketCreateFailureMapper.safeMessageFromPostgrest(error),
        'Data tiket tidak valid. Periksa kembali isian tiket.',
      );
    });

    test('maps missing RPC contract to backend-create failure', () {
      final error = sup.PostgrestException(
        message:
            'Could not find the function public.create_ticket_with_attachments',
        code: 'PGRST202',
        hint: 'Check function argument names and types',
      );

      expect(
        TicketCreateFailureMapper.typeFromPostgrest(error),
        TicketFailureType.databaseCreate,
      );
      expect(
        TicketCreateFailureMapper.safeMessageFromPostgrest(error),
        'Layanan pembuatan tiket belum siap. Coba lagi beberapa saat.',
      );
      expect(
        TicketCreateFailureMapper.debugSummaryFromPostgrest(error),
        contains('code=PGRST202'),
      );
      expect(
        TicketCreateFailureMapper.debugSummaryFromPostgrest(error),
        contains('create_ticket_with_attachments'),
      );
    });

    test(
        'allows direct insert fallback only for missing RPC without attachment',
        () {
      final error = sup.PostgrestException(
        message:
            'Could not find the function public.create_ticket_with_attachments',
        code: 'PGRST202',
      );

      expect(
        TicketCreateFailureMapper.canUseDirectInsertFallback(
          error: error,
          attachmentCount: 0,
        ),
        isTrue,
      );
      expect(
        TicketCreateFailureMapper.canUseDirectInsertFallback(
          error: error,
          attachmentCount: 1,
        ),
        isFalse,
      );
    });

    test('does not fallback for unrelated missing RPC error', () {
      final error = sup.PostgrestException(
        message: 'Could not find the function public.get_ticket_stats',
        code: 'PGRST202',
      );

      expect(
        TicketCreateFailureMapper.canUseDirectInsertFallback(
          error: error,
          attachmentCount: 0,
        ),
        isFalse,
      );
    });

    test('keeps raw backend details out of user-facing unknown message', () {
      final error = sup.PostgrestException(
        message: 'database returned internal stack trace',
        code: 'XX000',
        details: 'sensitive table detail',
      );

      expect(
        TicketCreateFailureMapper.safeMessageFromPostgrest(error),
        'Tiket belum dapat disimpan. Coba lagi beberapa saat.',
      );
      expect(
        TicketCreateFailureMapper.safeMessageFromPostgrest(error),
        isNot(contains('sensitive table detail')),
      );
    });

    test('redacts failing row details from debug summary', () {
      final error = sup.PostgrestException(
        message: 'new row violates check constraint',
        code: '23514',
        details:
            'Failing row contains (ticket-id, rahasia isi tiket, user-id).',
      );

      final summary = TicketCreateFailureMapper.debugSummaryFromPostgrest(
        error,
      );

      expect(summary, contains('code=23514'));
      expect(summary, contains('details=<redacted-row>'));
      expect(summary, isNot(contains('rahasia isi tiket')));
    });
  });
}
