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
              backgroundColor: AppColors.statusCritical,
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
            padding: const EdgeInsets.all(AppDimensions.spaceLG),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    label: AppStrings.ticketSubject,
                    hint: 'Jelaskan masalah secara singkat',
                    controller: _subjectController,
                    prefixIcon: Icons.title,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Subjek tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: AppDimensions.spaceLG),

                  // Category
                  Text(AppStrings.ticketCategory,
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: AppDimensions.spaceSM),
                  Wrap(
                    spacing: AppDimensions.spaceSM,
                    runSpacing: AppDimensions.spaceSM,
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat['value'];
                      return FilterChip(
                        label: Text(cat['label']!),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = cat['value']!),
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.primary,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppDimensions.spaceLG),

                  // Priority
                  Text(AppStrings.ticketPriority,
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: AppDimensions.spaceSM),
                  Row(
                    children: _priorities.map((p) {
                      final isSelected = _selectedPriority == p['value'];
                      final color = p['color'] as Color;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedPriority = p['value'] as String),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withValues(alpha: 0.12)
                                  : (isDark ? AppColors.cardDark : AppColors.cardLight),
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusMD),
                              border: Border.all(
                                color: isSelected ? color : (isDark ? AppColors.borderDark : AppColors.borderLight),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              p['label'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                color: isSelected ? color : null,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppDimensions.spaceLG),

                  AppTextField(
                    label: AppStrings.ticketDescription,
                    hint: 'Deskripsikan masalah secara detail...',
                    controller: _descController,
                    maxLines: 5,
                    prefixIcon: Icons.description_outlined,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Deskripsi tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: AppDimensions.spaceLG),

                  // Image Upload Section
                  Text('Lampiran Foto (Opsional)',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: AppDimensions.spaceSM),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _showImageSourceSheet,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.cardDark : AppColors.cardLight,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                              border: Border.all(
                                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: const Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceSM),
                        ...List.generate(_imagePaths.length, (index) {
                          return Container(
                            margin: const EdgeInsets.only(right: AppDimensions.spaceSM),
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                              image: DecorationImage(
                                image: FileImage(File(_imagePaths[index])),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: AppColors.statusCritical,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 14, color: Colors.white),
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
                  const SizedBox(height: AppDimensions.spaceXXL),

                  BlocBuilder<TicketBloc, TicketState>(
                    builder: (context, state) {
                      return AppButton(
                        label: 'Kirim Laporan',
                        isLoading: state.isLoading,
                        icon: Icons.send_rounded,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

