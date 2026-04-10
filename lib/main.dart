import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_strings.dart';
import 'core/constants/env_constants.dart';
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'package:uts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:uts/features/auth/presentation/bloc/auth_event.dart';
import 'package:uts/features/ticket/presentation/bloc/ticket_bloc.dart';
import 'package:uts/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:uts/shared/theme/app_theme.dart';
import 'package:uts/shared/theme/theme_cubit.dart';

Future<void> main() async {
  // Pastikan Flutter binding terinitialize sebelum operasi async
  WidgetsFlutterBinding.ensureInitialized();

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
  );

  // 2. Inisialisasi semua dependensi (GetIt service locator)
  await initDependencies();

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
          create: (_) => sl<TicketBloc>(),
        ),
        // NotificationBloc untuk fitur notifikasi
        BlocProvider<NotificationBloc>(
          create: (_) => sl<NotificationBloc>(),
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
              return MediaQuery(
                data: mediaQuery.copyWith(textScaler: constrainedTextScaleFactor),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
