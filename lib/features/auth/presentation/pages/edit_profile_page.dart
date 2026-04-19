import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/enums.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();

  File? _pickedImage;
  bool _isNameValid = false;
  bool _isEmailValid = false;

  String _originalName = '';
  String _originalEmail = '';

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    final user = context.read<AuthBloc>().state.user;
    _originalName = user.fullName ?? '';
    _originalEmail = user.email;
    _nameController.text = _originalName;
    _emailController.text = _originalEmail;
    _isNameValid = _originalName.isNotEmpty;
    _isEmailValid = _originalEmail.isNotEmpty;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();

    _nameController.addListener(
        () => setState(() => _isNameValid = _nameController.text.trim().isNotEmpty));
    _emailController.addListener(() {
      final val = _emailController.text.trim();
      setState(() => _isEmailValid =
          RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(val));
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool get _emailChanged =>
      _emailController.text.trim() != _originalEmail;

  bool get _nameChanged =>
      _nameController.text.trim() != _originalName;

  bool get _hasChanges =>
      (_nameChanged && _isNameValid) || _emailChanged || _pickedImage != null;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pilih Sumber Foto',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                      ctx, Icons.camera_alt_rounded, 'Kamera', ImageSource.camera),
                  _buildSourceOption(
                      ctx, Icons.photo_library_rounded, 'Galeri', ImageSource.gallery),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (pickedFile != null && mounted) {
        setState(() => _pickedImage = File(pickedFile.path));
      }
    }
  }

  Widget _buildSourceOption(
      BuildContext ctx, IconData icon, String label, ImageSource source) {
    return InkWell(
      onTap: () => Navigator.pop(ctx, source),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _onSave() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim();

    // Upload avatar first if a new image was picked
    if (_pickedImage != null) {
      context.read<AuthBloc>().add(UpdateAvatarRequested(_pickedImage!));
    }

    // Update name and/or email if either changed
    final emailToSend = _emailChanged ? newEmail : null;
    context.read<AuthBloc>().add(UpdateProfileRequested(
          fullName: newName,
          email: emailToSend,
        ));
  }

  void _showEmailConfirmationDialog(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'EmailConfirmation',
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (ctx, anim1, anim2) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 10)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mark_email_read_rounded,
                      color: AppColors.success, size: 40),
                ),
                const SizedBox(height: 20),
                Text('Profil Diperbarui',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4)),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: AppButton.primary(
                    label: 'Mengerti',
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.pop(); // kembali ke profil
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (ctx, anim1, anim2, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim1, child: child),
      ),
    );
  }

  Color _getNameColor(String name) {
    final int hash = name.hashCode;
    final List<Color> palette = [
      const Color(0xFF6366F1), const Color(0xFF8B5CF6), const Color(0xFFEC4899),
      const Color(0xFFF43F5E), const Color(0xFFF97316), const Color(0xFF10B981),
      const Color(0xFF06B6D4), const Color(0xFF3B82F6),
    ];
    return palette[hash.abs() % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated &&
            state.successMessage != null) {
          final msg = state.successMessage!;
          context.read<AuthBloc>().add(ClearAuthStatus());

          // Show special dialog if email was changed, else simple snackbar
          if (msg.contains('email')) {
            _showEmailConfirmationDialog(msg);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(children: [
                  const Icon(Icons.check_circle_outline,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(msg)),
                ]),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Future.delayed(const Duration(milliseconds: 800),
                () { if (context.mounted) context.pop(); });
          }
        }
        if (state.status == AuthStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(state.errorMessage!)),
              ]),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Edit Profil',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.space24),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _animationController,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppDimensions.space16),

                      // ── Avatar Section ─────────────────────────────────────
                      Center(
                        child: BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            final user = state.user;
                            final name = user.fullName ?? 'Pengguna';
                            final avatarColor = _getNameColor(name);
                            final isLoading = state.status == AuthStatus.loading;

                            return Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: avatarColor.withValues(alpha: 0.15),
                                    border: Border.all(
                                        color: avatarColor.withValues(alpha: 0.3),
                                        width: 3),
                                    image: _pickedImage != null
                                        ? DecorationImage(
                                            image: FileImage(_pickedImage!),
                                            fit: BoxFit.cover)
                                        : user.avatarUrl != null
                                            ? DecorationImage(
                                                image: NetworkImage(user.avatarUrl!),
                                                fit: BoxFit.cover)
                                            : null,
                                  ),
                                  child: (_pickedImage == null &&
                                              user.avatarUrl == null) ||
                                          isLoading
                                      ? Center(
                                          child: isLoading
                                              ? const SizedBox(
                                                  width: 28,
                                                  height: 28,
                                                  child: CircularProgressIndicator(
                                                      strokeWidth: 2.5))
                                              : Text(
                                                  name.substring(0, 1).toUpperCase(),
                                                  style:
                                                      GoogleFonts.plusJakartaSans(
                                                    fontSize: 38,
                                                    fontWeight: FontWeight.w800,
                                                    color: avatarColor,
                                                  ),
                                                ),
                                        )
                                      : null,
                                ),
                                if (!isLoading)
                                  InkWell(
                                    onTap: _pickImage,
                                    borderRadius: BorderRadius.circular(24),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3)),
                                        ],
                                      ),
                                      child: const Icon(Icons.camera_alt_rounded,
                                          size: 16, color: Colors.white),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space8),
                      Center(
                        child: TextButton(
                          onPressed: _pickImage,
                          child: Text(
                            'Ubah Foto Profil',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space32),

                      // ── Informasi Pribadi ──────────────────────────────────
                      Text(
                        'INFORMASI PRIBADI',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space12),
                      AppTextField(
                        label: 'Nama Lengkap',
                        hint: 'Masukkan nama lengkap Anda',
                        controller: _nameController,
                        focusNode: _nameFocus,
                        prefixIcon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _emailFocus.requestFocus(),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nama tidak boleh kosong'
                            : null,
                        isSuccess: _isNameValid,
                      ),
                      const SizedBox(height: AppDimensions.space20),

                      // ── Email ─────────────────────────────────────────────
                      Text(
                        'ALAMAT EMAIL',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space12),
                      AppTextField(
                        label: 'Email',
                        hint: 'Masukkan alamat email baru',
                        controller: _emailController,
                        focusNode: _emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (_hasChanges) _onSave();
                        },
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$')
                              .hasMatch(v.trim())) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                        isSuccess: _isEmailValid,
                      ),
                      if (_emailChanged) ...[
                        const SizedBox(height: AppDimensions.space8),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 14, color: AppColors.warning),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Email baru memerlukan verifikasi. Link konfirmasi akan dikirim ke alamat baru.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.warning,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppDimensions.space40),

                      // ── Save Button ────────────────────────────────────────
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          return AppButton.primary(
                            label: 'Simpan Perubahan',
                            onPressed: _hasChanges ? _onSave : null,
                            isLoading: state.status == AuthStatus.loading,
                            size: AppButtonSize.large,
                          );
                        },
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
