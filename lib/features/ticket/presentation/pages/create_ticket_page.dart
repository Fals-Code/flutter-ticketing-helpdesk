import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/app_dimensions.dart';
import 'package:uts/shared/widgets/app_button.dart';
import 'package:uts/shared/widgets/app_text_field.dart';
import 'package:uts/features/ticket/presentation/bloc/ticket_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/ticket_event.dart';
import 'package:uts/features/ticket/presentation/bloc/ticket_state.dart';

class CreateTicketPage extends StatefulWidget {
  const CreateTicketPage({super.key});

  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descController = TextEditingController();

  String _selectedPriority = 'medium';
  String _selectedCategory = 'software';
  final List<String> _imagePaths = [];
  final ImagePicker _picker = ImagePicker();

  static const _categories = [
    {'value': 'hardware', 'label': 'Hardware'},
    {'value': 'software', 'label': 'Software'},
    {'value': 'network', 'label': 'Jaringan'},
    {'value': 'account', 'label': 'Akun & Akses'},
    {'value': 'other', 'label': 'Lainnya'},
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1080,
      );
      if (image != null) {
        setState(() => _imagePaths.add(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil gambar: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() => _imagePaths.removeAt(index));
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLG)),
      ),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<TicketBloc, TicketState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.statusResolved,
            ),
          );
          context.pop();
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.priorityHigh,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: BlocBuilder<TicketBloc, TicketState>(
          builder: (context, state) {
            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Section
                        const SizedBox(height: 8),
                        const Text(
                          'Buat Laporan Baru',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Berikan detail masalah Anda agar tim kami dapat membantu dengan cepat.',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Subject Field
                        AppTextField(
                          label: 'Judul Laporan',
                          hint: 'Apa masalah yang Anda hadapi?',
                          controller: _subjectController,
                          prefixIcon: Icons.title_rounded,
                          borderRadius: 16,
                          validator: (v) => v == null || v.isEmpty ? 'Judul laporan wajib diisi' : null,
                        ),
                        const SizedBox(height: 32),

                        // Category Section
                        _buildLabel('Kategori Laporan'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _categories.map((cat) {
                            final isSelected = _selectedCategory == cat['value'];
                            return ChoiceChip(
                              label: Text(
                                cat['label']!,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.blueGrey,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _selectedCategory = cat['value']!),
                              selectedColor: AppColors.primary,
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected ? Colors.transparent : Colors.grey.withValues(alpha: 0.3),
                                ),
                              ),
                              showCheckmark: false,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),

                        // Description Field
                        AppTextField(
                          label: 'Deskripsi Masalah',
                          hint: 'Jelaskan detail kronologi atau kendala...',
                          controller: _descController,
                          maxLines: 5,
                          borderRadius: 16,
                          prefixIcon: Icons.description_rounded,
                          keyboardType: TextInputType.multiline,
                          validator: (v) => v == null || v.isEmpty ? 'Harap jelaskan deskripsi masalah' : null,
                        ),
                        const SizedBox(height: 32),

                        // Priority Section
                        _buildLabel('Tingkat Prioritas'),
                        const SizedBox(height: 12),
                        _buildPrioritySelector(),
                        const SizedBox(height: 32),

                        // Image Picker Section
                        _buildLabel('Lampiran Foto (Opsional)'),
                        const SizedBox(height: 12),
                        _buildImagePicker(isDark),

                        const SizedBox(height: 48),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            label: 'Kirim Laporan',
                            isLoading: state.isLoading,
                            onPressed: () {
                              if (!_formKey.currentState!.validate()) return;
                              context.read<TicketBloc>().add(CreateTicketRequested(
                                    title: _subjectController.text,
                                    description: _descController.text,
                                    category: _selectedCategory,
                                    priority: _selectedPriority,
                                    imagePaths: _imagePaths,
                                  ));
                            },
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                if (state.isLoading)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildPrioritySelector() {
    final List<Map<String, dynamic>> priorities = [
      {'value': 'low', 'label': 'Rendah', 'color': Colors.green},
      {'value': 'medium', 'label': 'Sedang', 'color': Colors.orange},
      {'value': 'high', 'label': 'Tinggi', 'color': Colors.red},
    ];

    return Row(
      children: priorities.map((p) {
        final isSelected = _selectedPriority == p['value'];
        final Color color = p['color'];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: p['value'] == 'high' ? 0 : 8),
            child: ChoiceChip(
              label: Container(
                width: double.infinity,
                alignment: Alignment.center,
                child: Text(
                  p['label'],
                  style: TextStyle(
                    color: isSelected ? Colors.white : color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedPriority = p['value']);
                }
              },
              selectedColor: color,
              backgroundColor: color.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isSelected ? Colors.transparent : color.withValues(alpha: 0.3)),
              ),
              showCheckmark: false,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImagePicker(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          GestureDetector(
            onTap: _showImageSourceSheet,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight, width: 1),
              ),
              child: const Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 28),
            ),
          ),
          const SizedBox(width: 12),
          ..._imagePaths.asMap().entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(right: 12),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: FileImage(File(entry.value)),
                  fit: BoxFit.cover,
                ),
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
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
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
}
