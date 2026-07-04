// ignore_for_file: use_super_parameters
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sup;
import 'package:uts/core/services/realtime_session_service.dart';

import '../models/ticket_model.dart';
import '../models/comment_model.dart';
import 'package:uts/features/ticket/domain/services/ticket_attachment_viewer.dart';
import 'ticket_remote_data_source.dart';

/// Realtime ticket data source with an explicitly typed stream pipeline.
///
/// The previous implementation stored the Supabase stream builder in a
/// `dynamic` variable. That erased the generic stream type and caused a runtime
/// cast failure when the result crossed the
/// `Stream<List<TicketModel>>` method boundary.
class TypedSupabaseTicketRemoteDataSourceImpl
    extends SupabaseTicketRemoteDataSourceImpl {
  final RealtimeSessionService realtimeSessionService;
  final Map<String, Map<String, dynamic>> _profileCache = {};

  TypedSupabaseTicketRemoteDataSourceImpl(
    sup.SupabaseClient supabaseClient, {
    RealtimeSessionService? realtimeSessionService,
    TicketAttachmentViewerDataSource? attachmentViewer,
  })  : realtimeSessionService = realtimeSessionService ??
            SupabaseRealtimeSessionService(supabaseClient),
        super(supabaseClient, attachmentViewer: attachmentViewer);

  @override
  Stream<List<TicketModel>> watchTickets({
    String? userId,
    String? assignedToId,
  }) {
    final channelName = _channelName(
      'tickets:list',
      userId: userId,
      assignedToId: assignedToId,
    );

    return _authenticatedStream(
      channelName: channelName,
      create: () => _watchTicketsUnsafe(
        userId: userId,
        assignedToId: assignedToId,
      ),
    );
  }

  Stream<List<TicketModel>> _watchTicketsUnsafe({
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

  @override
  Stream<TicketModel?> watchTicketDetail(String ticketId) {
    return _authenticatedStream(
      channelName: _channelName('tickets:detail', ticketId: ticketId),
      create: () => super.watchTicketDetail(ticketId),
    );
  }

  @override
  Stream<List<CommentModel>> watchTicketComments(String ticketId) {
    return _authenticatedStream(
      channelName: _channelName('comments:ticket', ticketId: ticketId),
      create: () => super.watchTicketComments(ticketId),
    );
  }

  Stream<T> _authenticatedStream<T>({
    required String channelName,
    required Stream<T> Function() create,
  }) async* {
    final generation = realtimeSessionService.generation;
    await realtimeSessionService.ensureAuthenticated(channelName: channelName);
    if (generation != realtimeSessionService.generation) {
      debugPrint(
        'Ticket realtime start ignored after cleanup channel=$channelName',
      );
      return;
    }
    yield* create();
  }

  String _channelName(
    String base, {
    String? userId,
    String? assignedToId,
    String? ticketId,
  }) {
    final parts = [
      base,
      if (userId != null && userId.isNotEmpty) 'user:${_shortId(userId)}',
      if (assignedToId != null && assignedToId.isNotEmpty)
        'assigned:${_shortId(assignedToId)}',
      if (ticketId != null && ticketId.isNotEmpty)
        'ticket:${_shortId(ticketId)}',
    ];
    return parts.join(':');
  }

  String _shortId(String value) {
    if (value.length <= 8) return value;
    return value.substring(0, 8);
  }

  Stream<List<TicketModel>> _mapTicketStream(
    Stream<List<Map<String, dynamic>>> source,
  ) {
    return source.asyncMap<List<TicketModel>>((rows) async {
      final activeRows = rows
          .where((row) => row['deleted_at'] == null)
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);

      if (activeRows.isEmpty) {
        return const <TicketModel>[];
      }

      final profileIds = <String>{};
      for (final row in activeRows) {
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

      return activeRows
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
