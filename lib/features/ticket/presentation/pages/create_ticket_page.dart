import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/features/ticket/domain/entities/local_attachment_candidate.dart';
import 'package:uts/features/ticket/domain/validation/ticket_attachment_validator.dart';
import 'package:uts/shared/widgets/app_button.dart';
import 'package:uts/shared/widgets/app_text_field.dart';
import 'package:uts/features/ticket/presentation/bloc/create/ticket_create_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/create/ticket_create_event.dart';
import 'package:uts/features/ticket/presentation/bloc/create/ticket_create_state.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_event.dart'
    as list_event;
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_event.dart'
    as stats_event;
import 'package:uts/core/router/app_router.dart';

class CreateTicketPage extends StatefulWidget {
  const CreateTicketPage({super.key});

  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _subjectController = TextEditingController();
  final _descController = TextEditingController();

  final _subjectFocus = FocusNode();
  final _descFocus = FocusNode();
  final TicketAttachmentValidator _attachmentValidator =
      const TicketAttachmentValidator();

  String _selectedCategory = '';
  final List<LocalAttachmentCandidate> _attachments = [];
  final ImagePicker _picker = ImagePicker();

  bool _isSuccess = false;

  late final AnimationController _successAnimController;
  late final Animation<double> _scaleAnim;

  bool _showCategoryError = false;

  static const List<Map<String, Object>> _categories = [
    {'value': 'hardware', 'label': 'Hardware', 'icon': Icons.build_rounded},
    {
      'value': 'software',
      'label': 'Software',
      'icon': Icons.laptop_chromebook_rounded,
    },
    {'value': 'network', 'label': 'Jaringan', 'icon': Icons.language_rounded},
    {'value': 'account', 'label': 'Akun & Akses', 'icon': Icons.key_rounded},
    {'value': 'other', 'label': 'Lainnya', 'icon': Icons.help_rounded},
  ];

