import 'package:uts/features/auth/domain/entities/user_entity.dart';
import '../../domain/entities/admin_report_entity.dart';

class AdminReportModel {
  final List<TeamPerformanceModel> teamPerformance;
  final List<CategoryDistributionModel> categoryDistribution;

  AdminReportModel({
    required this.teamPerformance,
    required this.categoryDistribution,
  });

  factory AdminReportModel.fromJson(Map<String, dynamic> json) {
    return AdminReportModel(
      teamPerformance: (json['team_performance'] as List)
          .map((e) => TeamPerformanceModel.fromJson(e))
          .toList(),
      categoryDistribution: (json['category_distribution'] as List)
          .map((e) => CategoryDistributionModel.fromJson(e))
          .toList(),
    );
  }
  AdminReport toEntity() {
    return AdminReport(
      teamPerformance: teamPerformance.map((e) => e.toEntity()).toList(),
      categoryDistribution: categoryDistribution.map((e) => e.toEntity()).toList(),
    );
  }
}

class TeamPerformanceModel {
  final String technicianId;
  final String fullName;
  final int resolvedCount;

  TeamPerformanceModel({
    required this.technicianId,
    required this.fullName,
    required this.resolvedCount,
  });

  factory TeamPerformanceModel.fromJson(Map<String, dynamic> json) {
    return TeamPerformanceModel(
      technicianId: json['technician_id'],
      fullName: json['full_name'],
      resolvedCount: json['resolved_count'] ?? 0,
    );
  }
  TeamPerformance toEntity() {
    return TeamPerformance(
      technicianId: technicianId,
      fullName: fullName,
      resolvedCount: resolvedCount,
    );
  }
}

class CategoryDistributionModel {
  final String category;
  final int count;

  CategoryDistributionModel({
    required this.category,
    required this.count,
  });

  factory CategoryDistributionModel.fromJson(Map<String, dynamic> json) {
    return CategoryDistributionModel(
      category: json['category'],
      count: json['count'] ?? 0,
    );
  }

  CategoryDistribution toEntity() {
    return CategoryDistribution(
      category: category,
      count: count,
    );
  }
}
