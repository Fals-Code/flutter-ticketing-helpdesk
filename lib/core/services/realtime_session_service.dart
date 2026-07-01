import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sup;

enum RealtimeSessionFailureType {
  authentication,
  configuration,
  transient,
  unknown,
}

class RealtimeSessionException implements Exception {
  final RealtimeSessionFailureType type;
  final String message;
  final Object? cause;

  const RealtimeSessionException({
    required this.type,
    required this.message,
    this.cause,
  });

  bool get isAuthenticationFailure =>
      type == RealtimeSessionFailureType.authentication;

  @override
  String toString() => message;
}

abstract class RealtimeSessionService {
  int get generation;

  Future<void> ensureAuthenticated({required String channelName});

  Future<void> stopAll({required String reason});
}

class SupabaseRealtimeSessionService implements RealtimeSessionService {
  final sup.SupabaseClient supabaseClient;
  int _generation = 0;
  Future<void>? _refreshInFlight;

  SupabaseRealtimeSessionService(this.supabaseClient);

  @override
  int get generation => _generation;

  @override
  Future<void> ensureAuthenticated({required String channelName}) async {
    final session = supabaseClient.auth.currentSession;
    if (session == null) {
      debugPrint(
        'Ticket realtime auth missing for channel=$channelName',
      );
      throw const RealtimeSessionException(
        type: RealtimeSessionFailureType.authentication,
        message: 'Sesi Anda telah berakhir. Silakan masuk kembali.',
      );
    }

    var activeSession = session;
    if (activeSession.isExpired) {
      debugPrint(
        'Ticket realtime refreshing expired session for channel=$channelName',
      );
      try {
        _refreshInFlight ??= supabaseClient.auth
            .refreshSession()
            .then<void>((_) {})
            .whenComplete(() => _refreshInFlight = null);
        await _refreshInFlight;
        activeSession = supabaseClient.auth.currentSession ?? activeSession;
      } on Object catch (error) {
        debugPrint(
          'Ticket realtime session refresh failed for channel=$channelName: '
          '${error.runtimeType}',
        );
        throw RealtimeSessionException(
          type: RealtimeSessionFailureType.authentication,
          message: 'Sesi Anda telah berakhir. Silakan masuk kembali.',
          cause: error,
        );
      }
    }

    try {
      await supabaseClient.realtime.setAuth(activeSession.accessToken);
      debugPrint('Ticket realtime auth ready for channel=$channelName');
    } on Object catch (error) {
      debugPrint(
        'Ticket realtime setAuth failed for channel=$channelName: '
        '${error.runtimeType}',
      );
      throw RealtimeSessionException(
        type: RealtimeSessionFailureType.configuration,
        message:
            'Pembaruan langsung belum dapat tersambung. Silakan coba lagi.',
        cause: error,
      );
    }
  }

  @override
  Future<void> stopAll({required String reason}) async {
    _generation++;
    debugPrint('Ticket realtime stopAll reason=$reason');
    try {
      await supabaseClient.removeAllChannels();
    } on Object catch (error) {
      debugPrint('Ticket realtime removeAllChannels failed: $error');
    }
    try {
      await supabaseClient.realtime.setAuth(null);
    } on Object catch (error) {
      debugPrint('Ticket realtime clear auth failed: ${error.runtimeType}');
    }
  }
}
