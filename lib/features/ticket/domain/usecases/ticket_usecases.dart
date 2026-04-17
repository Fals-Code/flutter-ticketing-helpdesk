import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/ticket_entity.dart';
import '../entities/comment_entity.dart';
import '../entities/ticket_history_entity.dart';
import '../repositories/ticket_repository.dart';

class GetTicketsUseCase
    implements UseCase<Either<Failure, List<TicketEntity>>, GetTicketsParams> {
  final TicketRepository repository;
  GetTicketsUseCase(this.repository);

  @override
  Future<Either<Failure, List<TicketEntity>>> call(GetTicketsParams params) async {
    return await repository.getTickets(
      page: params.page,
      limit: params.limit,
      searchQuery: params.searchQuery,
      category: params.category,
      status: params.status,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

class CreateTicketUseCase implements UseCase<Either<Failure, TicketEntity>, CreateTicketParams> {
  final TicketRepository repository;
  CreateTicketUseCase(this.repository);

  @override
  Future<Either<Failure, TicketEntity>> call(CreateTicketParams params) async {
    return await repository.createTicket(
      userId: params.userId,
      title: params.title,
      description: params.description,
      category: params.category,
      priority: params.priority,
      imagePaths: params.imagePaths,
    );
  }
}

class GetTicketDetailUseCase implements UseCase<Either<Failure, TicketEntity>, String> {
  final TicketRepository repository;
  GetTicketDetailUseCase(this.repository);

  @override
  Future<Either<Failure, TicketEntity>> call(String ticketId) async {
    return await repository.getTicketDetail(ticketId);
  }
}

class GetTicketCommentsUseCase
    implements UseCase<Either<Failure, List<CommentEntity>>, String> {
  final TicketRepository repository;
  GetTicketCommentsUseCase(this.repository);

  @override
  Future<Either<Failure, List<CommentEntity>>> call(String ticketId) async {
    return await repository.getTicketComments(ticketId);
  }
}

class AddCommentUseCase implements UseCase<Either<Failure, CommentEntity>, AddCommentParams> {
  final TicketRepository repository;
  AddCommentUseCase(this.repository);

  @override
  Future<Either<Failure, CommentEntity>> call(AddCommentParams params) async {
    return await repository.addComment(
      ticketId: params.ticketId,
      message: params.message,
    );
  }
}

class GetTicketStatsUseCase implements UseCase<Either<Failure, TicketStats>, String?> {
  final TicketRepository repository;
  GetTicketStatsUseCase(this.repository);

  @override
  Future<Either<Failure, TicketStats>> call(String? assignedToId) async {
    return await repository.getTicketStats(assignedToId: assignedToId);
  }
}

class GetTicketHistoryUseCase implements UseCase<Either<Failure, List<TicketHistoryEntity>>, String> {
  final TicketRepository repository;
  GetTicketHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<TicketHistoryEntity>>> call(String ticketId) async {
    return await repository.getTicketHistory(ticketId);
  }
}

class GetAllTicketHistoryUseCase implements UseCase<Either<Failure, List<TicketHistoryEntity>>, GetHistoryParams> {
  final TicketRepository repository;
  GetAllTicketHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<TicketHistoryEntity>>> call(GetHistoryParams params) async {
    return await repository.getAllTicketHistory(
      changedBy: params.changedBy,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

class SubmitRatingUseCase implements UseCase<Either<Failure, TicketEntity>, SubmitRatingParams> {
  final TicketRepository repository;
  SubmitRatingUseCase(this.repository);

  @override
  Future<Either<Failure, TicketEntity>> call(SubmitRatingParams params) async {
    return await repository.submitRating(
      ticketId: params.ticketId,
      rating: params.rating,
      feedback: params.feedback,
    );
  }
}

class WatchTicketsUseCase {
  final TicketRepository repository;
  WatchTicketsUseCase(this.repository);

  Stream<List<TicketEntity>> call({String? userId, String? assignedToId}) {
    return repository.watchTickets(userId: userId, assignedToId: assignedToId);
  }
}

class GetTicketsParams extends Equatable {
  final int page;
  final int limit;
  final String? status;
  final String? searchQuery;
  final String? category;
  final DateTime? startDate;
  final DateTime? endDate;

  const GetTicketsParams({
    required this.page,
    this.limit = 10,
    this.status,
    this.searchQuery,
    this.category,
    this.assignedToId,
    this.startDate,
    this.endDate,
  });

  final String? assignedToId;

  @override
  List<Object?> get props => [page, limit, status, searchQuery, category, assignedToId, startDate, endDate];
}

class CreateTicketParams extends Equatable {
  final String userId;
  final String title;
  final String description;
  final String category;
  final String priority;
  final List<String> imagePaths;

  const CreateTicketParams({
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    this.priority = 'medium',
    required this.imagePaths,
  });

  @override
  List<Object?> get props => [userId, title, description, category, priority, imagePaths];
}

class AddCommentParams extends Equatable {
  final String ticketId;
  final String message;

  const AddCommentParams({required this.ticketId, required this.message});

  @override
  List<Object?> get props => [ticketId, message];
}

class SubmitRatingParams extends Equatable {
  final String ticketId;
  final int rating;
  final String feedback;

  const SubmitRatingParams({
    required this.ticketId,
    required this.rating,
    required this.feedback,
  });

  @override
  List<Object?> get props => [ticketId, rating, feedback];
}

class GetHistoryParams extends Equatable {
  final String? changedBy;
  final DateTime? startDate;
  final DateTime? endDate;

  const GetHistoryParams({
    this.changedBy,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [changedBy, startDate, endDate];
}
