import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sup;
import 'package:uts/features/ticket/domain/value_objects/paginated_result.dart';
import 'package:uts/features/ticket/domain/value_objects/ticket_query.dart';
import '../models/ticket_model.dart';
import '../models/comment_model.dart';
import '../models/ticket_history_model.dart';
import 'ticket_attachment_storage_data_source.dart';
import 'ticket_create_exceptions.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/core/error/failures.dart';

abstract class TicketRemoteDataSource {
  Future<PaginatedResult<TicketModel>> getTickets(
    TicketQuery query,
  );
  Future<PaginatedResult<TicketModel>> getAllTickets(
    TicketQuery query, {
    String? assignedToId,
  });
  Future<List<Map<String, dynamic>>> getStaffUsers();
  String? getAuthenticatedUserId();
  Future<TicketModel> createTicketWithAttachments({
    required String ticketId,
    required String title,
    required String description,
    required String category,
    required List<UploadedTicketAttachment> attachments,
  });
  Future<TicketModel> getTicketDetail(String ticketId);
  Future<List<CommentModel>> getTicketComments(String ticketId);
  Future<CommentModel> addComment(CommentModel comment);
  Future<void> deleteTicket({
    required String ticketId,
    required String reason,
  });
  Future<TicketModel> updateTicketStatus(String ticketId, TicketStatus status);
  Future<TicketModel> assignTicket(String ticketId, String technicianId);
  Future<TicketModel> submitRating(
      String ticketId, int rating, String feedback);
  Future<List<TicketHistoryModel>> getTicketHistory(String ticketId);
  Future<List<TicketHistoryModel>> getAllTicketHistory(
      {String? changedBy, DateTime? startDate, DateTime? endDate});
  Future<Map<String, int>> getTicketStats({
    String? assignedToId,
    String? category,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  });
  Stream<List<TicketModel>> watchTickets(
      {String? userId, String? assignedToId});
  Stream<TicketModel?> watchTicketDetail(String ticketId);
  Stream<List<CommentModel>> watchTicketComments(String ticketId);
  Future<void> clearProfileCache();
}

class SupabaseTicketRemoteDataSourceImpl implements TicketRemoteDataSource {
  final sup.SupabaseClient supabaseClient;
  static const String _ticketSelect =
      '*, profiles:user_id(*), technician:assigned_to(*), ticket_attachments(*)';
  final Map<String, Map<String, dynamic>> _profileCache = {};

  SupabaseTicketRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<Map<String, int>> getTicketStats({
    String? assignedToId,
    String? category,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Supabase RPC may not support all filter combinations in the current backend.
      // For dashboard filtering, fetch matching ticket rows and aggregate locally.
      final query = supabaseClient.from('tickets').select('status');

      if (assignedToId != null) {
        query.eq('assigned_to', assignedToId);
      }
      if (status != null && status.isNotEmpty && status != 'all') {
        query.eq('status', status);
      }
      if (category != null && category.isNotEmpty) {
        query.eq('category', category);
      }
      if (startDate != null) {
        query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query.lte('created_at', endDate.toIso8601String());
      }

      final response =
          await query.order('created_at', ascending: false).range(0, 9999);

      final Map<String, int> stats = {
        'total': 0,
        'open': 0,
        'pending': 0,
        'in_progress': 0,
        'resolved': 0,
        'closed': 0,
        'reopened': 0,
      };

      for (var row in (response as List<dynamic>)) {
        final String statusValue = (row['status'] as String).toLowerCase();
        if (stats.containsKey(statusValue)) {
          stats[statusValue] = stats[statusValue]! + 1;
        }
        stats['total'] = stats['total']! + 1;
      }

      return stats;
    } on sup.PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch stats: $e');
    }
  }

  @override
  Future<PaginatedResult<TicketModel>> getTickets(
    TicketQuery ticketQuery,
  ) async {
    final from = ticketQuery.offset;
    final to = from + ticketQuery.limit - 1;
    var builder = supabaseClient
        .from('tickets')
        .select(_ticketSelect)
        .isFilter('deleted_at', null)
        .eq('user_id', supabaseClient.auth.currentUser!.id);

    if (ticketQuery.status != null) {
      builder = builder.eq('status', ticketQuery.status!.dbValue);
    }
    if (ticketQuery.category != null) {
      builder = builder.eq('category', ticketQuery.category!);
    }
    if (ticketQuery.search != null && ticketQuery.search!.isNotEmpty) {
      final escapedSearch = _sanitizeSearchTerm(ticketQuery.search!);
      builder = builder.or(
        'title.ilike.%$escapedSearch%,description.ilike.%$escapedSearch%',
      );
    }
    if (ticketQuery.startDate != null) {
      builder =
          builder.gte('created_at', ticketQuery.startDate!.toIso8601String());
    }
    if (ticketQuery.endDate != null) {
      builder =
          builder.lte('created_at', ticketQuery.endDate!.toIso8601String());
    }

    final response = await builder
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(from, to);

    final items = _mapTicketRows(response);
    return PaginatedResult<TicketModel>(
      items: items,
      hasMore: items.length == ticketQuery.limit,
      nextPage: items.length == ticketQuery.limit ? ticketQuery.page + 1 : null,
      nextOffset: items.length == ticketQuery.limit
          ? ticketQuery.offset + ticketQuery.limit
          : null,
    );
  }

  @override
  Future<PaginatedResult<TicketModel>> getAllTickets(
    TicketQuery ticketQuery, {
    String? assignedToId,
  }) async {
    final from = ticketQuery.offset;
    final to = from + ticketQuery.limit - 1;

    var query = supabaseClient
        .from('tickets')
        .select(_ticketSelect)
        .isFilter('deleted_at', null);

    if (assignedToId != null) {
      query = query.eq('assigned_to', assignedToId);
    }

    if (ticketQuery.status != null) {
      query = query.eq('status', ticketQuery.status!.dbValue);
    }
    if (ticketQuery.category != null) {
      query = query.eq('category', ticketQuery.category!);
    }
    if (ticketQuery.search != null && ticketQuery.search!.isNotEmpty) {
      final escapedSearch = _sanitizeSearchTerm(ticketQuery.search!);
      query = query.or(
        'title.ilike.%$escapedSearch%,description.ilike.%$escapedSearch%',
      );
    }
    if (ticketQuery.startDate != null) {
      query = query.gte('created_at', ticketQuery.startDate!.toIso8601String());
    }
    if (ticketQuery.endDate != null) {
      query = query.lte('created_at', ticketQuery.endDate!.toIso8601String());
    }

    final response = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(from, to);

    final items = _mapTicketRows(response);
    return PaginatedResult<TicketModel>(
      items: items,
      hasMore: items.length == ticketQuery.limit,
      nextPage: items.length == ticketQuery.limit ? ticketQuery.page + 1 : null,
      nextOffset: items.length == ticketQuery.limit
          ? ticketQuery.offset + ticketQuery.limit
          : null,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getStaffUsers() async {
    final response = await supabaseClient
        .from('profiles')
        .select('id, full_name, email, role')
        .eq('role', 2);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  String? getAuthenticatedUserId() => supabaseClient.auth.currentUser?.id;

  @override
  Future<TicketModel> createTicketWithAttachments({
    required String ticketId,
    required String title,
    required String description,
    required String category,
    required List<UploadedTicketAttachment> attachments,
  }) async {
    try {
      await supabaseClient.rpc('create_ticket_with_attachments', params: {
        'p_ticket_id': ticketId,
        'p_title': title,
        'p_description': description,
        'p_category': category,
        'p_attachments': attachments
            .map((attachment) => attachment.toManifestJson())
            .toList(growable: false),
      });
    } on sup.PostgrestException catch (error) {
      throw TicketCreateException(
        type: _mapPostgrestFailureType(error),
        message: _safeDatabaseMessage(error),
        code: int.tryParse(error.code ?? ''),
      );
    } catch (_) {
      throw const TicketCreateException(
        type: TicketFailureType.databaseCreate,
        message: 'Gagal menyimpan tiket.',
      );
    }

    try {
      return await getTicketDetail(ticketId);
    } catch (_) {
      final actorId = getAuthenticatedUserId() ?? '';
      return TicketModel(
        id: ticketId,
        title: title,
        description: description,
        status: TicketStatus.open,
        category: category,
        createdAt: DateTime.now(),
        userId: actorId,
      );
    }
  }

  @override
  Future<TicketModel> getTicketDetail(String ticketId) async {
    final response = await supabaseClient
        .from('tickets')
        .select(_ticketSelect)
        .isFilter('deleted_at', null)
        .eq('id', ticketId)
        .single();

    return TicketModel.fromJson(response);
  }

  @override
  Future<void> deleteTicket({
    required String ticketId,
    required String reason,
  }) async {
    await supabaseClient.rpc('delete_ticket_with_attachments', params: {
      'p_ticket_id': ticketId,
      'p_reason': reason,
    });
  }

  @override
  Future<TicketModel> updateTicketStatus(
      String ticketId, TicketStatus status) async {
    final response = await supabaseClient
        .from('tickets')
        .update({
          'status': status.dbValue,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', ticketId)
        .select(_ticketSelect)
        .single();

    final updatedTicket = TicketModel.fromJson(response);

    // Notify User
    await _notifyUser(
      userId: updatedTicket.userId,
      title: 'Update Tiket #${ticketId.substring(0, 8).toUpperCase()}',
      message: 'Status tiket Anda kini ${status.label.toUpperCase()}',
      ticketId: ticketId,
    );

    return updatedTicket;
  }

  @override
  Future<TicketModel> assignTicket(String ticketId, String technicianId) async {
    // 1. Get current status to check if closed
    final currentTicket = await getTicketDetail(ticketId);
    if (currentTicket.status == TicketStatus.closed) {
      throw Exception(
          'Tiket yang sudah ditutup tidak dapat didelegasikan ulang.');
    }

    final response = await supabaseClient
        .from('tickets')
        .update({
          'assigned_to': technicianId,
          'status':
              'in_progress', // Auto update status to In Progress when assigned
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', ticketId)
        .select(_ticketSelect)
        .single();

    final updatedTicket = TicketModel.fromJson(response);

    // Notify User
    await _notifyUser(
      userId: updatedTicket.userId,
      title: 'Update Penanganan Tiket',
      message: 'Petugas sedang memproses tiket Anda.',
      ticketId: ticketId,
    );

    return updatedTicket;
  }

  @override
  Future<TicketModel> submitRating(
      String ticketId, int rating, String feedback) async {
    try {
      final response = await supabaseClient
          .from('tickets')
          .update({
            'rating': rating,
            'feedback': feedback,
            'status': 'closed', // Auto close ticket after rating
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', ticketId)
          .select(_ticketSelect)
          .single();

      final updatedTicket = TicketModel.fromJson(response);

      // Notify User
      await _notifyUser(
        userId: updatedTicket.userId,
        title: 'Tiket Ditutup',
        message: 'Terima kasih atas penilaian Anda. Tiket ini telah ditutup.',
        ticketId: ticketId,
      );

      return updatedTicket;
    } on sup.PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to submit rating: $e');
    }
  }

  @override
  Future<List<TicketHistoryModel>> getTicketHistory(String ticketId) async {
    try {
      final response = await supabaseClient
          .from('ticket_history')
          .select('*, profiles!ticket_history_changed_by_fkey(full_name)')
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => TicketHistoryModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<TicketHistoryModel>> getAllTicketHistory(
      {String? changedBy, DateTime? startDate, DateTime? endDate}) async {
    try {
      var query = supabaseClient
          .from('ticket_history')
          .select('*, profiles:ticket_history_changed_by_fkey(full_name)');

      if (changedBy != null) {
        query = query.eq('changed_by', changedBy);
      }
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response =
          await query.order('created_at', ascending: false).limit(50);

      return (response as List)
          .map((json) => TicketHistoryModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<List<TicketModel>> watchTickets(
      {String? userId, String? assignedToId}) {
    dynamic query = supabaseClient.from('tickets').stream(primaryKey: ['id']);

    if (userId != null) {
      query = query.eq('user_id', userId);
    }

    if (assignedToId != null) {
      query = query.eq('assigned_to', assignedToId);
    }

    return query.asyncMap((data) async {
      final activeRows = data
          .where((row) => row['deleted_at'] == null)
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);

      if (activeRows.isEmpty) return [];

      // Hydration: Fetch profile information for the tickets in the stream
      final userIds = activeRows
          .map((e) => e['user_id'] as String)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      if (userIds.isNotEmpty) {
        try {
          // Fetch profiles in batch
          final List<dynamic> profilesResponse = await supabaseClient
              .from('profiles')
              .select('id, full_name, role')
              .inFilter('id', userIds);

          final profileMap = {
            for (var profile in profilesResponse) profile['id']: profile
          };

          // Cache profiles while we are at it
          for (var profile in profilesResponse) {
            _profileCache[profile['id']] = profile;
          }

          return activeRows
              .map((json) {
                final profile = profileMap[json['user_id']];
                if (profile != null) {
                  json['profiles'] = profile;
                } else if (_profileCache.containsKey(json['user_id'])) {
                  json['profiles'] = _profileCache[json['user_id']];
                }

                try {
                  return TicketModel.fromJson(json);
                } catch (e) {
                  debugPrint('Ticket Stream Mapping Error: $e');
                  return null;
                }
              })
              .whereType<TicketModel>()
              .toList();
        } catch (e) {
          debugPrint('Error hydrating ticket stream: $e');
        }
      }

      // Fallback if hydration fails or no user IDs
      return activeRows
          .map((json) {
            try {
              return TicketModel.fromJson(json);
            } catch (e) {
              return null;
            }
          })
          .whereType<TicketModel>()
          .toList();
    });
  }

  @override
  Stream<TicketModel?> watchTicketDetail(String ticketId) {
    return supabaseClient
        .from('tickets')
        .stream(primaryKey: ['id'])
        .eq('id', ticketId)
        .map((rows) => rows
            .where((row) => row['deleted_at'] == null)
            .map((row) => Map<String, dynamic>.from(row))
            .toList(growable: false))
        .asyncMap<TicketModel?>((rows) async {
          if (rows.isEmpty) {
            return null;
          }

          final row = rows.first;
          final reporterId = row['user_id'];
          final technicianId = row['assigned_to'];
          final profileIds = <String>{};

          if (reporterId is String && reporterId.isNotEmpty) {
            profileIds.add(reporterId);
          }
          if (technicianId is String && technicianId.isNotEmpty) {
            profileIds.add(technicianId);
          }

          if (profileIds.isNotEmpty) {
            try {
              final response = await supabaseClient
                  .from('profiles')
                  .select('id, full_name, role')
                  .inFilter('id', profileIds.toList(growable: false));

              for (final profile in List<Map<String, dynamic>>.from(response)) {
                final id = profile['id'];
                if (id is String && id.isNotEmpty) {
                  _profileCache[id] = profile;
                }
              }
            } catch (error) {
              debugPrint('Error hydrating ticket detail stream: $error');
            }
          }

          if (reporterId is String && _profileCache.containsKey(reporterId)) {
            row['profiles'] = _profileCache[reporterId];
          }
          if (technicianId is String &&
              _profileCache.containsKey(technicianId)) {
            row['technician'] = _profileCache[technicianId];
          }

          try {
            return TicketModel.fromJson(row);
          } catch (error) {
            debugPrint('Realtime ticket detail mapping error: $error');
            return null;
          }
        });
  }

  Future<void> _notifyUser({
    required String userId,
    required String title,
    required String message,
    String? ticketId,
  }) async {
    try {
      await supabaseClient.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'ticket_id': ticketId,
        'is_read': false,
      });
    } catch (e) {
      // Ignored: Notifying shouldn't break the main flow
    }
  }

  @override
  Future<List<CommentModel>> getTicketComments(String ticketId) async {
    final response = await supabaseClient
        .from('comments')
        .select('*, profiles(full_name, role)')
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => CommentModel.fromJson(json))
        .toList();
  }

  @override
  Future<CommentModel> addComment(CommentModel comment) async {
    final commentData = comment.toJson();
    // Injection of current authenticated user ID
    commentData['user_id'] = supabaseClient.auth.currentUser!.id;

    final response = await supabaseClient
        .from('comments')
        .insert(commentData)
        .select('*, profiles(full_name, role)')
        .single();

    return CommentModel.fromJson(response);
  }

  @override
  Stream<List<CommentModel>> watchTicketComments(String ticketId) {
    return supabaseClient
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: true)
        .asyncMap((data) async {
          // 1. Parse raw comments
          final List<CommentModel> comments = data
              .map((json) {
                try {
                  return CommentModel.fromJson(json);
                } catch (e) {
                  debugPrint('Comment Stream Parsing Error: $e');
                  return null;
                }
              })
              .whereType<CommentModel>()
              .toList();

          if (comments.isEmpty) return comments;

          // 2. Identify unique user IDs that are not in cache
          final userIds = comments.map((c) => c.userId).toSet();
          final missingUserIds =
              userIds.where((id) => !_profileCache.containsKey(id)).toList();

          // 3. Fetch missing profiles
          if (missingUserIds.isNotEmpty) {
            try {
              final List<dynamic> profilesResponse = await supabaseClient
                  .from('profiles')
                  .select('id, full_name, role')
                  .inFilter('id', missingUserIds);

              for (var profile in profilesResponse) {
                _profileCache[profile['id']] = profile;
              }
            } catch (e) {
              debugPrint('Error fetching profiles for comments: $e');
            }
          }

          // 4. Enrich comments with cached profile data
          return comments.map((comment) {
            final profile = _profileCache[comment.userId];
            if (profile != null) {
              final roleInt = profile['role'] as int?;
              final roleName = roleInt != null
                  ? UserRole.fromInt(roleInt).name
                  : (profile['role']?.toString() ?? 'user');

              return comment.copyWith(
                userName: profile['full_name'] ?? 'Unknown',
                userRole: roleName,
              );
            }
            return comment;
          }).toList();
        });
  }

  @override
  Future<void> clearProfileCache() async {
    _profileCache.clear();
  }

  TicketFailureType _mapPostgrestFailureType(sup.PostgrestException error) {
    switch (error.code) {
      case '42501':
        return TicketFailureType.authorization;
      case '22023':
      case '23514':
        return TicketFailureType.validation;
      default:
        return TicketFailureType.databaseCreate;
    }
  }

  String _safeDatabaseMessage(sup.PostgrestException error) {
    switch (error.code) {
      case '42501':
        return 'Anda tidak berwenang membuat tiket.';
      case '22023':
      case '23514':
        return 'Data tiket atau lampiran tidak valid.';
      default:
        return 'Gagal menyimpan tiket.';
    }
  }

  List<TicketModel> _mapTicketRows(dynamic response) {
    return (response as List)
        .where((json) => (json as Map<String, dynamic>)['deleted_at'] == null)
        .map((json) {
          try {
            return TicketModel.fromJson(json);
          } catch (error) {
            debugPrint('Error parsing ticket: $error');
            return null;
          }
        })
        .whereType<TicketModel>()
        .toList(growable: false);
  }

  String _sanitizeSearchTerm(String input) {
    return input
        .trim()
        .replaceAll('\\', '')
        .replaceAll(',', ' ')
        .replaceAll('(', ' ')
        .replaceAll(')', ' ')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
  }
}
