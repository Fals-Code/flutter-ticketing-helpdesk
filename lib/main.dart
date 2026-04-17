import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uts/core/constants/app_strings.dart';
import 'package:uts/core/constants/env_constants.dart';
import 'package:uts/core/di/injection_container.dart';
import 'package:uts/core/router/app_router.dart';
import 'package:uts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:uts/features/auth/presentation/bloc/auth_event.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_event.dart' as list_event;
import 'package:uts/features/ticket/presentation/bloc/detail/ticket_detail_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_event.dart' as stats_event;
import 'package:uts/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:uts/shared/widgets/global_error_boundary.dart';
import 'package:uts/shared/theme/app_theme.dart';
import 'package:uts/shared/theme/theme_cubit.dart';
import 'package:uts/core/storage/secure_local_storage.dart';
import 'package:uts/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:uts/features/admin/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:uts/features/admin/presentation/bloc/settings/app_settings_event.dart';
import 'package:uts/core/services/local_notification_service.dart';
import 'package:uts/core/services/fcm_service.dart';
import 'package:uts/shared/widgets/connectivity_banner_widget.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/features/auth/presentation/bloc/auth_state.dart';
import 'package:intl/date_symbol_data_local.dart';

// Top-level function for background FCM handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  // Pastikan Flutter binding terinitialize sebelum operasi async
  WidgetsFlutterBinding.ensureInitialized();

  // 0. Initialize Firebase
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found or failed to load. Ensure it is added to assets in pubspec.yaml.");
  }

  // Lock to portrait mode (sesuai SRS requirement mobile)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // 1. Initialize Supabase
  await Supabase.initialize(
    url: EnvConstants.supabaseUrl,
    anonKey: EnvConstants.supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureLocalStorage(),
    ),
  );

  // 2. Inisialisaasi semua dependensi (GetIt service locator)
  await initDependencies();

  // 3. Inisialisasi Local Notification Service
  await sl<LocalNotificationService>().initialize();

  // 4. Inisialisasi FCM Service
  await sl<FCMService>().initialize();

  // 5. Inisialisasi locale formatting
  await initializeDateFormatting('id', null);

  runApp(const ETicketingApp());
}


/// Root widget aplikasi E-Ticketing Helpdesk.
class ETicketingApp extends StatelessWidget {
  const ETicketingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // ThemeCubit shared di seluruh aplikasi
        BlocProvider<ThemeCubit>(
          create: (_) => sl<ThemeCubit>(),
        ),
        // AuthBloc untuk manajemen sesi
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>()..add(AppStarted()),
        ),
        // BLoCs untuk fitur tiket
        BlocProvider<TicketListBloc>(
          create: (_) => sl<TicketListBloc>()..add(const list_event.StartTicketListSubscription()),
        ),
        BlocProvider<TicketDetailBloc>(
          create: (_) => sl<TicketDetailBloc>(),
        ),
        BlocProvider<TicketStatsBloc>(
          create: (_) => sl<TicketStatsBloc>(),
        ),
        // NotificationBloc untuk fitur notifikasi
        BlocProvider<NotificationBloc>(
          create: (_) => sl<NotificationBloc>()..add(StartNotificationSubscription()),
        ),
        // AdminBloc untuk manajemen sistem
        BlocProvider<AdminBloc>(
          create: (_) => sl<AdminBloc>(),
        ),
        // AppSettingsBloc untuk konfigurasi global
        BlocProvider<AppSettingsBloc>(
          create: (_) => sl<AppSettingsBloc>()..add(FetchAppSettingsRequested()),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,

            // GoRouter configuration
            routerConfig: appRouter,

            // Tema Light & Dark
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,

            // Responsive text scaling
            builder: (context, child) {
              // Clamp text scale factor untuk mencegah overflow di berbagai device
              final mediaQuery = MediaQuery.of(context);
              final constrainedTextScaleFactor = mediaQuery.textScaler.clamp(
                minScaleFactor: 0.85,
                maxScaleFactor: 1.2,
              );

              final errorWrapped = GlobalErrorBoundary(child: child!);
              final connectivityWrapped = ConnectivityBannerWidget(child: errorWrapped);

              return BlocListener<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state.status == AuthStatus.sessionExpired) {
                    _showSessionExpiredDialog(context);
                  }
                  
                  if (state.status == AuthStatus.authenticated) {
                    // Start/Restart subscriptions on login
                    context.read<TicketListBloc>().add(const list_event.StartTicketListSubscription());
                    context.read<NotificationBloc>().add(StartNotificationSubscription());
                    context.read<TicketStatsBloc>().add(const stats_event.FetchTicketStatsRequested());
                  }

                  if (state.status == AuthStatus.unauthenticated) {
                    // Reset all app states on logout
                    context.read<TicketListBloc>().add(list_event.ResetTicketListState());
                    context.read<TicketStatsBloc>().add(stats_event.ResetTicketStatsState());
                    context.read<NotificationBloc>().add(ResetNotificationState());
                  }
                },
                child: MediaQuery(
                  data: mediaQuery.copyWith(textScaler: constrainedTextScaleFactor),
                  child: connectivityWrapped,
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showSessionExpiredDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Sesi Habis'),
        content: const Text('Sesi Anda telah berakhir. Silakan masuk kembali untuk melanjutkan.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(LogoutRequested());
            },
            child: const Text('Masuk Kembali'),
          ),
        ],
      ),
    );
  }
}
