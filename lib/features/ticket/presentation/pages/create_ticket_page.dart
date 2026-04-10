import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/app_dimensions.dart';
import 'package:uts/core/constants/app_strings.dart';
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

  static const _priorities = [
    {'value': 'low', 'label': AppStrings.priorityLow, 'color': AppColors.priorityLow},
    {'value': 'medium', 'label': AppStrings.priorityMedium, 'color': AppColors.priorityMedium},
    {'value': 'high', 'label': AppStrings.priorityHigh, 'color': AppColors.priorityHigh},
  ];

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
          title: const Text(AppStrings.createTicket),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('INFORMASI UMUM', Icons.info_outline),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: AppStrings.ticketSubject,
                    hint: 'Contoh: Printer Rusak, Komputer Lag',
                    controller: _subjectController,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Subjek tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Kategori',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat['value'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat['label']!),
                            selected: isSelected,
                            onSelected: (_) =>
                                setState(() => _selectedCategory = cat['value']!),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildSectionHeader('DETAIL LAPORAN', Icons.description_outlined),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: AppStrings.ticketDescription,
                    hint: 'Jelaskan detail masalah Anda...',
                    controller: _descController,
                    maxLines: 4,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Deskripsi tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Prioritas',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: _priorities.map((p) {
                      final isSelected = _selectedPriority == p['value'];
                      final color = p['color'] as Color;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedPriority = p['value'] as String),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? color : AppColors.borderLight,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _getPriorityIcon(p['value'] as String),
                                  size: 16,
                                  color: isSelected ? color : Colors.grey,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  p['label'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    color: isSelected ? color : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40),
                  _buildSectionHeader('LAMPIRAN', Icons.image_outlined),
                  const SizedBox(height: 20),
                  _buildImagePicker(isDark),
                  const SizedBox(height: 48),
                  BlocBuilder<TicketBloc, TicketState>(
                    builder: (context, state) {
                      return AppButton(
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
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getPriorityIcon(String val) {
    switch (val) {
      case 'low': return Icons.keyboard_double_arrow_down_rounded;
      case 'high': return Icons.keyboard_double_arrow_up_rounded;
      default: return Icons.remove_rounded;
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
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
                    color: isDark ? const Color(0xFF1F1F23) : const Color(0xFFF1F1F4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight, width: 1),
                  ),
                  child: const Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              ..._imagePaths.asMap().entries.map((entry) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
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
        ),
      ],
    );
  }
}


