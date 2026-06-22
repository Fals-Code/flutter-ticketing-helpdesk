import 'package:flutter/foundation.dart';

import '../models/ticket_model.dart';
import 'ticket_remote_data_source.dart';

/// Realtime ticket data source with an explicitly typed stream pipeline.
///
/// The previous implementation stored the Supabase stream builder in a
/// `dynamic` variable. That erased the generic stream type and caused a runtime
/// cast failure when the result crossed the
/// `Stream<List<TicketModel>>` method boundary.
class TypedSupabaseTicketRemoteDataSourceImpl
    extends SupabaseTicketRemoteDataSourceImpl {
  final Map<String, Map<String, dynamic>> _profileCache = {};

  TypedSupabaseTicketRemoteDataSourceImpl(super.supabaseClient);

  @override
  Stream<List<TicketModel>> watchTickets({
    String? userId,
    String? assignedToId,
  }) {
    final source = supabaseClient.from('tickets').stream(primaryKey: ['id']);

    if (userId != null && assignedToId != null) {
      final userScopedSource = source.eq('user_id', userId);
      final doublyFilteredSource = userScopedSource.map(
        (rows) => rows
            .where((row) => row['assigned_to'] == assignedToId)
            .map((row) => Map<String, dynamic>.from(row))
            .toList(growable: false),
      );

      return _mapTicketStream(doublyFilteredSource);
    }

    if (userId != null) {
      return _mapTicketStream(source.eq('user_id', userId));
    }

    if (assignedToId != null) {
      return _mapTicketStream(source.eq('assigned_to', assignedToId));
    }

    return _mapTicketStream(source);
  }

  Stream<List<TicketModel>> _mapTicketStream(
    Stream<List<Map<String, dynamic>>> source,
  ) {
    return source.asyncMap<List<TicketModel>>((rows) async {
      if (rows.isEmpty) {
        return const <TicketModel>[];
      }

      final mutableRows = rows
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);

      final profileIds = <String>{};
      for (final row in mutableRows) {
        final reporterId = row['user_id'];
        final technicianId = row['assigned_to'];

        if (reporterId is String && reporterId.isNotEmpty) {
          profileIds.add(reporterId);
        }
        if (technicianId is String && technicianId.isNotEmpty) {
          profileIds.add(technicianId);
        }
      }

      if (profileIds.isNotEmpty) {
        try {
          final response = await supabaseClient
              .from('profiles')
              .select('id, full_name, role')
              .inFilter('id', profileIds.toList(growable: false));

          final profiles = List<Map<String, dynamic>>.from(response);
          for (final profile in profiles) {
            final id = profile['id'];
            if (id is String && id.isNotEmpty) {
              _profileCache[id] = profile;
            }
          }
        } catch (error) {
          debugPrint('Error hydrating realtime ticket profiles: $error');
        }
      }

      return mutableRows
          .map((row) {
            final reporterId = row['user_id'];
            final technicianId = row['assigned_to'];

            if (reporterId is String) {
              final profile = _profileCache[reporterId];
              if (profile != null) {
                row['profiles'] = profile;
              }
            }

            if (technicianId is String) {
              final profile = _profileCache[technicianId];
              if (profile != null) {
                row['technician'] = profile;
              }
            }

            try {
              return TicketModel.fromJson(row);
            } catch (error) {
              debugPrint('Realtime ticket mapping error: $error');
              return null;
            }
          })
          .whereType<TicketModel>()
          .toList(growable: false);
    });
  }
}
