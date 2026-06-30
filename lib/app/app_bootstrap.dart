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
import 'package:uts/features/admin/presentation/bloc/admin_event.dart';
import 'package:uts/features/admin/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:uts/features/admin/presentation/bloc/settings/app_settings_event.dart';
import 'package:uts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:uts/features/auth/presentation/bloc/auth_event.dart';
import 'package:uts/features/auth/presentation/bloc/auth_state.dart';
import 'package:uts/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/detail/ticket_detail_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/detail/ticket_detail_event.dart';
import 'package:uts/features/ticket/presentation/bloc/create/ticket_create_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/create/ticket_create_event.dart';
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

  final missingUrl = EnvConstants.supabaseUrl.trim().isEmpty;
  final missingKey = EnvConstants.supabaseAnonKey.trim().isEmpty;
  if (missingUrl || missingKey) {
    runApp(const _StartupMessageApp(
      title: 'Konfigurasi Belum Lengkap',
      message: 'SUPABASE_URL dan SUPABASE_ANON_KEY wajib diberikan saat build.',
    ));
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
    runApp(const _StartupMessageApp(
      title: 'Aplikasi Gagal Dimulai',
      message: 'Periksa konfigurasi Firebase, Supabase, dan koneksi perangkat.',
    ));
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
          create: (_) => sl<AuthBloc>()..add(const AppStarted()),
        ),
        BlocProvider<TicketListBloc>(create: (_) => sl<TicketListBloc>()),
        BlocProvider<TicketCreateBloc>(create: (_) => sl<TicketCreateBloc>()),
        BlocProvider<TicketDetailBloc>(create: (_) => sl<TicketDetailBloc>()),
        BlocProvider<TicketStatsBloc>(create: (_) => sl<TicketStatsBloc>()),
        BlocProvider<NotificationBloc>(create: (_) => sl<NotificationBloc>()),
        BlocProvider<AdminBloc>(create: (_) => sl<AdminBloc>()),
        BlocProvider<AppSettingsBloc>(create: (_) => sl<AppSettingsBloc>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) => MaterialApp.router(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          routerConfig: appRouter,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            final content = ConnectivityBannerWidget(
              child: GlobalErrorBoundary(
                child: child ?? const SizedBox.shrink(),
              ),
            );
            return BlocListener<AuthBloc, AuthState>(
              listener: _handleAuthenticationState,
              child: MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: mediaQuery.textScaler.clamp(
                    minScaleFactor: 0.85,
                    maxScaleFactor: 1.2,
                  ),
                ),
                child: content,
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleAuthenticationState(BuildContext context, AuthState state) {
    if (state.status == AuthStatus.authenticated) {
      context
          .read<TicketListBloc>()
          .add(const list_event.StartTicketListSubscription());
      context.read<NotificationBloc>().add(StartNotificationSubscription());
      context
          .read<TicketStatsBloc>()
          .add(const stats_event.FetchTicketStatsRequested());
      context.read<AppSettingsBloc>().add(const FetchAppSettingsRequested());
      return;
    }

    final shouldReset = state.status == AuthStatus.unauthenticated ||
        state.status == AuthStatus.sessionExpired ||
        state.status == AuthStatus.passwordRecovery ||
        (state.status == AuthStatus.error && state.user.isEmpty);
    if (!shouldReset) return;

    context.read<TicketListBloc>().add(list_event.ResetTicketListState());
    context.read<TicketCreateBloc>().add(const TicketCreateResetRequested());
    context.read<TicketDetailBloc>().add(ResetTicketDetailState());
    context.read<TicketStatsBloc>().add(stats_event.ResetTicketStatsState());
    context.read<NotificationBloc>().add(ResetNotificationState());
    context.read<AdminBloc>().add(const ResetAdminState());
    context.read<AppSettingsBloc>().add(const ResetAppSettingsState());

    if (state.status == AuthStatus.sessionExpired && context.mounted) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Sesi Habis'),
          content: const Text('Silakan masuk kembali untuk melanjutkan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Masuk Kembali'),
            ),
          ],
        ),
      );
    }
  }
}

class _StartupMessageApp extends StatelessWidget {
  final String title;
  final String message;

  const _StartupMessageApp({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 56, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(message, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
