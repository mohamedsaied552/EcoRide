import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:zakzouka/l10n/app_localizations.dart';

class IdUploadCard extends StatelessWidget {
  const IdUploadCard({
    required this.imageBytes,
    required this.fileName,
    required this.onCameraTap,
    required this.onGalleryTap,
    required this.onClear,
    this.errorText,
    super.key,
  });

  final Uint8List? imageBytes;
  final String? fileName;
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;
  final VoidCallback onClear;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasImage = imageBytes != null && imageBytes!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: errorText == null
                  ? const Color(0xFFE5E7EB)
                  : const Color(0xFFEF4444),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasImage
                    ? Image.memory(
                        imageBytes!,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (context, error, stackTrace) {
                          return _UploadPlaceholder(
                            icon: Icons.broken_image_outlined,
                            title: l10n.unablePreviewImage,
                            subtitle: l10n.tryDifferentPhoto,
                          );
                        },
                      )
                    : _UploadPlaceholder(
                        icon: Icons.badge_outlined,
                        title: l10n.uploadNationalId,
                        subtitle: l10n.uploadIdHint,
                      ),
              ),
              const SizedBox(height: 16),
              if (fileName != null)
                Text(
                  fileName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF111827),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              if (fileName != null) const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCameraTap,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: Text(l10n.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onGalleryTap,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(l10n.gallery),
                    ),
                  ),
                ],
              ),
              if (hasImage) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.removeAndReupload),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 10),
          Text(
            errorText!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFDC2626),
                ),
          ),
        ],
      ],
    );
  }
}

class _UploadPlaceholder extends StatelessWidget {
  const _UploadPlaceholder({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0x141FAE6C),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 34, color: const Color(0xFF1FAE6C)),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF111827),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
