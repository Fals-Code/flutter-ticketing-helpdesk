abstract final class AuthIdentifier {
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _usernamePattern = RegExp(r'^[a-z][a-z0-9_]{2,29}$');

  static String normalize(String value) => value.trim().toLowerCase();

  static bool isEmail(String value) => _emailPattern.hasMatch(normalize(value));

  static bool isUsername(String value) =>
      _usernamePattern.hasMatch(normalize(value));

  static bool isValid(String value) => isEmail(value) || isUsername(value);

  static String? validateLogin(String? value) {
    final normalized = normalize(value ?? '');
    if (normalized.isEmpty) {
      return 'Email atau username wajib diisi';
    }
    if (!isValid(normalized)) {
      return 'Gunakan email valid atau username 3-30 karakter';
    }
    return null;
  }

  static String? validateUsername(String? value) {
    final normalized = normalize(value ?? '');
    if (normalized.isEmpty) {
      return 'Username wajib diisi';
    }
    if (!isUsername(normalized)) {
      return 'Username harus diawali huruf dan hanya memakai huruf kecil, angka, atau garis bawah';
    }
    return null;
  }
}
