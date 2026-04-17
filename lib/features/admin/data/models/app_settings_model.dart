import '../../domain/entities/app_settings_entity.dart';

class AppSettingsModel extends AppSettings {
  const AppSettingsModel({
    required super.maintenanceMode,
    required super.slaHours,
    required super.autoAssign,
    required super.defaultPriority,
  });

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsModel(
      maintenanceMode: json['maintenance_mode'] ?? false,
      slaHours: json['sla_hours'] ?? 4,
      autoAssign: json['auto_assign'] ?? true,
      defaultPriority: json['default_priority'] ?? 'Medium',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maintenance_mode': maintenanceMode,
      'sla_hours': slaHours,
      'auto_assign': autoAssign,
      'default_priority': defaultPriority,
    };
  }

  factory AppSettingsModel.fromEntity(AppSettings entity) {
    return AppSettingsModel(
      maintenanceMode: entity.maintenanceMode,
      slaHours: entity.slaHours,
      autoAssign: entity.autoAssign,
      defaultPriority: entity.defaultPriority,
    );
  }

  AppSettings toEntity() {
    return AppSettings(
      maintenanceMode: maintenanceMode,
      slaHours: slaHours,
      autoAssign: autoAssign,
      defaultPriority: defaultPriority,
    );
  }
}
