import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Status autentikasi global.
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
  success,
}

/// Role pengguna dalam sistem.
enum UserRole {
  user,
  technician,
  admin;

  static UserRole fromInt(int role) {
    switch (role) {
      case 1:
        return UserRole.admin;
      case 2:
        return UserRole.technician;
      default:
        return UserRole.user;
    }
  }

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'technician':
      case 'helpdesk':
      case 'agent':
        return UserRole.technician;
      default:
        return UserRole.user;
    }
  }

  String get name => toString().split('.').last;

  int get toInt {
    switch (this) {
      case UserRole.admin:
        return 1;
      case UserRole.technician:
        return 2;
      case UserRole.user:
        return 3;
    }
  }
}

/// Status tiket dalam siklus hidup pengerjaan.
enum TicketStatus {
  open,
  inProgress,
  resolved,
  closed;

  static TicketStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return TicketStatus.open;
      case 'in_progress':
      case 'inprogress':
      case 'in progress':
        return TicketStatus.inProgress;
      case 'resolved':
        return TicketStatus.resolved;
      case 'closed':
        return TicketStatus.closed;
      default:
        return TicketStatus.open;
    }
  }

  String get name => toString().split('.').last;
  
  String get label {
    switch (this) {
      case TicketStatus.open: return 'Terbuka';
      case TicketStatus.inProgress: return 'Diproses';
      case TicketStatus.resolved: return 'Selesai';
      case TicketStatus.closed: return 'Ditutup';
    }
  }

  String get dbValue {
    switch (this) {
      case TicketStatus.inProgress: return 'in_progress';
      default: return name;
    }
  }

  Color get color {
    switch (this) {
      case TicketStatus.open: return AppColors.statusOpen;
      case TicketStatus.inProgress: return AppColors.statusInProgress;
      case TicketStatus.resolved: return AppColors.statusResolved;
      case TicketStatus.closed: return AppColors.textSecondaryDark;
    }
  }
}

/// Prioritas tiket.
enum TicketPriority {
  low,
  medium,
  high,
  urgent;

  static TicketPriority fromString(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return TicketPriority.low;
      case 'medium':
        return TicketPriority.medium;
      case 'high':
        return TicketPriority.high;
      case 'urgent':
        return TicketPriority.urgent;
      default:
        return TicketPriority.medium;
    }
  }

  String get name => toString().split('.').last;

  String get label {
    switch (this) {
      case TicketPriority.low: return 'Rendah';
      case TicketPriority.medium: return 'Sedang';
      case TicketPriority.high: return 'Tinggi';
      case TicketPriority.urgent: return 'Mendesak';
    }
  }

  String get dbValue => name;

  Color get color {
    switch (this) {
      case TicketPriority.low: return AppColors.priorityLow;
      case TicketPriority.medium: return AppColors.priorityMedium;
      case TicketPriority.high: return AppColors.priorityHigh;
      case TicketPriority.urgent: return const Color(0xFFD32F2F); // Dark Red
    }
  }
}
