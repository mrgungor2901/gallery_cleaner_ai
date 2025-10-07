import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../core/constants/app_colors.dart';

class MonthlyGroupCard extends StatelessWidget {
  final String monthKey;
  final List<AssetEntity> photos;
  final String displayMonth;
  final VoidCallback onTap;

  const MonthlyGroupCard({
    super.key,
    required this.monthKey,
    required this.photos,
    required this.displayMonth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final photoCount =
        photos.where((asset) => asset.type == AssetType.image).length;
    final videoCount =
        photos.where((asset) => asset.type == AssetType.video).length;

    String mediaText;
    if (photoCount > 0 && videoCount > 0) {
      mediaText = '$photoCount fotoğraf, $videoCount video';
    } else if (videoCount > 0) {
      mediaText = '$videoCount video';
    } else {
      mediaText = '$photoCount fotoğraf';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildThumbnail(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayMonth,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mediaText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (photos.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.photo_library_outlined,
          size: 32,
          color: AppColors.textTertiary,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          children: [
            FutureBuilder<Widget>(
              future: _buildMediaWidget(photos.first),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
                  return snapshot.data!;
                }
                return Container(
                  color: AppColors.surfaceVariant,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
            ),
            // Video ikonu göster
            if (photos.first.type == AssetType.video)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<Widget> _buildMediaWidget(AssetEntity asset) async {
    // Daha küçük thumbnail - çok daha hızlı!
    final thumbnailData = await asset.thumbnailDataWithSize(
      const ThumbnailSize(100, 100), // 200'den 100'e düşürdük
    );

    if (thumbnailData != null) {
      return Image.memory(
        thumbnailData,
        fit: BoxFit.cover,
        width: 80,
        height: 80,
        gaplessPlayback: true, // Daha akıcı geçiş
      );
    }

    return Container(
      color: AppColors.surfaceVariant,
      child: const Icon(
        Icons.broken_image_outlined,
        color: AppColors.textTertiary,
      ),
    );
  }
}
