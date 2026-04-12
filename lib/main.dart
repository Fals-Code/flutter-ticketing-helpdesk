import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uts/core/constants/app_strings.dart';
import 'package:uts/core/constants/env_constants.dart';
import 'package:uts/core/di/injection_container.dart';
import 'package:uts/core/router/app_router.dart';
import 'package:uts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:uts/features/auth/presentation/bloc/auth_event.dart';
import 'package:uts/features/ticket/presentation/bloc/ticket_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/ticket_event.dart';
import 'package:uts/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:uts/shared/theme/app_theme.dart';
import 'package:uts/shared/theme/theme_cubit.dart';
import 'package:uts/core/storage/secure_local_storage.dart';
import 'package:uts/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:uts/core/services/local_notification_service.dart';
import 'package:uts/shared/widgets/connectivity_banner_widget.dart';

Future<void> main() async {
  // Pastikan Flutter binding terinitialize sebelum operasi async
  WidgetsFlutterBinding.ensureInitialized();

  // 0. Initialize Firebase
  await Firebase.initializeApp();

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
        // TicketBloc untuk fitur tiket
        BlocProvider<TicketBloc>(
          create: (_) => sl<TicketBloc>()..add(StartTicketSubscription()),
        ),
        // NotificationBloc untuk fitur notifikasi
        BlocProvider<NotificationBloc>(
          create: (_) => sl<NotificationBloc>()..add(StartNotificationSubscription()),
        ),
        // AdminBloc untuk manajemen sistem
        BlocProvider<AdminBloc>(
          create: (_) => sl<AdminBloc>(),
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
              final constrainedTextScaleFactor =
                  mediaQuery.textScaler.clamp(
                minScaleFactor: 0.85,
                maxScaleFactor: 1.2,
              );
              final connectivityWrapped = ConnectivityBannerWidget(child: child!);
              return MediaQuery(
                data: mediaQuery.copyWith(textScaler: constrainedTextScaleFactor),
                child: connectivityWrapped,
              );
            },
          );
        },
      ),
    );
  }
}