  @override
  void initState() {
    super.initState();
    final createStatus = context.read<TicketCreateBloc>().state.status;
    _isSuccess = createStatus == TicketCreateStatus.success;
    _subjectController.addListener(_updateProgress);
    _descController.addListener(_updateProgress);

    _successAnimController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _successAnimController, curve: Curves.elasticOut));
    if (_isSuccess) {
      _successAnimController.value = 1;
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descController.dispose();
    _subjectFocus.dispose();
    _descFocus.dispose();
    _successAnimController.dispose();
    super.dispose();
  }

  double get _progress {
    int score = 0;
    final subject = _subjectController.text.trim();
    final description = _descController.text.trim();

    if (subject.length >= 5) score += 25;
    if (_selectedCategory.isNotEmpty) score += 25;
    if (description.length >= 20) {
      score += 50;
    } else if (description.isNotEmpty) {
      score += 10; // Partial progress
    }
    return score / 100.0;
  }

  bool get _isFormValid {
    final title = _subjectController.text.trim();
    final desc = _descController.text.trim();
    return title.isNotEmpty &&
        _selectedCategory.isNotEmpty &&
        desc.length >= 20;
  }

  void _updateProgress() => setState(() {});

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
          source: source, imageQuality: 80, maxWidth: 1920);

      if (image != null) {
        final file = File(image.path);
        final sizeInBytes = await file.length();
        final candidate = LocalAttachmentCandidate.fromPath(
          localPath: image.path,
          fileName: image.name,
          sizeBytes: sizeInBytes,
          source: source == ImageSource.camera
              ? LocalAttachmentSource.camera
              : LocalAttachmentSource.gallery,
        );

        final validation = _attachmentValidator.validateAll([
          ..._attachments,
          candidate,
        ]);

        if (!validation.isValid) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(validation.message ?? 'Lampiran tidak valid.'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
          return;
        }

        setState(() => _attachments.add(candidate));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil gambar: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: TicketAttachmentConstraints.allowedExtensions
            .where((extension) => extension == 'pdf')
            .toList(growable: false),
        withData: false,
      );

      final file = result?.files.single;
      if (file == null) {
        return;
      }

      final path = file.path;
      if (path == null || path.trim().isEmpty) {
        _showAttachmentError('Path dokumen tidak valid.');
        return;
      }

      final localFile = File(path);
      if (!await localFile.exists()) {
        _showAttachmentError('Dokumen tidak ditemukan.');
        return;
      }

      final sizeInBytes = await localFile.length();
      final candidate = LocalAttachmentCandidate.fromPath(
        localPath: path,
        fileName: file.name,
        mimeType: LocalAttachmentCandidate.inferMimeTypeFromExtension(
          file.extension ?? '',
        ),
        sizeBytes: sizeInBytes,
        source: LocalAttachmentSource.document,
      );

      final validation = _attachmentValidator.validateAll([
        ..._attachments,
        candidate,
      ]);

      if (!validation.isValid) {
        _showAttachmentError(validation.message ?? 'Lampiran tidak valid.');
        return;
      }

      setState(() => _attachments.add(candidate));
    } catch (e) {
      _showAttachmentError('Gagal memilih dokumen.');
    }
  }

  void _showAttachmentError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  void _removeImage(int index) => setState(() => _attachments.removeAt(index));

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_rounded),
              title: const Text('Dokumen PDF'),
              onTap: () {
                Navigator.pop(context);
                _pickDocument();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    setState(() {
      _showCategoryError = _selectedCategory.isEmpty;
    });

    final isFormValid = _formKey.currentState?.validate() ?? false;

    if (!isFormValid || _selectedCategory.isEmpty) {
      // Show snackbar for better UX if hidden errors exist
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi semua field yang wajib diisi'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final attachmentValidation = _attachmentValidator.validateAll(_attachments);
    if (!attachmentValidation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            attachmentValidation.message ?? 'Lampiran tidak valid.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final isLoading = context.read<TicketCreateBloc>().state.isBusy;
    if (isLoading) return;

    FocusScope.of(context).unfocus();

    context.read<TicketCreateBloc>().add(SubmitTicketCreateRequested(
          title: _subjectController.text.trim(),
          description: _descController.text.trim(),
          category: _selectedCategory,
          attachments: List<LocalAttachmentCandidate>.unmodifiable(
            _attachments,
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<TicketCreateBloc, TicketCreateState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.message != current.message,
      listener: (context, state) {
        if (state.status == TicketCreateStatus.success && !_isSuccess) {
          setState(() {
            _isSuccess = true;
          });
          _successAnimController.forward();
          final createdTicket = state.ticket;
          if (createdTicket != null) {
            context
                .read<TicketListBloc>()
                .add(list_event.TicketCreatedLocally(createdTicket));
          }
          context
              .read<TicketStatsBloc>()
              .add(stats_event.FetchTicketStatsRequested());
        }
        if (!state.isBusy &&
            state.status != TicketCreateStatus.success &&
            state.message != null &&
            !_isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(state.message!)),
                ],
              ),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: _isSuccess
            ? null
            : AppBar(
                elevation: 0,
                backgroundColor: isDark
                    ? AppColors.backgroundDark
                    : AppColors.backgroundLight,
                leading: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => context.pop(),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: isDark ? Colors.white12 : Colors.black12,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 2,
                  ),
                ),
              ),
        body: _isSuccess
            ? _buildSuccessState(
                context.watch<TicketCreateBloc>().state,
                isDark,
              )
            : _buildFormState(isDark),
      ),
    );
  }

  Widget _buildFormState(bool isDark) {
    final createState = context.watch<TicketCreateBloc>().state;
    final isLoading = createState.isBusy;

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Buat Laporan',
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1)),
                      const SizedBox(height: 32),

                      // SECTION 1
                      _buildSectionTitle('1. Informasi Dasar', isDark),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Judul Laporan',
                        hint: 'Sebutkan inti masalah Anda (min. 5 karakter)',
                        controller: _subjectController,
                        focusNode: _subjectFocus,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_descFocus),
                        maxLength: 100,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Harap isi judul laporan';
                          }
                          if (v.trim().length < 5) {
                            return 'Judul terlalu pendek (min. 5 karakter)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Kategori',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87)),
                          if (_showCategoryError && _selectedCategory.isEmpty)
                            const Text('Pilih kategori',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final categoryValue = cat['value']! as String;
                          final categoryLabel = cat['label']! as String;
                          final isSelected = _selectedCategory == categoryValue;
                          final hasError =
                              _showCategoryError && _selectedCategory.isEmpty;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = categoryValue;
                                _showCategoryError = false;
                              });
                              _updateProgress();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : (isDark
                                        ? AppColors.surfaceDark
                                        : AppColors.surfaceLight),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (hasError
                                          ? AppColors.danger
                                              .withValues(alpha: 0.5)
                                          : (isDark
                                              ? AppColors.borderDark
                                              : AppColors.borderLight)),
                                  width: isSelected || hasError ? 1.5 : 1.0,
                                ),
                              ),
                              alignment: Alignment.centerLeft,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  Icon(
                                    _iconForCategory(categoryValue),
                                    size: 18,
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark
                                            ? Colors.white70
                                            : Colors.black54),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(categoryLabel,
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87))),
                                  if (isSelected)
                                    const Icon(Icons.check_circle_rounded,
                                        size: 16, color: AppColors.primary),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      Divider(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight),
                      const SizedBox(height: 24),

                      // SECTION 2
                      _buildSectionTitle('2. Detail Masalah', isDark),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Deskripsi',
                        hint:
                            'Jelaskan masalah secara rinci (minimal 20 karakter)...',
                        controller: _descController,
                        focusNode: _descFocus,
                        maxLines: 8,
                        minLines: 4,
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.multiline,
                        maxLength: 500,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Harap isi deskripsi masalah';
                          }
                          if (v.trim().length < 20) {
                            return 'Deskripsi terlalu pendek (min. 20 karakter)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      Divider(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight),
                      const SizedBox(height: 24),

                      // SECTION 3
                      _buildSectionTitle('3. Lampiran', isDark),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Lampiran',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87)),
                          Text(
                              '${_attachments.length}/${TicketAttachmentConstraints.maxAttachmentCount}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black54)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildAttachmentPicker(isDark),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),

            // BOTTOM ACTION AREA
            Container(
              padding: EdgeInsets.fromLTRB(
                  24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
              decoration: BoxDecoration(
                color:
                    isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
                border: Border(
                    top: BorderSide(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_progress > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Kategori: ${_selectedCategory.isEmpty ? '-' : _categories.firstWhere((e) => e['value'] == _selectedCategory)['label']}',
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton.primary(
                      label: isLoading ? 'Mengirim...' : 'Kirim Laporan',
                      isLoading: isLoading,
                      onPressed: (_isFormValid && !isLoading) ? _submit : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (isLoading)
          AbsorbPointer(
            child: Container(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.3),
            ),
          ),
        if (isLoading)
          Positioned(
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).padding.bottom + 92,
            child: _buildProgressCard(createState, isDark),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildAttachmentPicker(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_attachments.length <
            TicketAttachmentConstraints.maxAttachmentCount)
          OutlinedButton.icon(
            onPressed: _showImageSourceSheet,
            icon: const Icon(Icons.attach_file_rounded),
            label: const Text('Tambah Lampiran'),
          ),
        if (_attachments.isNotEmpty) const SizedBox(height: 12),
        ..._attachments.asMap().entries.map((entry) {
          final attachment = entry.value;
          final isImage = attachment.source == LocalAttachmentSource.camera ||
              attachment.source == LocalAttachmentSource.gallery;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: isImage
                        ? Image.file(
                            File(attachment.localPath),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_not_supported_outlined,
                            ),
                          )
                        : Container(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            child: const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attachment.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatBytes(attachment.sizeBytes)} - ${attachment.mimeType}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Hapus lampiran',
                  onPressed: () => _removeImage(entry.key),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildProgressCard(TicketCreateState state, bool isDark) {
    final label = switch (state.status) {
      TicketCreateStatus.validating => 'Memvalidasi tiket...',
      TicketCreateStatus.uploading =>
        'Mengunggah ${state.currentFileName ?? 'lampiran'} (${state.uploadedCount}/${state.totalCount})',
      TicketCreateStatus.creatingTicket => 'Menyimpan tiket...',
      _ => 'Memproses...',
    };

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  IconData _iconForCategory(String value) {
    return switch (value) {
      'hardware' => Icons.build_rounded,
      'software' => Icons.laptop_chromebook_rounded,
      'network' => Icons.language_rounded,
      'account' => Icons.key_rounded,
      _ => Icons.help_rounded,
    };
  }

  Widget _buildSuccessState(TicketCreateState state, bool isDark) {
    final ticketId = state.ticket?.id.trim();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 64),
              ),
            ),
            const SizedBox(height: 32),
            Text('Laporan Terkirim!',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 12),
            Text(
              'Tim helpdesk kami akan segera menindaklanjuti masalah Anda.',
              style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: AppButton.primary(
                label: 'Lihat Tiket',
                onPressed: ticketId == null || ticketId.isEmpty
                    ? null
                    : () => context.pushReplacementNamed(
                          'ticket-detail',
                          pathParameters: {'id': ticketId},
                        ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: AppButton.ghost(
                label: 'Kembali ke Beranda',
                onPressed: () => context.go(AppRoutes.dashboard),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
