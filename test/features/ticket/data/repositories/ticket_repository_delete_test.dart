import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sup;
import 'package:uts/core/error/failures.dart';
import 'package:uts/features/ticket/data/datasources/ticket_attachment_storage_data_source.dart';
import 'package:uts/features/ticket/data/datasources/ticket_create_exceptions.dart';
import 'package:uts/features/ticket/data/datasources/ticket_remote_data_source.dart';
import 'package:uts/features/ticket/data/repositories/ticket_repository_impl.dart';
import 'package:uts/features/ticket/domain/entities/delete_ticket_result.dart';
import 'package:uts/features/ticket/domain/entities/local_attachment_candidate.dart';

void main() {
  group('TicketRepositoryImpl.deleteTicket', () {
    test('RPC success without attachment returns deletedAndCleaned', () async {
      final remote = _DeleteRemote();
      final storage = _DeleteStorage();
      final repository = TicketRepositoryImpl(
        remoteDataSource: remote,
        attachmentStorageDataSource: storage,
      );

      final result = await repository.deleteTicket(
        ticketId: 'ticket-1',
        reason: 'hapus tiket',
      );

      result.fold(
        (_) => fail('expected success'),
        (value) {
          expect(value.ticketId, 'ticket-1');
          expect(
              value.cleanupStatus, DeleteTicketCleanupStatus.deletedAndCleaned);
          expect(value.storagePaths, isEmpty);
        },
      );
      expect(storage.deletedPaths, isEmpty);
    });

    test('RPC success with attachments removes backend-provided paths',
        () async {
      final paths = ['ticket/user/a.pdf', 'ticket/user/folder-b.pdf'];
      final remote = _DeleteRemote(paths: paths);
      final storage = _DeleteStorage();
      final repository = TicketRepositoryImpl(
        remoteDataSource: remote,
        attachmentStorageDataSource: storage,
      );

      final result = await repository.deleteTicket(
        ticketId: 'ticket-1',
        reason: 'hapus tiket',
      );

      result.fold(
        (_) => fail('expected success'),
        (value) {
          expect(
              value.cleanupStatus, DeleteTicketCleanupStatus.deletedAndCleaned);
          expect(value.storagePaths, paths);
          expect(value.failedPaths, isEmpty);
        },
      );
      expect(storage.deletedPaths, paths);
    });

    test('RPC rejection does not call storage cleanup', () async {
      final remote = _DeleteRemote(
        postgrestException: sup.PostgrestException(
          message: 'ticket cannot be deleted by this account',
          code: '42501',
        ),
      );
      final storage = _DeleteStorage();
      final repository = TicketRepositoryImpl(
        remoteDataSource: remote,
        attachmentStorageDataSource: storage,
      );

      final result = await repository.deleteTicket(
        ticketId: 'ticket-1',
        reason: 'hapus tiket',
      );

      result.fold(
        (failure) {
          expect((failure as TicketOperationFailure).type,
              TicketFailureType.authorization);
        },
        (_) => fail('expected failure'),
      );
      expect(storage.deletedPaths, isEmpty);
    });

    test('storage cleanup failure returns deletedWithCleanupPending', () async {
      final paths = ['ticket/user/a.pdf', 'ticket/user/b.pdf'];
      final remote = _DeleteRemote(paths: paths);
      final storage = _DeleteStorage(failPaths: {'ticket/user/b.pdf'});
      final repository = TicketRepositoryImpl(
        remoteDataSource: remote,
        attachmentStorageDataSource: storage,
      );

      final result = await repository.deleteTicket(
        ticketId: 'ticket-1',
        reason: 'hapus tiket',
      );

      result.fold(
        (_) => fail('expected success with pending cleanup'),
        (value) {
          expect(value.cleanupStatus,
              DeleteTicketCleanupStatus.deletedWithCleanupPending);
          expect(value.storagePaths, paths);
          expect(value.failedPaths, ['ticket/user/b.pdf']);
        },
      );
      expect(storage.deletedPaths, paths);
    });
  });
}

class _DeleteRemote implements TicketRemoteDataSource {
  final List<String> paths;
  final sup.PostgrestException? postgrestException;

  _DeleteRemote({
    this.paths = const [],
    this.postgrestException,
  });

  @override
  Future<TicketDeleteRemoteResult> deleteTicket({
    required String ticketId,
    required String reason,
  }) async {
    if (postgrestException != null) {
      throw postgrestException!;
    }
    return TicketDeleteRemoteResult(
      ticketId: ticketId,
      deleted: true,
      attachmentPaths: paths,
      cleanupStatus:
          paths.isEmpty ? 'deletedAndCleaned' : 'deletedWithCleanupPending',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DeleteStorage implements TicketAttachmentStorageDataSource {
  final Set<String> failPaths;
  final List<String> deletedPaths = [];

  _DeleteStorage({this.failPaths = const {}});

  @override
  Future<List<String>> deleteObjects(List<String> storagePaths) async {
    final failed = <String>[];
    for (final path in storagePaths) {
      deletedPaths.add(path);
      if (failPaths.contains(path)) {
        failed.add(path);
      }
    }
    return failed;
  }

  @override
  Future<void> deleteObject(String storagePath) async {
    deletedPaths.add(storagePath);
    if (failPaths.contains(storagePath)) {
      throw TicketCreateException(
        type: TicketFailureType.compensation,
        message: 'cleanup failed',
        failedStoragePaths: [storagePath],
      );
    }
  }

  @override
  String buildStoragePath({
    required String ticketId,
    required String userId,
    required String attachmentId,
    required LocalAttachmentCandidate candidate,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<UploadedTicketAttachment> upload({
    required String ticketId,
    required String userId,
    required String attachmentId,
    required LocalAttachmentCandidate candidate,
  }) {
    throw UnimplementedError();
  }
}
