import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:uts/core/constants/app_strings.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/core/constants/env_constants.dart';
import 'package:uts/core/di/injection_container.dart';
import 'package:uts/core/router/app_router.dart';
import 'package:uts/core/services/fcm_service.dart';
import 'package:uts/core/services/local_notification_service.dart';
import 'package:uts/core/storage/secure_local_storage.dart';
import 'package:uts/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:uts/features/admin/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:uts/features/admin/presentation/bloc/settings/app_settings_event.dart';
import 'package:uts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:uts/features/auth/presentation/bloc/auth_event.dart';
import 'package:uts/features/auth/presentation/bloc/auth_state.dart';
import 'package:uts/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/detail/ticket_detail_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/detail/ticket_detail_event.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_event.dart'
    as list_event;
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_event.dart'
    as stats_event;
import 'package:uts/shared/theme/app_theme.dart';
import 'package:uts/shared/theme/theme_cubit.dart';
import 'package:uts/shared/widgets/connectivity_banner_widget.dart';
import 'package:uts/shared/widgets/global_error_boundary.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling background FCM message: ${message.messageId}');
}

Future<void> bootstrapApplication() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isUrlMissing = EnvConstants.supabaseUrl.trim().isEmpty;
  final isKeyMissing = EnvConstants.supabaseAnonKey.trim().isEmpty;

  if (isUrlMissing || isKeyMissing) {
    runApp(
      ConfigurationErrorApp(
        isUrlMissing: isUrlMissing,
        isKeyMissing: isKeyMissing,
      ),
    );
    return;
  }

  try {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await Supabase.initialize(
      url: EnvConstants.supabaseUrl,
      anonKey: EnvConstants.supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: SecureLocalStorage(),
      ),
    );

    await initDependencies();
    await sl<LocalNotificationService>().initialize();
    await sl<FCMService>().initialize();
    await initializeDateFormatting('id', null);

    runApp(const ETicketingApp());
  } catch (error, stackTrace) {
    debugPrint('Application bootstrap failed: $error');
    debugPrintStack(stackTrace: stackTrace);

    runApp(
      const StartupErrorApp(
        message:
            'Inisialisasi layanan gagal. Periksa konfigurasi Firebase, '
            'Supabase, dan koneksi perangkat sebelum mencoba kembali.',
      ),
    );
  }
}

class ETicketingApp extends StatelessWidget {
  const ETicketingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => sl<ThemeCubit>()),
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>()..add(AppStarted()),
        ),
        BlocProvider<TicketListBloc>(create: (_) => sl<TicketListBloc>()),
        BlocProvider<TicketDetailBloc>(create: (_) => sl<TicketDetailBloc>()),
        BlocProvider<TicketStatsBloc>(create: (_) => sl<TicketStatsBloc>()),
        BlocProvider<NotificationBloc>(create: (_) => sl<NotificationBloc>()),
        BlocProvider<AdminBloc>(create: (_) => sl<AdminBloc>()),
        BlocProvider<AppSettingsBloc>(
          create: (_) =>
              sl<AppSettingsBloc>()..add(FetchAppSettingsRequested()),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            routerConfig: appRouter,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              final constrainedTextScaler = mediaQuery.textScaler.clamp(
                minScaleFactor: 0.85,
                maxScaleFactor: 1.2,
              );

              final appContent = ConnectivityBannerWidget(
                child: GlobalErrorBoundary(
                  child: child ?? const SizedBox.shrink(),
                ),
              );

              return BlocListener<AuthBloc, AuthState>(
                listener: _handleAuthenticationState,
                child: MediaQuery(
                  data: mediaQuery.copyWith(textScaler: constrainedTextScaler),
                  child: appContent,
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _handleAuthenticationState(BuildContext context, AuthState state) {
    if (state.status == AuthStatus.authenticated) {
      context
          .read<TicketListBloc>()
          .add(const list_event.StartTicketListSubscription());
      context
          .read<NotificationBloc>()
          .add(StartNotificationSubscription());
      context
          .read<TicketStatsBloc>()
          .add(const stats_event.FetchTicketStatsRequested());
      return;
    }

    if (state.status == AuthStatus.unauthenticated ||
        state.status == AuthStatus.sessionExpired) {
      _resetSessionScopedState(context);

      if (state.status == AuthStatus.sessionExpired) {
        _showSessionExpiredDialog(context);
      }
    }
  }

  void _resetSessionScopedState(BuildContext context) {
    context
        .read<TicketListBloc>()
        .add(list_event.ResetTicketListState());
    context.read<TicketDetailBloc>().add(ResetTicketDetailState());
    context
        .read<TicketStatsBloc>()
        .add(stats_event.ResetTicketStatsState());
    context.read<NotificationBloc>().add(ResetNotificationState());
  }

  void _showSessionExpiredDialog(BuildContext context) {
    if (!context.mounted) {
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sesi Habis'),
        content: const Text(
          'Sesi Anda telah berakhir. Silakan masuk kembali untuk melanjutkan.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthBloc>().add(LogoutRequested());
            },
            child: const Text('Masuk Kembali'),
          ),
        ],
      ),
    );
  }
}

class ConfigurationErrorApp extends StatelessWidget {
  final bool isUrlMissing;
  final bool isKeyMissing;

  const ConfigurationErrorApp({
    super.key,
    this.isUrlMissing = false,
    this.isKeyMissing = false,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _ConfigurationErrorPage(
        isUrlMissing: isUrlMissing,
        isKeyMissing: isKeyMissing,
      ),
    );
  }
}

class _ConfigurationErrorPage extends StatelessWidget {
  final bool isUrlMissing;
  final bool isKeyMissing;

  const _ConfigurationErrorPage({
    required this.isUrlMissing,
    required this.isKeyMissing,
  });

  @override
  Widget build(BuildContext context) {
    final missingValues = <String>[
      if (isUrlMissing) 'SUPABASE_URL',
      if (isKeyMissing) 'SUPABASE_ANON_KEY',
    ].join(' dan ');

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.security_outlined,
                        color: Colors.red,
                        size: 56,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Konfigurasi Belum Terpasang',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$missingValues belum diberikan saat proses build. '
                        'Aplikasi dihentikan dalam mode aman agar tidak berjalan '
                        'dengan konfigurasi kosong.',
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Jalankan aplikasi dengan:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: const SelectableText(
                          'flutter run --dart-define-from-file=define_config.json',
                          style: TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Gunakan define_config.example.json sebagai pola dan '
                        'jangan commit credential asli ke repository.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StartupErrorApp extends StatelessWidget {
  final String message;

  const StartupErrorApp({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 56,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aplikasi Gagal Dimulai',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
