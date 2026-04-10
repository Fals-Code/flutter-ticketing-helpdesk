import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme/theme_cubit.dart';
import '../../features/auth/di/auth_di.dart';
import '../../features/ticket/di/ticket_di.dart';
import '../../features/notification/di/notification_di.dart';

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

  // ── Features ──────────────────────────────────────────────────────────────
  await initAuthDependencies(sl);
  await initTicketDependencies(sl);
  await initNotificationDependencies(sl);
}
