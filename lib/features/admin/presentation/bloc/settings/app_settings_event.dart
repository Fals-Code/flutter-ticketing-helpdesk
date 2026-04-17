import 'package:equatable/equatable.dart';
import '../../../domain/entities/app_settings_entity.dart';

abstract class AppSettingsEvent extends Equatable {
  const AppSettingsEvent();
  @override
  List<Object?> get props => [];
}

class FetchAppSettingsRequested extends AppSettingsEvent {}

class UpdateAppSettingsRequested extends AppSettingsEvent {
  final AppSettings settings;
  const UpdateAppSettingsRequested(this.settings);
  @override
  List<Object?> get props => [settings];
}
