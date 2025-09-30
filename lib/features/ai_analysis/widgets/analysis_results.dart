import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/ai_service.dart';
import '../models/analysis_result.dart';

class AnalysisResults extends StatelessWidget {
  final AnalysisResult result;
  final Map<PhotoCategory, Set<AssetEntity>> selectedPhotos;
  final Function(PhotoCategory, List<AssetEntity>) onCategoryTap;
  final Function(PhotoCategory, AssetEntity) onPhotoSelectionChanged;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;

  const AnalysisResults({
    super.key,
    required this.result,
    required this.selectedPhotos,
    required this.onCategoryTap,
    required this.onPhotoSelectionChanged,
    required this.onSelectAll,
    required this.onDeselectAll,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          _buildSummaryCard(),
          const SizedBox(height: 24),

          // Categories
          const Text(
            'Kategoriler',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 16),

          // Category cards
          _buildCategoryCard(
            category: PhotoCategory.blurry,
            photos: result.blurryPhotos,
            icon: Icons.blur_on,
            color: AppColors.blurryCategory,
            title: 'Bulanık Fotoğraflar',
            description: 'Bulanık veya odaksız fotoğraflar',
          ),
          const SizedBox(height: 12),

          _buildCategoryCard(
            category: PhotoCategory.small,
            photos: result.smallPhotos,
            icon: Icons.photo_size_select_small,
            color: AppColors.smallCategory,
            title: 'Küçük Fotoğraflar',
            description: 'Düşük çözünürlüklü fotoğraflar',
          ),
          const SizedBox(height: 12),

          _buildCategoryCard(
            category: PhotoCategory.nonPerson,
            photos: result.nonPersonPhotos,
            icon: Icons.landscape,
            color: AppColors.nonPersonCategory,
            title: 'Kişi Olmayan Fotoğraflar',
            description: 'İçinde kişi bulunmayan fotoğraflar',
          ),
          const SizedBox(height: 12),

          _buildCategoryCard(
            category: PhotoCategory.good,
            photos: result.goodPhotos,
            icon: Icons.check_circle,
            color: AppColors.success,
            title: 'İyi Fotoğraflar',
            description: 'Kaliteli ve temiz fotoğraflar',
          ),

          const SizedBox(height: 100), // Space for bottom actions
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final problematicCount = result.problematicPhotos;
    final totalCount = result.totalPhotos;
    final selectedCount = selectedPhotos.values.fold(0, (sum, set) => sum + set.length);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analiz Tamamlandı',
                        style: AppTextStyles.heading4,
                      ),
                      Text(
                        'Fotoğraflarınız başarıyla analiz edildi',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Toplam',
                    totalCount.toString(),
                    AppColors.textPrimary,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Problemli',
                    problematicCount.toString(),
                    AppColors.warning,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Seçilen',
                    selectedCount.toString(),
                    AppColors.primary,
                  ),
                ),
              ],
            ),

            if (problematicCount > 0) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$problematicCount fotoğraf temizlenmeye hazır',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.heading3.copyWith(color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required PhotoCategory category,
    required List<AssetEntity> photos,
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    final selectedCount = selectedPhotos[category]?.length ?? 0;
    final hasPhotos = photos.isNotEmpty;

    return Card(
      child: InkWell(
        onTap: hasPhotos ? () => onCategoryTap(category, photos) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTextStyles.heading4,
                          ),
                        ),
                        if (hasPhotos)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              photos.length.toString(),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTextStyles.bodyMedium,
                    ),
                    if (hasPhotos && selectedCount > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '$selectedCount fotoğraf seçildi',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow
              if (hasPhotos)
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textTertiary,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
