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
  sessionExpired,
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

