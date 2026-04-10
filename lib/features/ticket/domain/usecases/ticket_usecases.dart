import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/ticket_entity.dart';
import '../entities/comment_entity.dart';
import '../repositories/ticket_repository.dart';

class GetTicketsUseCase
    implements UseCase<Either<Failure, List<TicketEntity>>, GetTicketsParams> {
  final TicketRepository repository;
  GetTicketsUseCase(this.repository);

  @override
  Future<Either<Failure, List<TicketEntity>>> call(GetTicketsParams params) async {
    return await repository.getTickets(page: params.page, limit: params.limit);
  }
}

class CreateTicketUseCase implements UseCase<Either<Failure, TicketEntity>, CreateTicketParams> {
  final TicketRepository repository;
  CreateTicketUseCase(this.repository);

  @override
  Future<Either<Failure, TicketEntity>> call(CreateTicketParams params) async {
    return await repository.createTicket(
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

class GetTicketsParams extends Equatable {
  final int page;
  final int limit;
  final String? status;

  const GetTicketsParams({required this.page, this.limit = 10, this.status});

  @override
  List<Object?> get props => [page, limit, status];
}

class CreateTicketParams extends Equatable {
  final String title;
  final String description;
  final String category;
  final String priority;
  final List<String> imagePaths;

  const CreateTicketParams({
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.imagePaths,
  });

  @override
  List<Object?> get props => [title, description, category, priority, imagePaths];
}

class AddCommentParams extends Equatable {
  final String ticketId;
  final String message;

  const AddCommentParams({required this.ticketId, required this.message});

  @override
  List<Object?> get props => [ticketId, message];
}
