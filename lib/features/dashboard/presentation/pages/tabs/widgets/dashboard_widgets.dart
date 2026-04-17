import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uts/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:uts/features/auth/presentation/bloc/auth_state.dart';

class GreetingBanner extends StatelessWidget {
  final bool isDark;

  const GreetingBanner({super.key, required this.isDark});

  Map<String, dynamic> _getGreetingConfig() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return {'text': 'Selamat Pagi', 'icon': Icons.wb_sunny_rounded, 'color': Colors.orangeAccent};
    } else if (hour >= 11 && hour < 15) {
      return {'text': 'Selamat Siang', 'icon': Icons.wb_sunny_rounded, 'color': Colors.orange};
    } else if (hour >= 15 && hour < 18) {
      return {'text': 'Selamat Sore', 'icon': Icons.wb_twilight_rounded, 'color': Colors.deepOrangeAccent};
    } else {
      return {'text': 'Selamat Malam', 'icon': Icons.bedtime_rounded, 'color': Colors.indigoAccent};
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _getGreetingConfig();
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final name = state.user.fullName ?? 'Pengguna';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  config['icon'] as IconData,
                  color: config['color'] as Color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '${config['text']}, $name!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "Berikut ringkasan bantuan Anda hari ini",
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        );
      },
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool isDark;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RecentTicketCard extends StatelessWidget {
  final TicketEntity ticket;
  final bool isDark;

  const RecentTicketCard({super.key, required this.ticket, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.ticketDetail.replaceAll(':id', ticket.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: ticket.status.color,
                    shape: BoxShape.circle,
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
                  DateFormat('dd MMM').format(ticket.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              ticket.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                BadgeWidget(label: ticket.category, color: AppColors.primary.withValues(alpha: 0.1), textColor: AppColors.primary),

              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BadgeWidget extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const BadgeWidget({super.key, required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }
}
