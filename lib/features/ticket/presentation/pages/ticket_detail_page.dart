import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/app_dimensions.dart';
import 'package:uts/shared/widgets/loading_widget.dart';
import 'package:uts/features/ticket/presentation/bloc/ticket_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/ticket_event.dart';
import 'package:uts/features/ticket/presentation/bloc/ticket_state.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/domain/entities/comment_entity.dart';
import 'package:uts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/shared/widgets/ticket_timeline_widget.dart';

class TicketDetailPage extends StatefulWidget {
  final String ticketId;

  const TicketDetailPage({super.key, required this.ticketId});

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  final _commentController = TextEditingController();

  @override
  void initState() {
    context.read<TicketBloc>().add(FetchTicketDetailRequested(widget.ticketId));
    
    // Fetch staff users if role is technician/admin
    final authState = context.read<AuthBloc>().state;
    if (authState.status == AuthStatus.authenticated && 
        (authState.user.role == UserRole.admin || authState.user.role == UserRole.technician)) {
      context.read<TicketBloc>().add(const FetchStaffUsersRequested());
    }
    
    // Fetch activities for timeline
    context.read<TicketBloc>().add(FetchTicketActivitiesRequested(ticketId: widget.ticketId));
    super.initState();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<TicketBloc, TicketState>(
      listener: (context, state) {
        if (state.successMessage == 'Tanggapan berhasil dikirim') {
          _commentController.clear();
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!), backgroundColor: AppColors.priorityHigh),
          );
        }
        if (state.successMessage != null && state.successMessage != 'Tanggapan berhasil dikirim') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage!), backgroundColor: AppColors.statusResolved),
          );
        }
      },
      builder: (context, state) {
        final ticket = state.selectedTicket;

        return Scaffold(
          appBar: AppBar(
            title: Text(ticket != null
                ? '#${ticket.id.substring(0, 8).toUpperCase()}'
                : 'Detail Tiket'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => context.pop(),
            ),
          ),
          body: state.isLoading && ticket == null
              ? const Center(child: LoadingWidget())
              : ticket == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimensions.spaceXXL),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 80,
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Tiket Tidak Ditemukan',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Maaf, tiket yang Anda cari tidak tersedia atau mungkin telah dihapus dari sistem.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: 200,
                              child: ElevatedButton(
                                onPressed: () => context.pop(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.arrow_back, size: 20),
                                    SizedBox(width: 8),
                                    Text('Kembali', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.all(AppDimensions.spaceLG),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeader(context, ticket),
                                const SizedBox(height: AppDimensions.spaceLG),
                                _buildAssignedInfo(context, ticket, isDark),
                                const SizedBox(height: AppDimensions.spaceXXL),
                                
                                // Staff Action Panel
                                _buildStaffActions(context, state),
                                
                                _buildDescription(context, ticket, isDark),
                                if (ticket.imageUrls.isNotEmpty) ...[
                                  const SizedBox(height: AppDimensions.spaceXXL),
                                  _buildImages(context, ticket),
                                ],
                                const SizedBox(height: AppDimensions.spaceXXL),
                                const Divider(),
                                const SizedBox(height: AppDimensions.spaceLG),
                                Text('Timeline Status',
                                    style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: AppDimensions.spaceLG),
                                TicketTimelineWidget(activities: state.history, isDark: isDark),
                                
                                const SizedBox(height: AppDimensions.spaceXXL),
                                const Divider(),
                                const SizedBox(height: AppDimensions.spaceLG),
                                Text('Diskusi & Tanggapan',
                                    style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: AppDimensions.spaceLG),
                                _buildCommentsList(context, state.comments, isDark),
                                const SizedBox(height: 100), // Space for input field
                              ],
                            ),
                          ),
                        ),
                        _buildCommentInput(context, state),
                      ],
                    ),
        );
      },
    );
  }

  Widget _buildAssignedInfo(BuildContext context, TicketEntity ticket, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.engineering_outlined,
            size: 16,
            color: ticket.assignedTo == null ? Colors.orange : AppColors.primary,
          ),
          const SizedBox(width: 8),
          const Text(
            'Petugas: ',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          Text(
            ticket.assignedToName ?? 'Belum ditugaskan',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ticket.assignedTo == null ? Colors.orange : (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffActions(BuildContext context, TicketState state) {
    final ticket = state.selectedTicket!;
    final authState = context.read<AuthBloc>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isStaff = authState.status == AuthStatus.authenticated && 
        (authState.user.role == UserRole.admin || authState.user.role == UserRole.technician);

    if (!isStaff) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'STAFF ACTIONS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Update Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: TicketStatus.values.map((status) {
              final isSelected = ticket.status == status;
              return ChoiceChip(
                label: Text(status.label, style: const TextStyle(fontSize: 12)),
                selected: isSelected,
                onSelected: (val) {
                  if (val && !isSelected) {
                    context.read<TicketBloc>().add(
                          UpdateTicketStatusRequested(ticketId: ticket.id, status: status),
                        );
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('Tugaskan Ke', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: ticket.assignedTo,
            isExpanded: true,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: state.staffUsers.map((user) {
              return DropdownMenuItem<String>(
                value: user.id,
                child: Text(user.fullName ?? user.email, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null && val != ticket.assignedTo) {
                context.read<TicketBloc>().add(
                      AssignTicketRequested(ticketId: ticket.id, technicianId: val),
                    );
              }
            },
          ),
        ],
      ),
    );
  }


  Widget _buildHeader(BuildContext context, TicketEntity ticket) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ticket.status.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                ticket.status.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: ticket.status.color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '#${ticket.id.substring(0, 8).toUpperCase()}',
              style: GoogleFonts.firaCode(
                fontSize: 11,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const Spacer(),
            Text(
              DateFormat('dd MMM yyyy').format(ticket.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          ticket.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.category_outlined, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              ticket.category,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildDescription(BuildContext context, TicketEntity ticket, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DESKRIPSI MASALAH',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Text(
            ticket.description,
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
        ),
      ],
    );
  }


  Widget _buildImages(BuildContext context, TicketEntity ticket) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lampiran Gambar', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: ticket.imageUrls.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 12),
                width: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  image: DecorationImage(
                    image: NetworkImage(ticket.imageUrls[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsList(BuildContext context, List<CommentEntity> comments, bool isDark) {
    if (comments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Text(
            'Belum ada tanggapan.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
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
        final isStaff = comment.userRole == 'technician' || comment.userRole == 'admin';

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMe) _buildCommentAvatar(comment, isStaff),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isMe) ...[
                      Text(
                        comment.userName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isStaff ? AppColors.primary : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe
                            ? AppColors.primary
                            : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                        borderRadius: BorderRadius.circular(12).copyWith(
                          topRight: isMe ? const Radius.circular(0) : const Radius.circular(12),
                          topLeft: !isMe ? const Radius.circular(0) : const Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        comment.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('HH:mm').format(comment.createdAt),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (isMe) _buildCommentAvatar(comment, isStaff),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentAvatar(CommentEntity comment, bool isStaff) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isStaff ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: isStaff ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
        ),
      ),
      child: Center(
        child: Text(
          comment.userName[0].toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isStaff ? AppColors.primary : Colors.grey,
          ),
        ),
      ),
    );
  }


  Widget _buildCommentInput(BuildContext context, TicketState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Tulis tanggapan...',
                hintStyle: const TextStyle(fontSize: 14),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                fillColor: isDark ? const Color(0xFF232329) : const Color(0xFFF1F1F4),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontSize: 14),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filled(
            onPressed: () {
              if (_commentController.text.trim().isEmpty) return;
              context.read<TicketBloc>().add(AddCommentRequested(
                    ticketId: widget.ticketId,
                    message: _commentController.text,
                  ));
            },
            icon: const Icon(Icons.send_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

}


