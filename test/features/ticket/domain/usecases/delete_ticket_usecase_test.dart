import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uts/core/error/failures.dart';
import 'package:uts/features/ticket/domain/repositories/ticket_repository.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_usecases.dart';

void main() {
  group('DeleteTicketUseCase', () {
    test('trims reason before repository call', () async {
      final repository = _DeleteRepository();
      final useCase = DeleteTicketUseCase(repository);

      final result = await useCase(const DeleteTicketParams(
        ticketId: 'ticket-1',
        reason: '  tiket duplikat  ',
      ));

      expect(result.isRight(), isTrue);
      expect(repository.lastReason, 'tiket duplikat');
    });

    test('rejects short reason', () async {
      final repository = _DeleteRepository();
      final useCase = DeleteTicketUseCase(repository);

      final result = await useCase(const DeleteTicketParams(
        ticketId: 'ticket-1',
        reason: 'ab',
      ));

      result.fold(
        (failure) => expect(
          (failure as TicketOperationFailure).type,
          TicketFailureType.validation,
        ),
        (_) => fail('expected validation failure'),
      );
      expect(repository.callCount, 0);
    });

    test('blocks duplicate submit while operation is running', () async {
      final repository = _DeleteRepository(completer: Completer<void>());
      final useCase = DeleteTicketUseCase(repository);

      unawaited(useCase(const DeleteTicketParams(
        ticketId: 'ticket-1',
        reason: 'hapus tiket',
      )));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final second = await useCase(const DeleteTicketParams(
        ticketId: 'ticket-1',
        reason: 'hapus tiket kedua',
      ));

      second.fold(
        (failure) => expect(
          (failure as TicketOperationFailure).type,
          TicketFailureType.duplicateSubmit,
        ),
        (_) => fail('expected duplicate-submit failure'),
      );
      expect(repository.callCount, 1);
    });
  });
}

class _DeleteRepository implements TicketRepository {
  final Completer<void>? completer;
  String? lastReason;
  int callCount = 0;

  _DeleteRepository({this.completer});

  @override
  Future<Either<Failure, String>> deleteTicket({
    required String ticketId,
    required String reason,
  }) async {
    callCount++;
    lastReason = reason;
    if (completer != null) {
      await completer!.future;
    }
    return const Right('ticket-1');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
