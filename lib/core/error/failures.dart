import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'Terjadi kesalahan pada server. Coba lagi nanti.',
    super.code = 500,
  });
}

class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Terjadi kesalahan saat membaca data lokal.',
    super.code,
  });
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
    super.code,
  });
}

class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'Terjadi kesalahan yang tidak diketahui.',
    super.code,
  });
}
