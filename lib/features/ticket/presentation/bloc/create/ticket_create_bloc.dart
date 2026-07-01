import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uts/core/error/failures.dart';
import 'package:uts/features/ticket/domain/entities/create_ticket_params.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_usecases.dart';

import 'ticket_create_event.dart';
import 'ticket_create_state.dart';

class TicketCreateBloc extends Bloc<TicketCreateEvent, TicketCreateState> {
  final CreateTicketUseCase createTicketUseCase;
  int _operationGeneration = 0;

  TicketCreateBloc({
    required this.createTicketUseCase,
  }) : super(const TicketCreateState()) {
    on<SubmitTicketCreateRequested>(_onSubmit);
    on<TicketCreateResetRequested>(_onReset);
  }

  Future<void> _onSubmit(
    SubmitTicketCreateRequested event,
    Emitter<TicketCreateState> emit,
  ) async {
    if (state.isBusy) {
      // Keep the in-flight operation generation intact so its success/failure
      // can still update the UI after a fast duplicate tap.
      return;
    }

    _operationGeneration++;
    final generation = _operationGeneration;

    emit(state.copyWith(
      status: TicketCreateStatus.validating,
      attachments: event.attachments,
      uploadedCount: 0,
      totalCount: event.attachments.length,
      clearMessage: true,
      clearTicket: true,
      clearCurrentFileName: true,
    ));

    final result = await createTicketUseCase(CreateTicketParams(
      title: event.title,
      description: event.description,
      category: event.category,
      attachments: event.attachments,
      onProgress: (progress) {
        if (!emit.isDone && generation == _operationGeneration && !isClosed) {
          emit(state.applyProgress(progress));
        }
      },
    ));

    if (generation != _operationGeneration || isClosed) {
      return;
    }

    result.fold(
      (failure) {
        if (generation != _operationGeneration || isClosed) {
          return;
        }
        emit(state.copyWith(
          status: _statusFromFailure(failure),
          message: failure.message,
          clearCurrentFileName: true,
        ));
      },
      (ticket) {
        if (generation != _operationGeneration || isClosed) {
          return;
        }
        emit(state.copyWith(
          status: TicketCreateStatus.success,
          ticket: ticket,
          message: 'Laporan berhasil dibuat',
          uploadedCount: event.attachments.length,
          totalCount: event.attachments.length,
          clearCurrentFileName: true,
        ));
      },
    );
  }

  void _onReset(
    TicketCreateResetRequested event,
    Emitter<TicketCreateState> emit,
  ) {
    _operationGeneration++;
    emit(const TicketCreateState());
  }

  TicketCreateStatus _statusFromFailure(Failure failure) {
    if (failure is! TicketOperationFailure) {
      return TicketCreateStatus.createFailure;
    }

    return switch (failure.type) {
      TicketFailureType.validation ||
      TicketFailureType.duplicateSubmit =>
        TicketCreateStatus.validationFailure,
      TicketFailureType.upload ||
      TicketFailureType.fileUnreadable =>
        TicketCreateStatus.uploadFailure,
      TicketFailureType.compensation => TicketCreateStatus.compensationFailure,
      _ => TicketCreateStatus.createFailure,
    };
  }
}
