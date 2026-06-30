import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_bloc.dart';

@Deprecated(
  'Gunakan TicketListBloc langsung. Guard realtime dan stale response '
  'sekarang sudah berada di implementasi utama.',
)
class SafeTicketListBloc extends TicketListBloc {
  SafeTicketListBloc({
    required super.getTicketsUseCase,
    required super.getAllTicketsUseCase,
    required super.watchTicketsUseCase,
    required super.createTicketUseCase,
    required super.localDataSource,
    required super.connectivityService,
  });
}
