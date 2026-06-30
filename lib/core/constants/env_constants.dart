class EnvConstants {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Custom URI handled by Android and iOS for Supabase password recovery.
  static const String passwordRecoveryRedirect =
      'ticketq://reset-password';
}
