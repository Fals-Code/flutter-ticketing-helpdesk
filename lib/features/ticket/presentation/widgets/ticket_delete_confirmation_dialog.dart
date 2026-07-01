import 'package:flutter/material.dart';

class TicketDeleteConfirmationDialog extends StatefulWidget {
  final bool isDeleting;
  final Future<void> Function(String reason) onConfirm;

  const TicketDeleteConfirmationDialog({
    super.key,
    required this.onConfirm,
    this.isDeleting = false,
  });

  @override
  State<TicketDeleteConfirmationDialog> createState() =>
      _TicketDeleteConfirmationDialogState();
}

class _TicketDeleteConfirmationDialogState
    extends State<TicketDeleteConfirmationDialog> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        _reasonController.text.trim().length >= 3 && !widget.isDeleting;

    return AlertDialog(
      title: const Text('Hapus tiket?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tindakan ini meminta backend melakukan soft delete tiket dan cleanup lampiran sesuai policy.',
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('ticket-delete-reason-field'),
            controller: _reasonController,
            autofocus: true,
            maxLines: 3,
            minLines: 2,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Alasan penghapusan',
              hintText: 'Tulis alasan minimal 3 karakter',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('ticket-delete-cancel-button'),
          onPressed:
              widget.isDeleting ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('ticket-delete-confirm-button'),
          onPressed: canSubmit
              ? () async {
                  await widget.onConfirm(_reasonController.text);
                }
              : null,
          child: widget.isDeleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Hapus'),
        ),
      ],
    );
  }
}
