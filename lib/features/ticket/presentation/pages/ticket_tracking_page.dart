import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/domain/entities/ticket_tracking_view_data.dart';
import 'package:uts/features/ticket/presentation/bloc/tracking/ticket_tracking_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/tracking/ticket_tracking_event.dart';
import 'package:uts/features/ticket/presentation/bloc/tracking/ticket_tracking_state.dart';
import 'package:uts/features/ticket/presentation/widgets/tracking/tracking_widgets.dart';
import 'package:uts/shared/widgets/app_button.dart';

class TicketTrackingPage extends StatelessWidget {
  final String ticketId;

  const TicketTrackingPage({
    super.key,
    required this.ticketId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Tracking Tiket'),
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        surfaceTintColor: Colors.transparent,
      ),
      body: BlocBuilder<TicketTrackingBloc, TicketTrackingState>(
        builder: (context, state) {
          return switch (state.status) {
            TicketTrackingStatus.initial ||
            TicketTrackingStatus.loading =>
              const Center(child: CircularProgressIndicator()),
            TicketTrackingStatus.notFound => _TrackingMessageState(
                isDark: isDark,
                icon: Icons.search_off_rounded,
                title: 'Tiket tidak ditemukan',
                message:
                    'Riwayat tiket tidak tersedia atau tiket sudah dihapus.',
                actionLabel: 'Coba Lagi',
                onPressed: () => context
                    .read<TicketTrackingBloc>()
                    .add(LoadTicketTrackingRequested(ticketId)),
              ),
            TicketTrackingStatus.unauthorized => _TrackingMessageState(
                isDark: isDark,
                icon: Icons.lock_outline_rounded,
                title: 'Akses ditolak',
                message: 'Anda tidak memiliki akses ke perjalanan tiket ini.',
                actionLabel: 'Kembali',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            TicketTrackingStatus.failure => _TrackingMessageState(
                isDark: isDark,
                icon: Icons.error_outline_rounded,
                title: 'Gagal memuat tracking',
                message: state.errorMessage ??
                    'Terjadi kesalahan saat memuat perjalanan tiket.',
                actionLabel: 'Coba Lagi',
                onPressed: () => context
                    .read<TicketTrackingBloc>()
                    .add(LoadTicketTrackingRequested(ticketId)),
              ),
            TicketTrackingStatus.loaded => _TrackingContent(
                isDark: isDark,
                ticket: state.ticket!,
                viewData: state.viewData!,
              ),
          };
        },
      ),
    );
  }
}

class _TrackingContent extends StatelessWidget {
  final bool isDark;
  final TicketEntity ticket;
  final TicketTrackingViewData viewData;

  const _TrackingContent({
    required this.isDark,
    required this.ticket,
    required this.viewData,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TicketTrackingSummaryCard(
          isDark: isDark,
          ticket: ticket,
        ),
        const SizedBox(height: 24),
        const Text(
          'Progres Tiket',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        TicketLifecycleProgress(
          isDark: isDark,
          milestones: viewData.lifecycleMilestones,
        ),
        const SizedBox(height: 32),
        const Text(
          'Riwayat Aktivitas',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        TicketActivityTimeline(
          isDark: isDark,
          items: viewData.activityEvents,
        ),
      ],
    );
  }
}

class _TrackingMessageState extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  const _TrackingMessageState({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            AppButton.primary(
              label: actionLabel,
              onPressed: onPressed,
            ),
          ],
        ),
      ),
    );
  }
}
