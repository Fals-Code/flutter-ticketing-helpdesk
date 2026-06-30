import 'package:flutter_test/flutter_test.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/core/error/failures.dart';
import 'package:uts/features/ticket/data/datasources/ticket_attachment_storage_data_source.dart';
import 'package:uts/features/ticket/data/datasources/ticket_create_exceptions.dart';
import 'package:uts/features/ticket/data/datasources/ticket_remote_data_source.dart';
import 'package:uts/features/ticket/data/models/ticket_model.dart';
import 'package:uts/features/ticket/data/repositories/ticket_repository_impl.dart';
import 'package:uts/features/ticket/domain/entities/create_ticket_params.dart';
import 'package:uts/features/ticket/domain/entities/local_attachment_candidate.dart';

void main() {
  group('TicketRepositoryImpl.createTicket', () {
    test('uploads no attachment and runs create transaction directly',
        () async {
      final remote = _FakeRemote();
      final storage = _FakeStorage();
      final repository = TicketRepositoryImpl(
        remoteDataSource: remote,
        attachmentStorageDataSource: storage,
      );

      final result = await repository.createTicket(_params());

      expect(result.isRight(), isTrue);
      expect(storage.uploadedPaths, isEmpty);
      expect(remote.createCallCount, 1);
      expect(remote.lastAttachments, isEmpty);
    });

    test('first upload failure does not call database', () async {
      final remote = _FakeRemote();
      final storage = _FakeStorage(failUploadAt: 0);
      final repository = TicketRepositoryImpl(
        remoteDataSource: remote,
        attachmentStorageDataSource: storage,
      );

      final result = await repository.createTicket(_params(
        attachments: [_attachment('one.pdf')],
      ));

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(
          (failure as TicketOperationFailure).type,
          TicketFailureType.upload,
        ),
        (_) => fail('expected failure'),
      );
      expect(remote.createCallCount, 0);
      expect(storage.deletedPaths, isEmpty);
    });

    test('partial upload failure deletes already uploaded objects', () async {
      final remote = _FakeRemote();
      final storage = _FakeStorage(failUploadAt: 1);
      final repository = TicketRepositoryImpl(
        remoteDataSource: remote,
        attachmentStorageDataSource: storage,
      );

      final result = await repository.createTicket(_params(
        attachments: [_attachment('one.pdf'), _attachment('two.pdf')],
      ));

      expect(result.isLeft(), isTrue);
      expect(remote.createCallCount, 0);
      expect(storage.deletedPaths, [storage.uploadedPaths.first]);
    });

    test('create transaction failure deletes all uploaded objects', () async {
      final remote = _FakeRemote(failCreate: true);
      final storage = _FakeStorage();
      final repository = TicketRepositoryImpl(
        remoteDataSource: remote,
        attachmentStorageDataSource: storage,
      );

      final result = await repository.createTicket(_params(
        attachments: [_attachment('one.pdf'), _attachment('two.pdf')],
      ));

      expect(result.isLeft(), isTrue);
      expect(remote.createCallCount, 1);
      expect(storage.deletedPaths, storage.uploadedPaths);
    });

    test('cleanup failure returns compensation failure', () async {
      final remote = _FakeRemote(failCreate: true);
      final storage = _FakeStorage(failDelete: true);
      final repository = TicketRepositoryImpl(
        remoteDataSource: remote,
        attachmentStorageDataSource: storage,
      );

      final result = await repository.createTicket(_params(
        attachments: [_attachment('one.pdf')],
      ));

      result.fold(
        (failure) {
          final typed = failure as TicketOperationFailure;
          expect(typed.type, TicketFailureType.compensation);
          expect(typed.failedStoragePaths, storage.uploadedPaths);
        },
        (_) => fail('expected compensation failure'),
      );
    });

    test('session change after upload triggers cleanup and blocks create',
        () async {
      final remote = _FakeRemote(changeSessionAfterFirstRead: true);
      final storage = _FakeStorage();
      final repository = TicketRepositoryImpl(
        remoteDataSource: remote,
        attachmentStorageDataSource: storage,
      );

      final result = await repository.createTicket(_params(
        attachments: [_attachment('one.pdf')],
      ));

      result.fold(
        (failure) {
          final typed = failure as TicketOperationFailure;
          expect(typed.type, TicketFailureType.sessionChanged);
        },
        (_) => fail('expected session-changed failure'),
      );
      expect(remote.createCallCount, 0);
      expect(storage.deletedPaths, storage.uploadedPaths);
    });
  });
}

