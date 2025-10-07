import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class GalleryStats extends StatelessWidget {
  final int totalPhotos;
  final int totalVideos;
  final int displayedPhotos;
  final VoidCallback? onPhotosTap;
  final VoidCallback? onVideosTap;
  final VoidCallback? onAllTap;
  final bool isPhotosSelected;
  final bool isVideosSelected;

  const GalleryStats({
    super.key,
    required this.totalPhotos,
    required this.totalVideos,
    required this.displayedPhotos,
    this.onPhotosTap,
    this.onVideosTap,
    this.onAllTap,
    this.isPhotosSelected = false,
    this.isVideosSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.photo_library,
                label: 'Toplam Fotoğraf',
                value: totalPhotos.toString(),
                color: AppColors.primary,
                onTap: onPhotosTap,
                isSelected: isPhotosSelected,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: AppColors.surfaceVariant,
            ),
            Expanded(
              child: _buildStatItem(
                icon: Icons.videocam,
                label: 'Toplam Video',
                value: totalVideos.toString(),
                color: AppColors.secondary,
                onTap: onVideosTap,
                isSelected: isVideosSelected,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: AppColors.surfaceVariant,
            ),
            Expanded(
              child: _buildStatItem(
                icon: Icons.visibility,
                label: 'Görüntülenen',
                value: displayedPhotos.toString(),
                color: AppColors.info,
                onTap: onAllTap,
                isSelected: !isPhotosSelected && !isVideosSelected,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: color, width: 2) : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.heading3.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
