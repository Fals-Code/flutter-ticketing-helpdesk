import 'package:equatable/equatable.dart';

class AppSettings extends Equatable {
  final bool maintenanceMode;
  final int slaHours;
  final bool autoAssign;
  final String defaultPriority;

  const AppSettings({
    required this.maintenanceMode,
    required this.slaHours,
    required this.autoAssign,
    required this.defaultPriority,
  });

  const AppSettings.defaultSettings()
      : maintenanceMode = false,
        slaHours = 4,
        autoAssign = true,
        defaultPriority = 'Medium';

  @override
  List<Object?> get props => [maintenanceMode, slaHours, autoAssign, defaultPriority];
}
