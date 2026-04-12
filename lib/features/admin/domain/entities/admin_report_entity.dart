import 'package:equatable/equatable.dart';

class AdminReport extends Equatable {
  final List<TeamPerformance> teamPerformance;
  final List<CategoryDistribution> categoryDistribution;

  const AdminReport({
    required this.teamPerformance,
    required this.categoryDistribution,
  });

  @override
  List<Object?> get props => [teamPerformance, categoryDistribution];
}

class TeamPerformance extends Equatable {
  final String technicianId;
  final String fullName;
  final int resolvedCount;

  const TeamPerformance({
    required this.technicianId,
    required this.fullName,
    required this.resolvedCount,
  });

  @override
  List<Object?> get props => [technicianId, fullName, resolvedCount];
}

class CategoryDistribution extends Equatable {
  final String category;
  final int count;

  const CategoryDistribution({
    required this.category,
    required this.count,
  });

  @override
  List<Object?> get props => [category, count];
}
