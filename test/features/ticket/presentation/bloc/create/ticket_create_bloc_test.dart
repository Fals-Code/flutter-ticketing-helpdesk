import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/core/error/failures.dart';
import 'package:uts/features/ticket/domain/entities/create_ticket_params.dart';
import 'package:uts/features/ticket/domain/entities/local_attachment_candidate.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/domain/repositories/ticket_repository.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_usecases.dart';
import 'package:uts/features/ticket/presentation/bloc/create/ticket_create_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/create/ticket_create_event.dart';
import 'package:uts/features/ticket/presentation/bloc/create/ticket_create_state.dart';

void main() {
  group('TicketCreateBloc', () {
    blocTest<TicketCreateBloc, TicketCreateState>(
      'emits validating, uploading, creatingTicket, and success',
      build: () => TicketCreateBloc(
        createTicketUseCase: CreateTicketUseCase(_FakeCreateRepository()),
      ),
      act: (bloc) => bloc.add(SubmitTicketCreateRequested(
        title: 'Printer error',
        description: 'Printer lantai 2 tidak dapat mencetak dokumen.',
        category: 'hardware',
        attachments: [_attachment()],
      )),
      expect: () => [
        isA<TicketCreateState>()
            .having((state) => state.status, 'status',
                TicketCreateStatus.validating)
            .having((state) => state.totalCount, 'totalCount', 1),
        isA<TicketCreateState>().having(
          (state) => state.status,
          'status',
          TicketCreateStatus.uploading,
        ),
        isA<TicketCreateState>().having(
          (state) => state.status,
          'status',
          TicketCreateStatus.creatingTicket,
        ),
        isA<TicketCreateState>()
            .having(
                (state) => state.status, 'status', TicketCreateStatus.success)
            .having((state) => state.ticket?.id, 'ticket id', 'ticket-1'),
      ],
    );

    blocTest<TicketCreateBloc, TicketCreateState>(
      'emits validationFailure for invalid form',
      build: () => TicketCreateBloc(
        createTicketUseCase: CreateTicketUseCase(_FakeCreateRepository()),
      ),
      act: (bloc) => bloc.add(const SubmitTicketCreateRequested(
        title: 'Bad',
        description: 'Short',
        category: '',
        attachments: [],
      )),
      expect: () => [
        isA<TicketCreateState>().having(
          (state) => state.status,
          'status',
          TicketCreateStatus.validating,
        ),
        isA<TicketCreateState>().having(
          (state) => state.status,
          'status',
          TicketCreateStatus.validationFailure,
        ),
      ],
    );

    blocTest<TicketCreateBloc, TicketCreateState>(
      'emits createFailure when repository returns create failure',
      build: () => TicketCreateBloc(
        createTicketUseCase: CreateTicketUseCase(
          _FakeCreateRepository(
            failure: const TicketOperationFailure(
              type: TicketFailureType.databaseCreate,
              message: 'create failed',
            ),
          ),
        ),
      ),
      act: (bloc) => bloc.add(const SubmitTicketCreateRequested(
        title: 'Printer error',
        description: 'Printer lantai 2 tidak dapat mencetak dokumen.',
        category: 'hardware',
        attachments: [],
      )),
      expect: () => [
        isA<TicketCreateState>().having(
          (state) => state.status,
          'status',
          TicketCreateStatus.validating,
        ),
        isA<TicketCreateState>().having(
          (state) => state.status,
          'status',
          TicketCreateStatus.uploading,
        ),
        isA<TicketCreateState>().having(
          (state) => state.status,
          'status',
          TicketCreateStatus.creatingTicket,
        ),
        isA<TicketCreateState>().having(
          (state) => state.status,
          'status',
          TicketCreateStatus.createFailure,
        ),
      ],
    );

    blocTest<TicketCreateBloc, TicketCreateState>(
      'maps compensation failure to compensationFailure state',
      build: () => TicketCreateBloc(
        createTicketUseCase: CreateTicketUseCase(
          _FakeCreateRepository(
            failure: const TicketOperationFailure(
              type: TicketFailureType.compensation,
              message: 'cleanup failed',
            ),
          ),
        ),
      ),
      act: (bloc) => bloc.add(const SubmitTicketCreateRequested(
        title: 'Printer error',
        description: 'Printer lantai 2 tidak dapat mencetak dokumen.',
        category: 'hardware',
        attachments: [],
      )),
      expect: () => [
        isA<TicketCreateState>().having(
          (state) => state.status,
          'status',
          TicketCreateStatus.validating,
        ),
        isA<TicketCreateState>().having(
          (state) => state.status,
          'status',
          TicketCreateStatus.uploading,
        ),
        isA<TicketCreateState>().having(
          (state) => state.status,
          'status',
          TicketCreateStatus.creatingTicket,
        ),
        isA<TicketCreateState>().having(
          (state) => state.status,
          'status',
          TicketCreateStatus.compensationFailure,
        ),
      ],
    );

    blocTest<TicketCreateBloc, TicketCreateState>(
      'reset clears create state and ignores stale create completion',
      build: () => TicketCreateBloc(
        createTicketUseCase: CreateTicketUseCase(
          _FakeCreateRepository(
            completion: Completer<Either<Failure, TicketEntity>>(),
          ),
        ),
      ),
      act: (bloc) async {
        final repository =
            bloc.createTicketUseCase.repository as _FakeCreateRepository;
        bloc.add(const SubmitTicketCreateRequested(
          title: 'Printer error',
          description: 'Printer lantai 2 tidak dapat mencetak dokumen.',
          category: 'hardware',
          attachments: [],
        ));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const TicketCreateResetRequested());
        repository.completion!.complete(
          Right(TicketEntity(
            id: 'late-ticket',
            title: 'Printer error',
            description: 'Printer lantai 2 tidak dapat mencetak dokumen.',
            status: TicketStatus.open,
            category: 'hardware',
            createdAt: DateTime.parse('2026-06-30T00:00:00.000Z'),
            userId: 'user-1',
          )),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));
      },
      verify: (bloc) {
        expect(bloc.state, const TicketCreateState());
      },
    );

    blocTest<TicketCreateBloc, TicketCreateState>(
      'duplicate submit keeps first create operation alive',
      build: () => TicketCreateBloc(
        createTicketUseCase: CreateTicketUseCase(
          _FakeCreateRepository(
            completion: Completer<Either<Failure, TicketEntity>>(),
          ),
        ),
      ),
      act: (bloc) async {
        final repository =
            bloc.createTicketUseCase.repository as _FakeCreateRepository;
        bloc.add(const SubmitTicketCreateRequested(
          title: 'Printer error',
          description: 'Printer lantai 2 tidak dapat mencetak dokumen.',
          category: 'hardware',
          attachments: [],
        ));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const SubmitTicketCreateRequested(
          title: 'Printer error',
          description: 'Printer lantai 2 tidak dapat mencetak dokumen.',
          category: 'hardware',
          attachments: [],
        ));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(repository.createCallCount, 1);
        repository.completion!.complete(
          Right(TicketEntity(
            id: 'ticket-1',
            title: 'Printer error',
            description: 'Printer lantai 2 tidak dapat mencetak dokumen.',
            status: TicketStatus.open,
            category: 'hardware',
            createdAt: DateTime.parse('2026-06-30T00:00:00.000Z'),
            userId: 'user-1',
          )),
        );
      },
      expect: () => [
        isA<TicketCreateState>().having(
          (state) => state.status,
          'status',
          TicketCreateStatus.validating,
        ),
        isA<TicketCreateState>().having(
          (state) => state.status,
          'status',
          TicketCreateStatus.uploading,
        ),
        isA<TicketCreateState>().having(
          (state) => state.status,
          'status',
          TicketCreateStatus.creatingTicket,
        ),
        isA<TicketCreateState>()
            .having(
                (state) => state.status, 'status', TicketCreateStatus.success)
            .having((state) => state.ticket?.id, 'ticket id', 'ticket-1'),
      ],
      verify: (bloc) {
        final repository =
            bloc.createTicketUseCase.repository as _FakeCreateRepository;
        expect(repository.createCallCount, 1);
      },
    );
  });
}