CreateTicketParams _params({
  List<LocalAttachmentCandidate> attachments = const [],
}) {
  return CreateTicketParams(
    title: 'Printer error',
    description: 'Printer lantai 2 tidak dapat mencetak dokumen.',
    category: 'hardware',
    attachments: attachments,
  );
}

LocalAttachmentCandidate _attachment(String fileName) {
  return LocalAttachmentCandidate(
    localPath: 'C:/tmp/$fileName',
    fileName: fileName,
    mimeType: 'application/pdf',
    extension: 'pdf',
    sizeBytes: 1024,
    source: LocalAttachmentSource.document,
  );
}

class _FakeStorage implements TicketAttachmentStorageDataSource {
  final int? failUploadAt;
  final bool failDelete;
  final List<String> uploadedPaths = [];
  final List<String> deletedPaths = [];

  _FakeStorage({
    this.failUploadAt,
    this.failDelete = false,
  });

  @override
  String buildStoragePath({
    required String ticketId,
    required String userId,
    required String attachmentId,
    required LocalAttachmentCandidate candidate,
  }) {
    return '$ticketId/$userId/$attachmentId-${candidate.fileName}';
  }

  @override
  Future<UploadedTicketAttachment> upload({
    required String ticketId,
    required String userId,
    required String attachmentId,
    required LocalAttachmentCandidate candidate,
  }) async {
    if (failUploadAt == uploadedPaths.length) {
      throw const TicketCreateException(
        type: TicketFailureType.upload,
        message: 'upload failed',
      );
    }
    final path = buildStoragePath(
      ticketId: ticketId,
      userId: userId,
      attachmentId: attachmentId,
      candidate: candidate,
    );
    uploadedPaths.add(path);
    return UploadedTicketAttachment(
      id: attachmentId,
      storagePath: path,
      fileName: '$attachmentId-${candidate.fileName}',
      mimeType: candidate.mimeType,
      extension: candidate.extension,
      sizeBytes: candidate.sizeBytes,
      source: candidate.source,
    );
  }

  @override
  Future<void> deleteObject(String storagePath) async {
    deletedPaths.add(storagePath);
    if (failDelete) {
      throw TicketCreateException(
        type: TicketFailureType.compensation,
        message: 'cleanup failed',
        failedStoragePaths: [storagePath],
      );
    }
  }

  @override
  Future<List<String>> deleteObjects(List<String> storagePaths) async {
    final failed = <String>[];
    for (final path in storagePaths) {
      try {
        await deleteObject(path);
      } on TicketCreateException {
        failed.add(path);
      }
    }
    return failed;
  }
}

class _FakeRemote implements TicketRemoteDataSource {
  final bool failCreate;
  final bool changeSessionAfterFirstRead;
  int _authReadCount = 0;
  int createCallCount = 0;
  List<UploadedTicketAttachment> lastAttachments = const [];

  _FakeRemote({
    this.failCreate = false,
    this.changeSessionAfterFirstRead = false,
  });

  @override
  String? getAuthenticatedUserId() {
    _authReadCount++;
    if (changeSessionAfterFirstRead && _authReadCount > 1) {
      return 'user-2';
    }
    return 'user-1';
  }

  @override
  Future<TicketModel> createTicketWithAttachments({
    required String ticketId,
    required String title,
    required String description,
    required String category,
    required List<UploadedTicketAttachment> attachments,
  }) async {
    createCallCount++;
    lastAttachments = attachments;
    if (failCreate) {
      throw const TicketCreateException(
        type: TicketFailureType.databaseCreate,
        message: 'create failed',
      );
    }
    return TicketModel(
      id: ticketId,
      title: title,
      description: description,
      status: TicketStatus.open,
      category: category,
      createdAt: DateTime.parse('2026-06-30T00:00:00.000Z'),
      userId: 'user-1',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
