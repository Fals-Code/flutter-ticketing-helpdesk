import 'package:flutter/material.dart';
import 'package:uts/shared/theme/app_theme.dart';

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
    final values = <String>[
      if (isUrlMissing) 'SUPABASE_URL',
      if (isKeyMissing) 'SUPABASE_ANON_KEY',
    ].join(' dan ');
    return _StatusApp(
      title: 'Konfigurasi Belum Terpasang',
      message: '$values belum diberikan saat proses build.',
    );
  }
}

class StartupErrorApp extends StatelessWidget {
  final String message;

  const StartupErrorApp({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return _StatusApp(
      title: 'Aplikasi Gagal Dimulai',
      message: message,
    );
  }
}

class _StatusApp extends StatelessWidget {
  final String title;
  final String message;

  const _StatusApp({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 56, color: Colors.red),
                const SizedBox(height: 16),
                Text(title, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
