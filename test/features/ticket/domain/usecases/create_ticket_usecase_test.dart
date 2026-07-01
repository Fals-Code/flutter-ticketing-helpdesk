import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/core/error/failures.dart';
import 'package:uts/features/ticket/domain/entities/create_ticket_params.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/domain/repositories/ticket_repository.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_usecases.dart';

void main() {
  group('CreateTicketUseCase', () {
    test('allows user, helpdesk, and admin callers through domain contract',
        () async {
      for (final roleLabel in ['user', 'helpdesk', 'admin']) {
        final repository = _CompletingRepository();
        final useCase = CreateTicketUseCase(repository);

        final result = await useCase(_params(title: 'Ticket $roleLabel'));

        expect(result.isRight(), isTrue);
        expect(repository.callCount, 1);
      }
    });

    test('rejects duplicate submit while one operation is running', () async {
      final repository = _CompletingRepository(completeManually: true);
      final useCase = CreateTicketUseCase(repository);

      final first = useCase(_params());
      final second = await useCase(_params());

      second.fold(
        (failure) {
          final typed = failure as TicketOperationFailure;
          expect(typed.type, TicketFailureType.duplicateSubmit);
        },
        (_) => fail('expected duplicate submit failure'),
      );

      repository.complete();
      expect((await first).isRight(), isTrue);
      expect(repository.callCount, 1);
    });
  });
}

CreateTicketParams _params({String title = 'Printer error'}) {
  return CreateTicketParams(
    title: title,
    description: 'Printer lantai 2 tidak dapat mencetak dokumen.',
    category: 'hardware',
  );
}

class _CompletingRepository implements TicketRepository {
  final bool completeManually;
  final Completer<Either<Failure, TicketEntity>> _completer = Completer();
  int callCount = 0;

  _CompletingRepository({this.completeManually = false});

  @override
  Future<Either<Failure, TicketEntity>> createTicket(
    CreateTicketParams params,
  ) {
    callCount++;
    if (completeManually) {
      return _completer.future;
    }
    return Future.value(Right(_ticket(params)));
  }

  void complete() {
    if (!_completer.isCompleted) {
      _completer.complete(Right(_ticket(_params())));
    }
  }

  TicketEntity _ticket(CreateTicketParams params) {
    return TicketEntity(
      id: 'ticket-1',
      title: params.trimmedTitle,
      description: params.trimmedDescription,
      status: TicketStatus.open,
      category: params.trimmedCategory,
      createdAt: DateTime.parse('2026-06-30T00:00:00.000Z'),
      userId: 'user-1',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
