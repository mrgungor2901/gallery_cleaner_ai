import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class GalleryStats extends StatelessWidget {
  final int totalPhotos;
  final int displayedPhotos;

  const GalleryStats({
    super.key,
    required this.totalPhotos,
    required this.displayedPhotos,
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
                color: AppColors.secondary,
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
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.heading3.copyWith(color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
