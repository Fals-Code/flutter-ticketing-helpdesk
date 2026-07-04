import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/features/ticket/domain/entities/ticket_attachment_entity.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/domain/services/ticket_attachment_viewer.dart';

typedef TicketAttachmentMessageCallback = void Function(
  String message, {
  bool isError,
});

class TicketAttachmentsSection extends StatefulWidget {
  final TicketEntity ticket;
  final bool isDark;
  final TicketAttachmentViewerDataSource? viewer;
  final TicketAttachmentMessageCallback onMessage;

  const TicketAttachmentsSection({
    super.key,
    required this.ticket,
    required this.isDark,
    required this.onMessage,
    this.viewer,
  });

  @override
  State<TicketAttachmentsSection> createState() =>
      _TicketAttachmentsSectionState();
}

class _TicketAttachmentsSectionState extends State<TicketAttachmentsSection> {
  late final TicketAttachmentViewerDataSource _viewer;
  final Set<String> _busyAttachmentIds = <String>{};

  @override
  void initState() {
    super.initState();
    _viewer = widget.viewer ?? GetIt.I<TicketAttachmentViewerDataSource>();
  }

  @override
  Widget build(BuildContext context) {
    final imageAttachments =
        widget.ticket.attachments.where((attachment) => attachment.isImageLike);
    final documentAttachments = widget.ticket.attachments
        .where((attachment) => !attachment.isImageLike)
        .toList(growable: false);
    final legacyImageUrls = widget.ticket.legacyCompatibleImageUrls
        .where((url) => url.trim().isNotEmpty)
        .where(
          (url) => !imageAttachments
              .any((attachment) => attachment.accessUrl == url),
        )
        .toList(growable: false);

    if (imageAttachments.isEmpty &&
        documentAttachments.isEmpty &&
        legacyImageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    final imagePreviewItems = [
      ...imageAttachments,
      ...legacyImageUrls.map(
        (url) => _LegacyImagePreviewItem(
          url: url,
          label: _fileLabelFromUrl(url),
        ),
      )
    ];
    final galleryUrls = [
      ...imageAttachments
          .where((attachment) =>
              attachment.accessUrl != null &&
              attachment.accessUrl!.trim().isNotEmpty)
          .map((attachment) => attachment.accessUrl!.trim()),
      ...legacyImageUrls,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(isDark: widget.isDark, label: 'LAMPIRAN'),
        const SizedBox(height: 14),
        if (imagePreviewItems.isNotEmpty) ...[
          _buildImageGrid(imagePreviewItems, galleryUrls),
          const SizedBox(height: 16),
        ],
        if (documentAttachments.isNotEmpty) ...[
          ...documentAttachments.map(
            (attachment) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildDocumentCard(attachment),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageGrid(
      List<Object> imagePreviewItems, List<String> galleryUrls) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 560 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: imagePreviewItems.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.92,
          ),
          itemBuilder: (context, index) {
            final item = imagePreviewItems[index];
            if (item is TicketAttachmentEntity) {
              return _buildImageAttachmentTile(item, galleryUrls);
            }
            final legacy = item as _LegacyImagePreviewItem;
            return _buildLegacyImageTile(legacy, galleryUrls);
          },
        );
      },
    );
  }

