class ServerException implements Exception {
  final String? message;
  final int? code;
  ServerException({this.message, this.code});
  
  @override
  String toString() => 'ServerException: ${message ?? "Unknown server error"}';
}

class CacheException implements Exception {}

class OfflineException implements Exception {}
