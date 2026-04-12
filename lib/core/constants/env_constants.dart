import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Konfigurasi Environment — Mengambil nilai dari file .env.
class EnvConstants {
  static String get supabaseUrl => dotenv.get('SUPABASE_URL', fallback: '');
  static String get supabaseAnonKey => dotenv.get('SUPABASE_ANON_KEY', fallback: '');
}
