import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uts/core/services/connectivity_service.dart';
import 'package:uts/shared/theme/theme_cubit.dart';
import 'package:uts/features/auth/di/auth_di.dart';
import 'package:uts/features/ticket/di/ticket_di.dart';
import 'package:uts/features/notification/di/notification_di.dart';
import 'package:uts/features/admin/di/admin_di.dart';

/// Global service locator instance.
final GetIt sl = GetIt.instance;

/// Inisialisasi semua dependensi di sini.
/// Dipanggil sekali di `main()` sebelum `runApp()`.
Future<void> initDependencies() async {
  // ── External ──────────────────────────────────────────────────────────────
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // ── Shared / Core ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<ThemeCubit>(
    () => ThemeCubit(preferences: sl<SharedPreferences>()),
  );

  sl.registerSingleton<ConnectivityService>(ConnectivityService());

  // ── Features ──────────────────────────────────────────────────────────────
  await initAuthDependencies(sl);
  await initTicketDependencies(sl);
  await initNotificationDependencies(sl);
  await initAdmin(sl);
}