LocalAttachmentCandidate _attachment() {
  return const LocalAttachmentCandidate(
    localPath: 'C:/tmp/evidence.pdf',
    fileName: 'evidence.pdf',
    mimeType: 'application/pdf',
    extension: 'pdf',
    sizeBytes: 1024,
    source: LocalAttachmentSource.document,
  );
}

class _FakeCreateRepository implements TicketRepository {
  final Failure? failure;
  final Completer<Either<Failure, TicketEntity>>? completion;
  int createCallCount = 0;

  _FakeCreateRepository({this.failure, this.completion});

  @override
  Future<Either<Failure, TicketEntity>> createTicket(
    CreateTicketParams params,
  ) async {
    createCallCount++;
    params.onProgress?.call(CreateTicketProgress(
      stage: CreateTicketProgressStage.uploading,
      currentFileName:
          params.attachments.isEmpty ? null : params.attachments.first.fileName,
      totalCount: params.attachments.length,
    ));
    params.onProgress?.call(CreateTicketProgress(
      stage: CreateTicketProgressStage.creatingTicket,
      uploadedCount: params.attachments.length,
      totalCount: params.attachments.length,
    ));

    if (completion != null) {
      return completion!.future;
    }

    if (failure != null) {
      return Left(failure!);
    }

    return Right(TicketEntity(
      id: 'ticket-1',
      title: params.trimmedTitle,
      description: params.trimmedDescription,
      status: TicketStatus.open,
      category: params.trimmedCategory,
      createdAt: DateTime.parse('2026-06-30T00:00:00.000Z'),
      userId: 'user-1',
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
