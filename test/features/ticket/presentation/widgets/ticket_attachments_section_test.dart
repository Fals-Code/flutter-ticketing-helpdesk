import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/features/ticket/data/models/ticket_attachment_model.dart';
import 'package:uts/features/ticket/domain/entities/ticket_attachment_entity.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/domain/services/ticket_attachment_viewer.dart';
import 'package:uts/features/ticket/presentation/widgets/ticket_attachments_section.dart';

void main() {
  group('TicketAttachmentsSection', () {
    testWidgets('renders image thumbnail and opens gallery on tap',
        (tester) async {
      final viewer = _FakeAttachmentViewer();
      final ticket = _ticket([
        _imageAttachment(
          id: 'att-1',
          accessUrl: 'https://example.test/image.jpg',
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TicketAttachmentsSection(
              ticket: ticket,
              isDark: false,
              viewer: viewer,
              onMessage: (_, {bool isError = false}) {},
            ),
          ),
        ),
      );

      expect(find.text('LAMPIRAN'), findsOneWidget);
      expect(find.text('Pratinjau tidak tersedia'), findsNothing);
      expect(find.byType(Image), findsOneWidget);

      await tester.tap(find.byType(InkWell).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('image attachment without signed URL does not crash',
        (tester) async {
      final viewer = _FakeAttachmentViewer();
      final ticket = _ticket([
        _imageAttachment(
          id: 'att-1',
          accessUrl: null,
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TicketAttachmentsSection(
              ticket: ticket,
              isDark: false,
              viewer: viewer,
              onMessage: (_, {bool isError = false}) {},
            ),
          ),
        ),
      );

      expect(find.text('Pratinjau tidak tersedia'), findsOneWidget);
      expect(find.byType(TicketAttachmentsSection), findsOneWidget);
    });

    testWidgets('document card opens attachment once and shows progress',
        (tester) async {
      final completer = Completer<TicketAttachmentActionResult>();
      final viewer = _FakeAttachmentViewer(
        openCallback: (_) => completer.future,
      );
      final ticket = _ticket([
        _documentAttachment(id: 'att-1', fileName: 'file.pdf'),
      ]);
      final messages = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TicketAttachmentsSection(
              ticket: ticket,
              isDark: false,
              viewer: viewer,
              onMessage: (message, {bool isError = false}) {
                messages.add(message);
              },
            ),
          ),
        ),
      );

      final card = find.byType(InkWell).last;
      await tester.tap(card);
      await tester.tap(card);
      await tester.pump();

      expect(viewer.openCalls, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(const TicketAttachmentActionResult.opened());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(messages, isEmpty);
    });

    testWidgets('download error produces a user-facing message',
        (tester) async {
      final viewer = _FakeAttachmentViewer(
        openResult: const TicketAttachmentActionResult.fileNotFound(),
      );
      final ticket = _ticket([
        _documentAttachment(id: 'att-1', fileName: 'file.pdf'),
      ]);
      final messages = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TicketAttachmentsSection(
              ticket: ticket,
              isDark: false,
              viewer: viewer,
              onMessage: (message, {bool isError = false}) {
                messages.add(message);
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell).last);
      await tester.pump();

      expect(messages, contains('File tidak ditemukan.'));
    });
  });
}

TicketEntity _ticket(List<TicketAttachmentEntity> attachments) {
  return TicketEntity(
    id: 'ticket-1',
    title: 'Printer Error',
    description: 'Printer cannot print',
    status: TicketStatus.open,
    category: 'Hardware',
    createdAt: DateTime.parse('2026-06-30T10:00:00Z'),
    userId: 'user-1',
    attachments: attachments,
  );
}

TicketAttachmentEntity _imageAttachment({
  required String id,
  required String? accessUrl,
}) {
  return TicketAttachmentModel(
    id: id,
    ticketId: 'ticket-1',
    storagePath: 'ticket-1/user-1/image.jpg',
    fileName: 'image.jpg',
    mimeType: 'image/jpeg',
    extension: 'jpg',
    sizeBytes: 1024,
    uploadedBy: 'user-1',
    createdAt: DateTime.parse('2026-06-30T10:00:00Z'),
    kind: TicketAttachmentKind.image,
    accessUrl: accessUrl,
  );
}

TicketAttachmentEntity _documentAttachment({
  required String id,
  required String fileName,
}) {
  return TicketAttachmentModel(
    id: id,
    ticketId: 'ticket-1',
    storagePath: 'ticket-1/user-1/$fileName',
    fileName: fileName,
    mimeType: 'application/pdf',
    extension: 'pdf',
    sizeBytes: 2048,
    uploadedBy: 'user-1',
    createdAt: DateTime.parse('2026-06-30T10:00:00Z'),
    kind: TicketAttachmentKind.document,
  );
}

class _FakeAttachmentViewer implements TicketAttachmentViewerDataSource {
  final Future<TicketAttachmentActionResult> Function(
    TicketAttachmentEntity attachment,
  )? openCallback;
  final TicketAttachmentActionResult? openResult;
  int openCalls = 0;

  _FakeAttachmentViewer({this.openCallback, this.openResult});

  @override
  Future<List<Map<String, dynamic>>> hydrateAttachmentPayloads(
    List<Map<String, dynamic>> attachments, {
    Duration signedUrlTtl = const Duration(minutes: 12),
  }) async {
    return attachments;
  }

  @override
  Future<TicketAttachmentActionResult> openAttachment(
    TicketAttachmentEntity attachment,
  ) async {
    openCalls++;
    if (openCallback != null) {
      return openCallback!(attachment);
    }
    return openResult ?? const TicketAttachmentActionResult.opened();
  }
}
