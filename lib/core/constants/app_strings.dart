/// Konstanta string untuk seluruh aplikasi E-Ticketing Helpdesk.
/// Memudahkan lokalisasi di masa depan.
abstract class AppStrings {
  // ── App Info ───────────────────────────────────────────────────────────────
  static const String appName = 'E-Ticketing Helpdesk';
  static const String appTagline = 'Solusi Cepat, Laporan Tepat';

  // ── Auth ───────────────────────────────────────────────────────────────────
  static const String login = 'Masuk';
  static const String logout = 'Keluar';
  static const String email = 'Email';
  static const String password = 'Kata Sandi';
  static const String forgotPassword = 'Lupa Kata Sandi?';
  static const String loginTitle = 'Selamat Datang';
  static const String loginSubtitle = 'Masuk ke akun helpdesk Anda';
  static const String emailHint = 'contoh@perusahaan.com';
  static const String passwordHint = 'Masukkan kata sandi';
  static const String roleLabel = 'Masuk sebagai';
  static const String roleUser = 'Pengguna';
  static const String roleTechnician = 'Teknisi / Agen';
  static const String roleAdmin = 'Administrator';
  static const String emailRequired = 'Email tidak boleh kosong';
  static const String emailInvalid = 'Format email tidak valid';
  static const String passwordRequired = 'Kata sandi tidak boleh kosong';
  static const String passwordMinLength = 'Minimal 6 karakter';

  // ── Navigation ─────────────────────────────────────────────────────────────
  static const String navDashboard = 'Beranda';
  static const String navTickets = 'Tiket';
  static const String navNotifications = 'Notifikasi';
  static const String navProfile = 'Profil';

  // ── Dashboard ──────────────────────────────────────────────────────────────
  static const String dashboardGreeting = 'Selamat datang';
  static const String dashboardSubtitle = 'Pantau dan kelola tiket Anda';
  static const String totalTickets = 'Total Tiket';
  static const String openTickets = 'Tiket Terbuka';
  static const String resolvedTickets = 'Tiket Selesai';
  static const String inProgressTickets = 'Sedang Diproses';

  // ── Tickets ────────────────────────────────────────────────────────────────
  static const String myTickets = 'Tiket Saya';
  static const String createTicket = 'Buat Tiket';
  static const String ticketSubject = 'Subjek';
  static const String ticketDescription = 'Deskripsi';
  static const String ticketCategory = 'Kategori';
  static const String ticketPriority = 'Prioritas';
  static const String ticketStatus = 'Status';

  // ── Status Labels ──────────────────────────────────────────────────────────
  static const String statusOpen = 'Terbuka';
  static const String statusInProgress = 'Diproses';
  static const String statusResolved = 'Selesai';
  static const String statusClosed = 'Ditutup';

  // ── Priority Labels ────────────────────────────────────────────────────────
  static const String priorityLow = 'Rendah';
  static const String priorityMedium = 'Sedang';
  static const String priorityHigh = 'Tinggi';
  static const String priorityCritical = 'Kritis';

  // ── Error Messages ─────────────────────────────────────────────────────────
  static const String errorGeneral = 'Terjadi kesalahan. Coba lagi.';
  static const String errorNetwork = 'Periksa koneksi internet Anda.';
  static const String errorUnauthorized = 'Sesi berakhir. Silakan masuk ulang.';
  static const String errorNotFound = 'Data tidak ditemukan.';

  // ── Success Messages ───────────────────────────────────────────────────────
  static const String successTicketCreated = 'Tiket berhasil dibuat!';
  static const String successLogin = 'Login berhasil!';
  static const String successLogout = 'Berhasil keluar.';

  // ── Common ─────────────────────────────────────────────────────────────────
  static const String submit = 'Kirim';
  static const String cancel = 'Batal';
  static const String save = 'Simpan';
  static const String edit = 'Edit';
  static const String delete = 'Hapus';
  static const String loading = 'Memuat...';
  static const String noData = 'Belum ada data';
  static const String retry = 'Coba Lagi';
  static const String search = 'Cari tiket...';
}
