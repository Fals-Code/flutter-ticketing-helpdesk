import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ticket_model.dart';

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
  static const String _cacheKey = 'cached_tickets';
  static const String _detailCachePrefix = 'cached_ticket_detail_';
  final SharedPreferences sharedPreferences;

  SharedPrefsTicketLocalDataSource(this.sharedPreferences);

  @override
  Future<void> cacheTickets(List<TicketModel> tickets) async {
    final jsonList = tickets.map((t) => t.toJson()..['id'] = t.id).toList();
    await sharedPreferences.setString(_cacheKey, jsonEncode(jsonList));
  }

  @override
  Future<List<TicketModel>> getCachedTickets() async {
    final jsonString = sharedPreferences.getString(_cacheKey);
    if (jsonString == null) throw CacheException();
    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded
        .map((json) => TicketModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> cacheTicketDetail(TicketModel ticket) async {
    await sharedPreferences.setString(
      '$_detailCachePrefix${ticket.id}',
      jsonEncode(ticket.toJson()..['id'] = ticket.id),
    );
  }

  @override
  Future<TicketModel?> getCachedTicketDetail(String ticketId) async {
    final jsonString =
        sharedPreferences.getString('$_detailCachePrefix$ticketId');
    if (jsonString == null) return null;
    return TicketModel.fromJson(jsonDecode(jsonString));
  }

  @override
  Future<void> removeCachedTicketDetail(String ticketId) async {
    await sharedPreferences.remove('$_detailCachePrefix$ticketId');
  }

  @override
  Future<void> clearCache() async {
    final keys = sharedPreferences.getKeys();
    for (final key in keys) {
      if (key.startsWith(_detailCachePrefix) || key == _cacheKey) {
        await sharedPreferences.remove(key);
      }
    }
  }
}
