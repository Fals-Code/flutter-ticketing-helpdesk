import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ticket_model.dart';

abstract class TicketCacheSessionProvider {
  String? get activeUserId;
}

class SupabaseTicketCacheSessionProvider implements TicketCacheSessionProvider {
  final SupabaseClient supabaseClient;

  const SupabaseTicketCacheSessionProvider(this.supabaseClient);

  @override
  String? get activeUserId => supabaseClient.auth.currentUser?.id;
}

abstract class TicketLocalDataSource {
  /// Cache the list of tickets locally.
  Future<void> cacheTickets(List<TicketModel> tickets);

  /// Returns the last cached list of tickets.
  /// Throws [CacheException] if no cached data exists.
  Future<List<TicketModel>> getCachedTickets();

  /// Cache a single ticket detail.
  Future<void> cacheTicketDetail(TicketModel ticket);

  /// Get cached ticket detail by ID.
  Future<TicketModel?> getCachedTicketDetail(String ticketId);

  /// Remove a single cached ticket detail entry.
  Future<void> removeCachedTicketDetail(String ticketId);

  /// Clear all cached ticket data.
  Future<void> clearCache();
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'No cached tickets found.']);
  @override
  String toString() => 'CacheException: $message';
}

class SharedPrefsTicketLocalDataSource implements TicketLocalDataSource {
  static const String _legacyListCacheKey = 'cached_tickets';
  static const String _legacyDetailCachePrefix = 'cached_ticket_detail_';
  static const String _listCachePrefix = 'ticket_list::';
  static const String _detailCachePrefix = 'ticket_detail::';
  final SharedPreferences sharedPreferences;
  final TicketCacheSessionProvider sessionProvider;

  SharedPrefsTicketLocalDataSource(
    this.sharedPreferences, {
    required this.sessionProvider,
  });

  String? get activeUserId => sessionProvider.activeUserId;

  @override
  Future<void> cacheTickets(List<TicketModel> tickets) async {
    await clearLegacyCache();
    final userId = _requireActiveUserId();
    final jsonList = tickets
        .map(
          (ticket) => ticket.toJson(includeAttachmentAccessUrls: false)
            ..['id'] = ticket.id,
        )
        .toList();
    await sharedPreferences.setString(
      _listCacheKey(userId),
      jsonEncode(jsonList),
    );
  }

  @override
  Future<List<TicketModel>> getCachedTickets() async {
    await clearLegacyCache();
    final userId = _requireActiveUserId();
    final jsonString = sharedPreferences.getString(_listCacheKey(userId));
    if (jsonString == null) {
      throw CacheException();
    }
    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded
        .map((json) => TicketModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> cacheTicketDetail(TicketModel ticket) async {
    await clearLegacyCache();
    final userId = _requireActiveUserId();
    await sharedPreferences.setString(
      _detailCacheKey(userId, ticket.id),
      jsonEncode(
        ticket.toJson(includeAttachmentAccessUrls: false)..['id'] = ticket.id,
      ),
    );
  }

  @override
  Future<TicketModel?> getCachedTicketDetail(String ticketId) async {
    await clearLegacyCache();
    final userId = _requireActiveUserId();
    final jsonString = sharedPreferences.getString(
      _detailCacheKey(userId, ticketId),
    );
    if (jsonString == null) {
      return null;
    }
    return TicketModel.fromJson(jsonDecode(jsonString));
  }

  @override
  Future<void> removeCachedTicketDetail(String ticketId) async {
    await clearLegacyCache();
    final userId = activeUserId;
    if (userId == null || userId.isEmpty) {
      return;
    }
    await sharedPreferences.remove(_detailCacheKey(userId, ticketId));
  }

  @override
  Future<void> clearCache() async {
    await clearLegacyCache();
    final userId = activeUserId;
    if (userId == null || userId.isEmpty) {
      return;
    }
    final keys = sharedPreferences.getKeys();
    for (final key in keys) {
      if (key == _listCacheKey(userId) || key.startsWith(_detailCachePrefix)) {
        if (_belongsToUser(key, userId)) {
          await sharedPreferences.remove(key);
        }
      }
    }
  }

  Future<void> clearLegacyCache() async {
    final keys = sharedPreferences.getKeys();
    for (final key in keys) {
      if (key == _legacyListCacheKey ||
          key.startsWith(_legacyDetailCachePrefix)) {
        await sharedPreferences.remove(key);
      }
    }
  }

  String _requireActiveUserId() {
    final userId = activeUserId;
    if (userId == null || userId.isEmpty) {
      throw CacheException('Active ticket cache session not found.');
    }
    return userId;
  }

  static String _listCacheKey(String userId) => '$_listCachePrefix$userId';

  static String _detailCacheKey(String userId, String ticketId) =>
      '$_detailCachePrefix$userId::$ticketId';

  bool _belongsToUser(String key, String userId) {
    return key == _listCacheKey(userId) ||
        key.startsWith('$_detailCachePrefix$userId::');
  }
}
