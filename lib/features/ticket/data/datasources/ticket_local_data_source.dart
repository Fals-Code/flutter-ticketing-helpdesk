import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ticket_model.dart';

abstract class TicketLocalDataSource {
  /// Cache the list of tickets locally.
  Future<void> cacheTickets(List<TicketModel> tickets);

  /// Returns the last cached list of tickets.
  /// Throws [CacheException] if no cached data exists.
  Future<List<TicketModel>> getCachedTickets();

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
    return decoded.map((json) => TicketModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> clearCache() async {
    await sharedPreferences.remove(_cacheKey);
  }
}
