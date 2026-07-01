import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uts/core/error/failures.dart';
import 'package:uts/features/ticket/domain/entities/comment_entity.dart';
import 'package:uts/features/ticket/domain/repositories/ticket_repository.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_usecases.dart';

void main() {
  group('AddCommentUseCase', () {
    test('trims message before repository call', () async {
      final repository = _FakeTicketRepository();
      final useCase = AddCommentUseCase(repository);

      final result = await useCase(
        const AddCommentParams(
          ticketId: 'ticket-1',
          message: '  halo  ',
        ),
      );

      expect(result.isRight(), isTrue);
      expect(repository.lastMessage, 'halo');
    });

    test('rejects empty message before repository call', () async {
      final repository = _FakeTicketRepository();
      final useCase = AddCommentUseCase(repository);

      final result = await useCase(
        const AddCommentParams(
          ticketId: 'ticket-1',
          message: '   ',
        ),
      );

      expect(result.isLeft(), isTrue);
      expect(repository.callCount, 0);
    });

    test('blocks duplicate submit while request in flight', () async {
      final repository =
          _FakeTicketRepository(delayCompleter: Completer<void>());
      final useCase = AddCommentUseCase(repository);

      final firstFuture = useCase(
        const AddCommentParams(ticketId: 'ticket-1', message: 'halo'),
      );
      final secondResult = await useCase(
        const AddCommentParams(ticketId: 'ticket-1', message: 'halo lagi'),
      );

      expect(secondResult.isLeft(), isTrue);
      repository.delayCompleter!.complete();
      await firstFuture;
      expect(repository.callCount, 1);
    });
  });
}

class _FakeTicketRepository implements TicketRepository {
  final Completer<void>? delayCompleter;
  int callCount = 0;
  String? lastMessage;

  _FakeTicketRepository({this.delayCompleter});

  @override
  Future<Either<Failure, CommentEntity>> addComment({
    required String ticketId,
    required String message,
  }) async {
    callCount++;
    lastMessage = message;
    if (delayCompleter != null) {
      await delayCompleter!.future;
    }
    return Right(CommentEntity(
      id: 'comment-1',
      ticketId: ticketId,
      userId: 'user-1',
      userName: 'User',
      userRole: 'user',
      message: message,
      createdAt: DateTime.parse('2026-06-30T10:00:00Z'),
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
