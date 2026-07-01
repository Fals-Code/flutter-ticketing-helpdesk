import 'package:uts/core/error/failures.dart';

class TicketCreateException implements Exception {
  final TicketFailureType type;
  final String message;
  final int? code;
  final List<String> failedStoragePaths;

  const TicketCreateException({
    required this.type,
    required this.message,
    this.code,
    this.failedStoragePaths = const [],
  });

  @override
  String toString() => message;
}
