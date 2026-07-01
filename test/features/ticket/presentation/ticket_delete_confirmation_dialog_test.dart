import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uts/features/ticket/presentation/widgets/ticket_delete_confirmation_dialog.dart';

void main() {
  testWidgets('cancel does not invoke delete confirmation callback',
      (tester) async {
    var confirmCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => TicketDeleteConfirmationDialog(
                      onConfirm: (_) async => confirmCalls++,
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ticket-delete-cancel-button')));
    await tester.pumpAndSettle();

    expect(confirmCalls, 0);
  });

  testWidgets('confirm forwards delete reason', (tester) async {
    String? receivedReason;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TicketDeleteConfirmationDialog(
            onConfirm: (reason) async => receivedReason = reason,
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('ticket-delete-reason-field')),
      '  tiket duplikat  ',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('ticket-delete-confirm-button')));
    await tester.pump();

    expect(receivedReason, '  tiket duplikat  ');
  });
}
