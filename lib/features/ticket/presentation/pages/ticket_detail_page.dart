import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/app_dimensions.dart';
import 'package:uts/shared/widgets/loading_widget.dart';
import 'package:uts/shared/widgets/app_text_field.dart';
import 'package:uts/features/ticket/presentation/bloc/ticket_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/ticket_event.dart';
import 'package:uts/features/ticket/presentation/bloc/ticket_state.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/domain/entities/comment_entity.dart';
import 'package:uts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:uts/core/constants/enums.dart';

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
            SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
          );
        }
        if (state.successMessage != null && state.successMessage != 'Tanggapan berhasil dikirim') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage!), backgroundColor: Colors.green),
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
                  ? const Center(child: Text('Tiket tidak ditemukan'))
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
                                  Text('Riwayat Aktivitas',
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

  Widget _buildStaffActions(BuildContext context, TicketState state) {
    final ticket = state.selectedTicket!;
    final authState = context.read<AuthBloc>().state;
    final isStaff = authState.status == AuthStatus.authenticated && 
        (authState.user.role == UserRole.admin || authState.user.role == UserRole.technician);

    if (!isStaff) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceXXL),
      padding: const EdgeInsets.all(AppDimensions.spaceLG),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Panel Administrasi',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceLG),
          Text('Update Status', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TicketStatus.values.map((status) {
                final isSelected = ticket.status == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(status.label, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val && !isSelected) {
                        context.read<TicketBloc>().add(
                              UpdateTicketStatusRequested(ticketId: ticket.id, status: status),
                            );
                      }
                    },
                    selectedColor: status.color.withValues(alpha: 0.2),
                    checkmarkColor: status.color,
                    labelStyle: TextStyle(
                      color: isSelected ? status.color : null,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceLG),
          Text('Tugaskan Ke', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: ticket.assignedTo,
                hint: const Text('Pilih Petugas', style: TextStyle(fontSize: 14)),
                isExpanded: true,
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
            ),
          ),
          if (ticket.assignedToName != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_pin_outlined, size: 14, color: AppColors.textSecondaryLight),
                const SizedBox(width: 4),
                Text(
                  'Ditugaskan kepada: ${ticket.assignedToName}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TicketEntity ticket) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Badge(
              label: ticket.status.label,
              color: ticket.status.color,
            ),
            const SizedBox(width: 8),
            _Badge(
              label: ticket.priority.label,
              color: ticket.priority.color,
            ),
            const Spacer(),
            Text(
              '${ticket.createdAt.day}/${ticket.createdAt.month}/${ticket.createdAt.year}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          ticket.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.category_outlined, size: 16, color: AppColors.textSecondaryLight),
            const SizedBox(width: 4),
            Text(
              ticket.category,
              style: Theme.of(context).textTheme.bodySmall,
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
        Text('Deskripsi Masalah', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.spaceLG),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Text(
            ticket.description,
            style: Theme.of(context).textTheme.bodyMedium,
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

  Widget _buildCommentsList(
      BuildContext context, List<CommentEntity> comments, bool isDark) {
    if (comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceXXL),
          child: Text(
            'Belum ada tanggapan.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        final isTechnician = comment.userRole == 'technician' || comment.userRole == 'admin';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: isTechnician ? AppColors.secondary : AppColors.primary,
                child: Text(
                  comment.userName[0].toUpperCase(),
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        if (isTechnician) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Staff',
                              style: TextStyle(fontSize: 8, color: AppColors.secondaryDark),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          '${comment.createdAt.hour}:${comment.createdAt.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : AppColors.cardLight,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                      child: Text(
                        comment.message,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentInput(BuildContext context, TicketState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.spaceLG,
        AppDimensions.spaceMD,
        AppDimensions.spaceLG,
        MediaQuery.of(context).padding.bottom + AppDimensions.spaceMD,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        border: Border(
            top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppTextField(
              label: 'Kirim Pesan',
              hint: 'Tulis tanggapan...',
              controller: _commentController,
              prefixIcon: Icons.chat_bubble_outline,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              if (_commentController.text.trim().isEmpty) return;
              context.read<TicketBloc>().add(AddCommentRequested(
                    ticketId: widget.ticketId,
                    message: _commentController.text,
                  ));
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