  Widget _buildImageAttachmentTile(
      TicketAttachmentEntity attachment, List<String> galleryUrls) {
    final url = attachment.accessUrl;
    final hasPreview = url != null && url.trim().isNotEmpty;
    final cardColor = widget.isDark ? AppColors.surfaceDark : Colors.white;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: hasPreview
            ? () {
                final previewUrl = attachment.accessUrl;
                if (previewUrl == null) return;
                _openImageGallery(galleryUrls, previewUrl);
              }
            : null,
        child: Ink(
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  widget.isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasPreview)
                        Image.network(
                          url,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: widget.isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : Colors.black.withValues(alpha: 0.04),
                              alignment: Alignment.center,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return _buildImagePlaceholder(
                              title: attachment.fileName,
                              subtitle: 'Pratinjau gagal dimuat',
                              icon: Icons.broken_image_outlined,
                            );
                          },
                        )
                      else
                        _buildImagePlaceholder(
                          title: attachment.fileName,
                          subtitle: 'Pratinjau tidak tersedia',
                          icon: Icons.image_not_supported_outlined,
                        ),
                      if (hasPreview)
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.48),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.zoom_in_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Lihat',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatMeta(attachment),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.isDark
                            ? Colors.white60
                            : Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegacyImageTile(
      _LegacyImagePreviewItem legacy, List<String> galleryUrls) {
    return Material(
      color: widget.isDark ? AppColors.surfaceDark : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openImageGallery(galleryUrls, legacy.url),
        child: Ink(
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  widget.isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    legacy.url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImagePlaceholder(
                        title: legacy.label,
                        subtitle: 'Pratinjau gagal dimuat',
                        icon: Icons.broken_image_outlined,
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      legacy.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lampiran gambar lama',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.isDark
                            ? Colors.white60
                            : Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCard(TicketAttachmentEntity attachment) {
    final busy = _busyAttachmentIds.contains(attachment.id);
    final cardColor = widget.isDark ? AppColors.surfaceDark : Colors.white;
    final iconColor = _iconColor(attachment);

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: busy ? null : () => _openDocumentAttachment(attachment),
        child: Ink(
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  widget.isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _iconForAttachment(attachment),
                    color: iconColor,
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
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: widget.isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatMeta(attachment),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.isDark
                              ? Colors.white60
                              : Colors.black.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (busy)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    onPressed: () => _openDocumentAttachment(attachment),
                    icon: const Icon(Icons.download_rounded),
                    tooltip: 'Buka lampiran',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      color: widget.isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.black.withValues(alpha: 0.04),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 34,
                color: widget.isDark ? Colors.white38 : Colors.black38,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: widget.isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openImageGallery(List<String> urls, String initialUrl) {
    if (urls.isEmpty) {
      return;
    }

    final initialIndex =
        urls.indexOf(initialUrl).clamp(0, urls.length - 1).toInt();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _ImageGalleryPage(
          urls: urls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Future<void> _openDocumentAttachment(
      TicketAttachmentEntity attachment) async {
    if (!mounted) return;
    if (_busyAttachmentIds.contains(attachment.id)) {
      return;
    }

    setState(() {
      _busyAttachmentIds.add(attachment.id);
    });

    final result = await _viewer.openAttachment(attachment);

    if (!mounted) return;
    setState(() {
      _busyAttachmentIds.remove(attachment.id);
    });

    if (result.status == TicketAttachmentActionStatus.opened ||
        result.status == TicketAttachmentActionStatus.busy) {
      return;
    }

    widget.onMessage(
      _messageForStatus(result.status, result.message),
      isError: true,
    );
  }

  String _messageForStatus(
      TicketAttachmentActionStatus status, String fallback) {
    return switch (status) {
      TicketAttachmentActionStatus.fileNotFound => 'File tidak ditemukan.',
      TicketAttachmentActionStatus.accessDenied => 'Akses ditolak.',
      TicketAttachmentActionStatus.offline =>
        'Koneksi internet tidak tersedia.',
      TicketAttachmentActionStatus.noAppFound =>
        'Tidak ada aplikasi pembuka yang tersedia.',
      TicketAttachmentActionStatus.failed => fallback,
      TicketAttachmentActionStatus.unsupported =>
        'Lampiran ini tidak bisa dibuka dari aplikasi.',
      TicketAttachmentActionStatus.busy => 'Lampiran sedang diproses.',
      TicketAttachmentActionStatus.opened => fallback,
    };
  }

  IconData _iconForAttachment(TicketAttachmentEntity attachment) {
    final extension = attachment.extension.trim().toLowerCase();
    return switch (extension) {
      'pdf' => Icons.picture_as_pdf_rounded,
      'txt' => Icons.description_rounded,
      'doc' || 'docx' => Icons.article_rounded,
      _ => Icons.insert_drive_file_rounded,
    };
  }

  Color _iconColor(TicketAttachmentEntity attachment) {
    final extension = attachment.extension.trim().toLowerCase();
    return switch (extension) {
      'pdf' => const Color(0xFFE53935),
      'txt' => const Color(0xFF1E88E5),
      'doc' || 'docx' => const Color(0xFF2E7D32),
      _ => const Color(0xFF546E7A),
    };
  }

  String _formatMeta(TicketAttachmentEntity attachment) {
    final parts = <String>[
      attachment.mimeType.isNotEmpty ? attachment.mimeType : 'Lampiran',
      if (attachment.sizeBytes > 0) _formatFileSize(attachment.sizeBytes),
    ];
    return parts.join(' | ');
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _fileLabelFromUrl(String url) {
    final lastSegment = url.split('?').first.split('/').last;
    return lastSegment.isEmpty ? 'Lampiran gambar' : lastSegment;
  }
}

class _LegacyImagePreviewItem {
  final String url;
  final String label;

  const _LegacyImagePreviewItem({
    required this.url,
    required this.label,
  });
}

class _SectionLabel extends StatelessWidget {
  final bool isDark;
  final String label;

  const _SectionLabel({
    required this.isDark,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white54 : Colors.black45,
        letterSpacing: 1,
      ),
    );
  }
}

class _ImageGalleryPage extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const _ImageGalleryPage({
    required this.urls,
    required this.initialIndex,
  });

  @override
  State<_ImageGalleryPage> createState() => _ImageGalleryPageState();
}

class _ImageGalleryPageState extends State<_ImageGalleryPage> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.urls.length}',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.urls.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Hero(
                tag: widget.urls[index],
                child: Image.network(
                  widget.urls[index],
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 64,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
