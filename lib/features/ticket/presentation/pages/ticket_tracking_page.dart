import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/features/ticket/domain/entities/ticket_tracking_item.dart';
import 'package:uts/features/ticket/presentation/bloc/tracking/ticket_tracking_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/tracking/ticket_tracking_event.dart';
import 'package:uts/features/ticket/presentation/bloc/tracking/ticket_tracking_state.dart';
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
            TicketTrackingStatus.empty => _TrackingEmptyState(
                isDark: isDark,
                onRetry: () => context
                    .read<TicketTrackingBloc>()
                    .add(LoadTicketTrackingRequested(ticketId)),
              ),
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
            TicketTrackingStatus.loaded => _TrackingTimelineView(
                isDark: isDark,
                ticketId: state.ticket?.id ?? ticketId,
                title: state.ticket?.title,
                items: state.items,
              ),
          };
        },
      ),
    );
  }
}

class _TrackingTimelineView extends StatelessWidget {
  final bool isDark;
  final String ticketId;
  final String? title;
  final List<TicketTrackingItem> items;

  const _TrackingTimelineView({
    required this.isDark,
    required this.ticketId,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: items.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _TrackingHeader(
            isDark: isDark,
            ticketId: ticketId,
            title: title,
            count: items.length,
          );
        }

        final item = items[index - 1];
        final isLast = index == items.length;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: item.isCurrent
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 72,
                      margin: const EdgeInsets.only(top: 8),
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (item.isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Terbaru',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (item.actorName != null &&
                            item.actorName!.isNotEmpty)
                          _TrackingMetaChip(
                            label: item.actorName!,
                            isDark: isDark,
                            icon: Icons.person_outline_rounded,
                          ),
                        _TrackingMetaChip(
                          label: DateFormat('dd MMM yyyy, HH:mm', 'id')
                              .format(item.occurredAt),
                          isDark: isDark,
                          icon: Icons.schedule_rounded,
                        ),
                        if (item.oldStatus != null)
                          _TrackingMetaChip(
                            label: 'Dari ${item.oldStatus}',
                            isDark: isDark,
                            icon: Icons.arrow_upward_rounded,
                          ),
                        if (item.newStatus != null)
                          _TrackingMetaChip(
                            label: 'Ke ${item.newStatus}',
                            isDark: isDark,
                            icon: Icons.arrow_downward_rounded,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TrackingHeader extends StatelessWidget {
  final bool isDark;
  final String ticketId;
  final String? title;
  final int count;

  const _TrackingHeader({
    required this.isDark,
    required this.ticketId,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '#${ticketId.substring(0, ticketId.length > 8 ? 8 : ticketId.length).toUpperCase()}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white60 : Colors.black45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title ?? 'Perjalanan tiket',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$count aktivitas tercatat pada timeline ini.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingMetaChip extends StatelessWidget {
  final String label;
  final bool isDark;
  final IconData icon;

  const _TrackingMetaChip({
    required this.label,
    required this.isDark,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? Colors.white60 : Colors.black45,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingEmptyState extends StatelessWidget {
  final bool isDark;
  final VoidCallback onRetry;

  const _TrackingEmptyState({
    required this.isDark,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return _TrackingMessageState(
      isDark: isDark,
      icon: Icons.timeline_rounded,
      title: 'Belum ada riwayat',
      message:
          'Tiket ini belum memiliki aktivitas tracking yang dapat ditampilkan.',
      actionLabel: 'Muat Ulang',
      onPressed: onRetry,
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
