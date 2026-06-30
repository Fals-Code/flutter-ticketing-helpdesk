import 'package:equatable/equatable.dart';

class TicketCommentValidationResult extends Equatable {
  final bool isValid;
  final String trimmedMessage;
  final String? message;

  const TicketCommentValidationResult._({
    required this.isValid,
    required this.trimmedMessage,
    this.message,
  });

  const TicketCommentValidationResult.valid(String trimmedMessage)
      : this._(
          isValid: true,
          trimmedMessage: trimmedMessage,
        );

  const TicketCommentValidationResult.invalid({
    required String message,
    String trimmedMessage = '',
  }) : this._(
          isValid: false,
          trimmedMessage: trimmedMessage,
          message: message,
        );

  @override
  List<Object?> get props => [isValid, trimmedMessage, message];
}

class TicketCommentValidator {
  static const int maxCommentLength = 5000;

  const TicketCommentValidator();

  TicketCommentValidationResult validate(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return const TicketCommentValidationResult.invalid(
        message: 'Pesan tidak boleh kosong.',
      );
    }

    if (trimmed.length > maxCommentLength) {
      return const TicketCommentValidationResult.invalid(
        message: 'Pesan melebihi batas maksimum.',
      );
    }

    return TicketCommentValidationResult.valid(trimmed);
  }
}
