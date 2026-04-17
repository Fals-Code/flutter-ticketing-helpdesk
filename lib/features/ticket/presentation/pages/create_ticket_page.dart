import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/shared/widgets/app_button.dart';
import 'package:uts/shared/widgets/app_text_field.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_event.dart' as list_event;
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_state.dart' as list_state;
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_event.dart' as stats_event;
import 'package:uts/core/router/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uts/core/constants/enums.dart';

class CreateTicketPage extends StatefulWidget {
  const CreateTicketPage({super.key});

  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  final _subjectController = TextEditingController();
  final _descController = TextEditingController();
  
  final _subjectFocus = FocusNode();
  final _descFocus = FocusNode();

  String _selectedCategory = '';
  TicketPriority _selectedPriority = TicketPriority.medium;
  final List<String> _imagePaths = [];
  final ImagePicker _picker = ImagePicker();

  bool _isSuccess = false;

  late final AnimationController _successAnimController;
  late final Animation<double> _scaleAnim;

  static const _categories = [
    {'value': 'hardware', 'label': 'Hardware', 'icon': '🔧'},
    {'value': 'software', 'label': 'Software', 'icon': '💻'},
    {'value': 'network', 'label': 'Jaringan', 'icon': '🌐'},
    {'value': 'account', 'label': 'Akun & Akses', 'icon': '🔑'},
    {'value': 'other', 'label': 'Lainnya', 'icon': '❓'},
  ];

  @override
  void initState() {
    super.initState();
    _subjectController.addListener(_updateProgress);
    _descController.addListener(_updateProgress);
    
    _successAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _successAnimController, curve: Curves.elasticOut));
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
    if (_subjectController.text.trim().isNotEmpty) score += 25;
    if (_selectedCategory.isNotEmpty) score += 25;
    if (_descController.text.trim().isNotEmpty) score += 50;
    return score / 100.0;
  }

  bool get _isFormValid => _progress == 1.0;

  void _updateProgress() => setState(() {});

  Future<void> _pickImage(ImageSource source) async {
    if (_imagePaths.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maksimal 5 foto lampiran.')));
      return;
    }
    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 70, maxWidth: 1080);
      if (image != null) setState(() => _imagePaths.add(image.path));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  void _removeImage(int index) => setState(() => _imagePaths.removeAt(index));

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_isFormValid) return;
    FocusScope.of(context).unfocus();
    
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sesi telah berakhir.')));
      return;
    }

    context.read<TicketListBloc>().add(list_event.CreateTicketRequested(
      userId: currentUser.id,
      title: _subjectController.text.trim(),
      description: _descController.text.trim(),
      category: _selectedCategory,
      priority: _selectedPriority.name,
      imagePaths: _imagePaths,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<TicketListBloc, list_state.TicketListState>(
      listener: (context, state) {
        if (state.successMessage != null && !_isSuccess) {
          setState(() {
            _isSuccess = true;
          });
          _successAnimController.forward();
          context.read<TicketStatsBloc>().add(stats_event.FetchTicketStatsRequested());
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!), backgroundColor: AppColors.danger),
          );
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: _isSuccess ? null : AppBar(
          elevation: 0,
          backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.pop(),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: isDark ? Colors.white12 : Colors.black12,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 2,
            ),
          ),
        ),
        body: _isSuccess ? _buildSuccessState(isDark) : _buildFormState(isDark),
      ),
    );
  }

  Widget _buildFormState(bool isDark) {
    final isLoading = context.watch<TicketListBloc>().state.isLoading;

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Buat Laporan', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1)),
                      const SizedBox(height: 32),

                      // SECTION 1
                      _buildSectionTitle('1. Informasi Dasar', isDark),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Judul Laporan',
                        hint: 'Sebutkan inti masalah Anda',
                        controller: _subjectController,
                        focusNode: _subjectFocus,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => FocusScope.of(context).requestFocus(_descFocus),
                        maxLength: 100,
                      ),
                      const SizedBox(height: 24),
                      Text('Kategori', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final isSelected = _selectedCategory == cat['value'];
                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedCategory = cat['value']!);
                              _updateProgress();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                              ),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  Text(cat['icon']!, style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(cat['label']!, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isDark ? Colors.white : Colors.black87))),
                                  if (isSelected) const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      const SizedBox(height: 24),

                      // SECTION 2
                      _buildSectionTitle('2. Detail Masalah', isDark),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Deskripsi',
                        hint: 'Jelaskan masalah secara rinci...\n\n\n\n',
                        controller: _descController,
                        focusNode: _descFocus,
                        maxLines: 8,
                        minLines: 4,
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.multiline,
                        maxLength: 500,
                      ),
                      const SizedBox(height: 32),
                      Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      const SizedBox(height: 24),

                      // SECTION 3
                      _buildSectionTitle('3. Prioritas & Lampiran', isDark),
                      const SizedBox(height: 16),
                      Text('Prioritas', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
                      const SizedBox(height: 12),
                      Row(
                        children: TicketPriority.values.map((priority) {
                          final isSelected = _selectedPriority == priority;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedPriority = priority),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? priority.color.withValues(alpha: 0.15) : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: isSelected ? priority.color : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  priority.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? priority.color : (isDark ? Colors.white54 : Colors.black54),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Lampiran Foto', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
                          Text('${_imagePaths.length}/5', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildImagePicker(isDark),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
            
            // BOTTOM ACTION AREA
            Container(
              padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
                border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_progress > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Kategori: ${_selectedCategory.isEmpty ? '-' : _categories.firstWhere((e) => e['value'] == _selectedCategory)['label']} • Prioritas: ${_selectedPriority.label}',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w500),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton.primary(
                      label: 'Kirim Laporan',
                      isLoading: isLoading,
                      onPressed: _isFormValid ? _submit : null,
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
              color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.3),
            ),
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

  Widget _buildImagePicker(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          if (_imagePaths.length < 5)
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 1, style: BorderStyle.solid),
                ),
                child: const Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 24),
              ),
            ),
          if (_imagePaths.length < 5) const SizedBox(width: 12),
          ..._imagePaths.asMap().entries.map((entry) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(image: FileImage(File(entry.value)), fit: BoxFit.cover),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 4,
                    top: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(entry.key),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSuccessState(bool isDark) {
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
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 64),
              ),
            ),
            const SizedBox(height: 32),
            Text('Laporan Terkirim!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 12),
            Text(
              'Tim helpdesk kami akan segera menindaklanjuti masalah Anda.',
              style: TextStyle(fontSize: 15, color: isDark ? Colors.white70 : Colors.black54, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: AppButton.primary(
                label: 'Lihat Tiket',
                onPressed: () => context.go('/tickets'), // Adjust to actual detail route once ID is parsed well
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
