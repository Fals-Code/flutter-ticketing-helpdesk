import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/features/ticket/presentation/bloc/detail/ticket_detail_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/detail/ticket_detail_event.dart'
    as detail_event;
import 'package:uts/features/ticket/presentation/bloc/detail/ticket_detail_state.dart'
    as detail_state;
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_event.dart'
    as stats_event;
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_state.dart'
    as stats_state;
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/domain/entities/comment_entity.dart';
import 'package:uts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/shared/widgets/ticket_timeline_widget.dart';
import 'package:uts/shared/widgets/app_button.dart';
import 'package:uts/features/ticket/presentation/widgets/rating_dialog.dart';

class TicketDetailPage extends StatefulWidget {
  final String ticketId;

  const TicketDetailPage({super.key, required this.ticketId});

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isDescExpanded = false;
  int _charCount = 0;

  late TicketDetailBloc _ticketDetailBloc;

  @override
  void initState() {
    super.initState();
    _commentController.addListener(() {
      setState(() => _charCount = _commentController.text.length);
    });

    _ticketDetailBloc = context.read<TicketDetailBloc>();

    _ticketDetailBloc.add(detail_event.FetchTicketDetailRequested(widget.ticketId));
    _ticketDetailBloc.add(detail_event.StartTicketCommentsSubscription(widget.ticketId));
    _ticketDetailBloc.add(detail_event.FetchTicketActivitiesRequested(widget.ticketId));

    final authState = context.read<AuthBloc>().state;
    if (authState.status == AuthStatus.authenticated &&
        (authState.user.role == UserRole.admin || authState.user.role == UserRole.technician)) {
      context.read<TicketStatsBloc>().add(stats_event.FetchStaffUsersRequested());
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();

    _ticketDetailBloc.add(detail_event.ResetTicketDetailState());

    super.dispose();
  }

  bool _isChatDisabled(TicketEntity ticket) =>
      ticket.status == TicketStatus.resolved || ticket.status == TicketStatus.closed;

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => _ToastWidget(message: message, isError: isError),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () => entry.remove());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<TicketDetailBloc, detail_state.TicketDetailState>(
      listener: (context, state) {
        if (state.successMessage == 'Tanggapan berhasil dikirim') {
          _commentController.clear();
        }
        if (state.errorMessage != null) {
          _showToast(state.errorMessage!, isError: true);
        }
        if (state.successMessage != null && state.successMessage != 'Tanggapan berhasil dikirim') {
          _showToast(state.successMessage!);
        }
      },
      builder: (context, state) {
        final ticket = state.ticket;
        final authState = context.read<AuthBloc>().state;
        final currentUserRole = authState.user.role;
        final isUser = currentUserRole == UserRole.user;
        final isStaff = currentUserRole == UserRole.admin || currentUserRole == UserRole.technician;

        return Scaffold(
          backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          body: state.isLoading && ticket == null
              ? _buildSkeleton(isDark)
              : ticket == null
                  ? _buildNotFound(context, isDark)
                  : Column(
                      children: [
                        Expanded(
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              // APP BAR
                              SliverAppBar(
                                title: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '#${ticket.id.substring(0, 8).toUpperCase()}',
                                      style: GoogleFonts.firaCode(fontSize: 15, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: ticket.status.color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        ticket.status.label,
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ticket.status.color),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                                surfaceTintColor: Colors.transparent,
                                leading: IconButton(
                                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                                  onPressed: () => context.pop(),
                                ),
                                actions: [
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert_rounded),
                                    onSelected: (val) {
                                      if (val == 'copy') {
                                        Clipboard.setData(ClipboardData(text: ticket.id));
                                        _showToast('ID tiket disalin');
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'copy', child: Row(children: [Icon(Icons.copy_rounded, size: 18), SizedBox(width: 12), Text('Salin ID')])),
                                    ],
                                  ),
                                ],
                                pinned: true,
                                floating: false,
                              ),

                              // CONTENT
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // HEADER
                                      _buildHeader(ticket, isDark),
                                      const SizedBox(height: 24),

                                      // DESCRIPTION
                                      _buildDescription(ticket, isDark),
                                      const SizedBox(height: 24),

                                      // IMAGES
                                      if (ticket.imageUrls.isNotEmpty) ...[
                                        _buildImages(context, ticket, isDark),
                                        const SizedBox(height: 24),
                                      ],

                                      // STAFF ACTIONS
                                      _buildStaffActions(context, state, isDark),

                                      // TIMELINE
                                      _buildSectionLabel('RIWAYAT', isDark),
                                      const SizedBox(height: 14),
                                      TicketTimelineWidget(activities: state.history, isDark: isDark),
                                      const SizedBox(height: 24),

                                      // RATING
                                      if (isUser && _isChatDisabled(ticket))
                                        _buildUserRatingSection(context, state, ticket, isDark),
                                      if (isStaff && _isChatDisabled(ticket))
                                        _buildStaffRatingView(ticket, isDark),

                                      // CHAT
                                      if (!_isChatDisabled(ticket)) ...[
                                        _buildSectionLabel('DISKUSI LANGSUNG', isDark, showLiveDot: true),
                                        const SizedBox(height: 14),
                                        _buildCommentsList(context, state.comments, isDark),
                                      ],

                                      const SizedBox(height: 100),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // BOTTOM BAR
                        if (!_isChatDisabled(ticket))
                          _buildCommentInput(context, state, isDark),
                      ],
                    ),
        );
      },
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(TicketEntity ticket, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date
        Text(
          'Dibuat ${DateFormat('dd MMMM yyyy, HH:mm', 'id').format(ticket.createdAt)}',
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45),
        ),
        const SizedBox(height: 12),
        // Title
        Text(
          ticket.title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.3),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 14),
        // Category + Priority
        Row(
          children: [
            Icon(Icons.category_outlined, size: 14, color: isDark ? Colors.white54 : Colors.black54),
            const SizedBox(width: 6),
            Text(ticket.category, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 14),
        // Assignee
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: ticket.assignedTo != null ? AppColors.primary.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: ticket.assignedTo != null
                    ? Text(
                        (ticket.assignedToName ?? 'T')[0].toUpperCase(),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                      )
                    : const Icon(Icons.person_off_outlined, size: 14, color: Colors.orange),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ditugaskan ke', style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38)),
                Text(
                  ticket.assignedToName ?? 'Belum ditugaskan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ticket.assignedTo != null ? (isDark ? Colors.white : Colors.black87) : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ],
    );
  }

  // ── DESCRIPTION ────────────────────────────────────────────────────────────

  Widget _buildDescription(TicketEntity ticket, bool isDark) {
    final lines = ticket.description.split('\n');
    final isLong = lines.length > 5 || ticket.description.length > 300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('DESKRIPSI', isDark),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ticket.description,
                style: TextStyle(fontSize: 14, height: 1.6, color: isDark ? Colors.white70 : Colors.black87),
                maxLines: _isDescExpanded || !isLong ? null : 5,
                overflow: _isDescExpanded || !isLong ? null : TextOverflow.ellipsis,
              ),
              if (isLong) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => setState(() => _isDescExpanded = !_isDescExpanded),
                  child: Text(
                    _isDescExpanded ? 'Tutup' : 'Lihat selengkapnya',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── IMAGES ─────────────────────────────────────────────────────────────────

  Widget _buildImages(BuildContext context, TicketEntity ticket, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('LAMPIRAN', isDark),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: ticket.imageUrls.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _showImageGallery(context, ticket.imageUrls, index),
              child: Hero(
                tag: ticket.imageUrls[index],
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    image: DecorationImage(image: NetworkImage(ticket.imageUrls[index]), fit: BoxFit.cover),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showImageGallery(BuildContext context, List<String> urls, int initial) {
    Navigator.push(context, PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, __, ___) => _ImageGalleryOverlay(urls: urls, initialIndex: initial),
    ));
  }

  // ── STAFF ACTIONS ──────────────────────────────────────────────────────────

  Widget _buildStaffActions(BuildContext context, detail_state.TicketDetailState state, bool isDark) {
    final ticket = state.ticket!;
    final authState = context.read<AuthBloc>().state;
    if (authState.user.isEmpty) return const SizedBox.shrink();

    final isAdmin = authState.user.role == UserRole.admin;
    final isTechnician = authState.user.role == UserRole.technician;
    final isAssignedToMe = ticket.assignedTo == authState.user.id;

    if (isTechnician && !isAssignedToMe) return const SizedBox.shrink();
    if (!isAdmin && !isTechnician) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(isAdmin ? Icons.admin_panel_settings_rounded : Icons.engineering_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(
                  isAdmin ? 'KONTROL ADMINISTRATOR' : 'TUGAS & PENANGANAN',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.8),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step tracker
                _buildStepTracker(ticket, isDark),
                const SizedBox(height: 16),

                // Action button
                if (ticket.status == TicketStatus.open)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.read<TicketDetailBloc>().add(
                            detail_event.UpdateTicketStatusRequested(ticketId: ticket.id, status: TicketStatus.inProgress),
                          ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: const Text('Mulai Kerjakan', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                if (ticket.status == TicketStatus.inProgress)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.read<TicketDetailBloc>().add(
                            detail_event.UpdateTicketStatusRequested(ticketId: ticket.id, status: TicketStatus.resolved),
                          ),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                      label: const Text('Tandai Selesai', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                if (ticket.status == TicketStatus.resolved || ticket.status == TicketStatus.closed)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_rounded, color: AppColors.success, size: 18),
                        SizedBox(width: 8),
                        Text('Penanganan Selesai', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),

                // Admin delegation
                if (isAdmin) ...[
                  const SizedBox(height: 20),
                  Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  const SizedBox(height: 16),
                  const Text('Delegasikan Ke Teknisi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showStaffBottomSheet(context, ticket),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          if (ticket.assignedTo != null) ...[
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: Center(child: Text((ticket.assignedToName ?? 'T')[0].toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary))),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(child: Text(ticket.assignedToName ?? 'Pilih Teknisi...', style: TextStyle(fontSize: 14, color: ticket.assignedTo != null ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white54 : Colors.black45)))),
                          Icon(Icons.unfold_more_rounded, size: 20, color: isDark ? Colors.white54 : Colors.black45),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTracker(TicketEntity ticket, bool isDark) {
    const steps = ['Terbuka', 'Diproses', 'Selesai'];
    int activeIndex = 0;
    if (ticket.status == TicketStatus.inProgress) activeIndex = 1;
    if (ticket.status == TicketStatus.resolved || ticket.status == TicketStatus.closed) activeIndex = 2;

    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index <= activeIndex;
        final isLast = index == steps.length - 1;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isActive
                      ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                      : Text('${index + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.black26)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(steps[index], style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? AppColors.primary : (isDark ? Colors.white38 : Colors.black38))),
              ),
              if (!isLast)
                Container(width: 16, height: 1, color: isActive ? AppColors.primary.withValues(alpha: 0.5) : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))),
            ],
          ),
        );
      }),
    );
  }

  void _showStaffBottomSheet(BuildContext context, TicketEntity ticket) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      builder: (ctx) {
        return BlocBuilder<TicketStatsBloc, stats_state.TicketStatsState>(
          builder: (context, statsState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  const Text('Pilih Teknisi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ...statsState.staffUsers.map((user) {
                    final isSelected = user.id == ticket.assignedTo;
                    return ListTile(
                      leading: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Center(child: Text((user.fullName ?? user.email)[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
                      ),
                      title: Text(user.fullName ?? user.email, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(user.role.name, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45)),
                      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        if (user.id != ticket.assignedTo) {
                          context.read<TicketDetailBloc>().add(detail_event.AssignTicketRequested(ticketId: ticket.id, technicianId: user.id));
                        }
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── RATING ─────────────────────────────────────────────────────────────────

  Widget _buildUserRatingSection(BuildContext context, detail_state.TicketDetailState state, TicketEntity ticket, bool isDark) {
    final hasRated = ticket.rating != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('PENILAIAN LAYANAN', isDark),
        const SizedBox(height: 14),
        if (hasRated)
          _buildRatingDisplay(ticket, isDark, label: 'Terima kasih atas penilaianmu!')
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Column(
              children: [
                const Icon(Icons.star_outline_rounded, size: 48, color: Colors.amber),
                const SizedBox(height: 12),
                const Text('Tiket telah diselesaikan!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Berikan penilaian untuk membantu kami meningkatkan layanan.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => RatingDialog.show(context, onSubmitted: (rating, feedback) {
                      context.read<TicketDetailBloc>().add(detail_event.SubmitRatingRequested(ticketId: widget.ticketId, rating: rating, feedback: feedback));
                    }),
                    icon: const Icon(Icons.star_rounded),
                    label: const Text('Beri Penilaian Layanan', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStaffRatingView(TicketEntity ticket, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('PENILAIAN DARI PENGGUNA', isDark),
        const SizedBox(height: 14),
        if (ticket.rating != null)
          _buildRatingDisplay(ticket, isDark, label: 'Penilaian Diberikan')
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Row(
              children: [
                Icon(Icons.hourglass_empty_rounded, color: isDark ? Colors.white38 : Colors.black26, size: 18),
                const SizedBox(width: 12),
                Text('Pengguna belum memberikan penilaian.', style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black45)),
              ],
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRatingDisplay(TicketEntity ticket, bool isDark, {String? label}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Text(label ?? 'Penilaian', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (index) {
              return Icon(index < (ticket.rating ?? 0) ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 28);
            }),
          ),
          if (ticket.ratingFeedback != null && ticket.ratingFeedback!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('"${ticket.ratingFeedback}"', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, height: 1.4)),
          ],
        ],
      ),
    );
  }

  // ── CHAT ───────────────────────────────────────────────────────────────────

  Widget _buildCommentsList(BuildContext context, List<CommentEntity> comments, bool isDark) {
    if (comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.chat_bubble_outline_rounded, size: 32, color: isDark ? Colors.white24 : Colors.black12),
              const SizedBox(height: 12),
              Text('Belum ada pesan.', style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black45)),
              const SizedBox(height: 4),
              Text('Mulai diskusi di sini.', style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black26)),
            ],
          ),
        ),
      );
    }

    final authState = context.read<AuthBloc>().state;
    final myId = authState.user.id;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        final isMe = comment.userId == myId;
        final isStaffComment = comment.userRole == 'technician' || comment.userRole == 'admin';

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMe) ...[
                _buildAvatar(comment, isStaffComment),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4, left: 4),
                        child: Text(
                          comment.userName,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isStaffComment ? AppColors.primary : (isDark ? Colors.white54 : Colors.black45)),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : isStaffComment
                                ? AppColors.primary.withValues(alpha: 0.05)
                                : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                        borderRadius: BorderRadius.circular(16).copyWith(
                          bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                          bottomLeft: !isMe ? const Radius.circular(4) : const Radius.circular(16),
                        ),
                        border: isStaffComment && !isMe
                            ? Border(left: BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 3))
                            : null,
                      ),
                      child: Text(
                        comment.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: isMe ? AppColors.primary : (isDark ? Colors.white : Colors.black87),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(DateFormat('HH:mm').format(comment.createdAt), style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black26)),
                    ),
                  ],
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 10),
                _buildAvatar(comment, isStaffComment),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(CommentEntity comment, bool isStaff) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isStaff ? AppColors.primary.withValues(alpha: 0.1) : (Colors.grey.withValues(alpha: 0.1)),
        shape: BoxShape.circle,
        border: Border.all(color: isStaff ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent, width: 1.5),
      ),
      child: Center(
        child: Text(
          comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : '?',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isStaff ? AppColors.primary : Colors.grey),
        ),
      ),
    );
  }

  // ── CHAT INPUT ─────────────────────────────────────────────────────────────

  Widget _buildCommentInput(BuildContext context, detail_state.TicketDetailState state, bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_charCount > 400)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('$_charCount / 500', style: TextStyle(fontSize: 11, color: _charCount > 490 ? AppColors.danger : (isDark ? Colors.white54 : Colors.black45))),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  maxLength: 500,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'Tulis pesan...',
                    hintStyle: TextStyle(fontSize: 14, color: isDark ? Colors.white38 : Colors.black38),
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    fillColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                ),
              ),
              const SizedBox(width: 10),
              _SendButton(
                enabled: _charCount > 0,
                onPressed: () {
                  if (_commentController.text.trim().isEmpty) return;
                  context.read<TicketDetailBloc>().add(
                        detail_event.AddCommentRequested(ticketId: widget.ticketId, message: _commentController.text),
                      );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label, bool isDark, {bool showLiveDot = false}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white54 : Colors.black45, letterSpacing: 1),
        ),
        if (showLiveDot) ...[
          const SizedBox(width: 8),
          _PulsingDot(),
        ],
      ],
    );
  }

  Widget _buildNotFound(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: isDark ? Colors.white12 : Colors.black12),
            const SizedBox(height: 24),
            const Text('Tiket Tidak Ditemukan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Tiket mungkin telah dihapus dari sistem.', textAlign: TextAlign.center, style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
            const SizedBox(height: 32),
            AppButton.primary(label: 'Kembali', onPressed: () => context.pop()),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(bool isDark) {
    final baseColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: baseColor, shape: BoxShape.circle)), const Spacer()]),
            const SizedBox(height: 24),
            Container(width: 120, height: 12, color: baseColor),
            const SizedBox(height: 16),
            Container(width: double.infinity, height: 20, color: baseColor),
            const SizedBox(height: 8),
            Container(width: 200, height: 20, color: baseColor),
            const SizedBox(height: 20),
            Row(children: [Container(width: 80, height: 16, color: baseColor), const SizedBox(width: 12), Container(width: 60, height: 16, color: baseColor)]),
            const SizedBox(height: 20),
            Row(children: [Container(width: 28, height: 28, decoration: BoxDecoration(color: baseColor, shape: BoxShape.circle)), const SizedBox(width: 12), Container(width: 140, height: 14, color: baseColor)]),
            const SizedBox(height: 32),
            Container(width: double.infinity, height: 100, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(12))),
            const SizedBox(height: 24),
            Container(width: 80, height: 12, color: baseColor),
            const SizedBox(height: 16),
            ...List.generate(3, (_) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: baseColor, shape: BoxShape.circle)), const SizedBox(width: 14), Expanded(child: Container(height: 14, color: baseColor))]))),
          ],
        ),
      ),
    );
  }
}

// ── PRIVATE REUSABLE WIDGETS ─────────────────────────────────────────────────

class _SendButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onPressed;
  const _SendButton({required this.enabled, required this.onPressed});

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.9).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onPressed(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: widget.enabled ? AppColors.primary : (Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.send_rounded, size: 20, color: widget.enabled ? Colors.white : Colors.grey),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl),
      child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
    );
  }
}

class _ImageGalleryOverlay extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  const _ImageGalleryOverlay({required this.urls, required this.initialIndex});

  @override
  State<_ImageGalleryOverlay> createState() => _ImageGalleryOverlayState();
}

class _ImageGalleryOverlayState extends State<_ImageGalleryOverlay> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text('${_currentIndex + 1} / ${widget.urls.length}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Hero(
                tag: widget.urls[index],
                child: Image.network(
                  widget.urls[index],
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, p) {
                    if (p == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  const _ToastWidget({required this.message, this.isError = false});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _slide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = Tween<double>(begin: 0, end: 1).animate(_ctrl);
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) _ctrl.reverse();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 24,
      right: 16,
      left: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.isError ? AppColors.danger : AppColors.success,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Icon(widget.isError ? Icons.error_rounded : Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(widget.message, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
