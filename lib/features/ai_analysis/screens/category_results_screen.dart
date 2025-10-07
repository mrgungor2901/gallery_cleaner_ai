import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/ai_service.dart';
import '../providers/ai_provider.dart';
import '../../gallery/widgets/photo_tile.dart';

class CategoryResultsScreen extends StatelessWidget {
  final PhotoCategory category;
  final List<AssetEntity> photos;

  const CategoryResultsScreen({
    super.key,
    required this.category,
    required this.photos,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getCategoryTitle(category)),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          Consumer<AIProvider>(
            builder: (context, aiProvider, child) {
              final selectedCount = aiProvider.selectedPhotos[category]?.length ?? 0;
              final allSelected = selectedCount == photos.length;

              return TextButton(
                onPressed: () {
                  if (allSelected) {
                    aiProvider.deselectAllInCategory(category);
                  } else {
                    aiProvider.selectAllInCategory(category);
                  }
                },
                child: Text(allSelected ? 'Temizle' : 'Tümünü Seç'),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _getCategoryColor(category).withValues(alpha: 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getCategoryIcon(category),
                      color: _getCategoryColor(category),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getCategoryTitle(category),
                            style: AppTextStyles.heading4,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getCategoryDescription(category),
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Consumer<AIProvider>(
                  builder: (context, aiProvider, child) {
                    final selectedCount = aiProvider.selectedPhotos[category]?.length ?? 0;
                    return Text(
                      '${photos.length} fotoğraf bulundu • $selectedCount seçildi',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _getCategoryColor(category),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Photos grid
          Expanded(
            child: photos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getCategoryIcon(category),
                          size: 64,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Bu kategoride fotoğraf bulunamadı',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : Consumer<AIProvider>(
                    builder: (context, aiProvider, child) {
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                        itemCount: photos.length,
                        itemBuilder: (context, index) {
                          final photo = photos[index];
                          final isSelected = aiProvider.isPhotoSelected(category, photo);

                          return PhotoTile(
                            photo: photo,
                            isSelected: isSelected,
                            onSelectionChanged: () {
                              aiProvider.togglePhotoSelection(category, photo);
                            },
                            onTap: () => _showPhotoDetail(context, photo),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _getCategoryTitle(PhotoCategory category) {
    switch (category) {
      case PhotoCategory.blurry:
        return 'Bulanık Fotoğraflar';
      case PhotoCategory.small:
        return 'Küçük Fotoğraflar';
      case PhotoCategory.nonPerson:
        return 'Kişi Olmayan Fotoğraflar';
      case PhotoCategory.good:
        return 'İyi Fotoğraflar';
    }
  }

  String _getCategoryDescription(PhotoCategory category) {
    switch (category) {
      case PhotoCategory.blurry:
        return 'Bulanık veya odaksız olarak tespit edilen fotoğraflar';
      case PhotoCategory.small:
        return 'Düşük çözünürlüklü veya küçük boyutlu fotoğraflar';
      case PhotoCategory.nonPerson:
        return 'İçinde kişi bulunmayan fotoğraflar';
      case PhotoCategory.good:
        return 'Kaliteli ve temiz fotoğraflar';
    }
  }

  IconData _getCategoryIcon(PhotoCategory category) {
    switch (category) {
      case PhotoCategory.blurry:
        return Icons.blur_on;
      case PhotoCategory.small:
        return Icons.photo_size_select_small;
      case PhotoCategory.nonPerson:
        return Icons.landscape;
      case PhotoCategory.good:
        return Icons.check_circle;
    }
  }

  Color _getCategoryColor(PhotoCategory category) {
    switch (category) {
      case PhotoCategory.blurry:
        return AppColors.blurryCategory;
      case PhotoCategory.small:
        return AppColors.smallCategory;
      case PhotoCategory.nonPerson:
        return AppColors.nonPersonCategory;
      case PhotoCategory.good:
        return AppColors.success;
    }
  }

  void _showPhotoDetail(BuildContext context, AssetEntity photo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: FutureBuilder<Widget?>(
                future: _buildFullImage(photo),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return snapshot.data!;
                  }
                  return const CircularProgressIndicator();
                },
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Widget?> _buildFullImage(AssetEntity photo) async {
    final data = await photo.originBytes;
    if (data != null) {
      return Image.memory(
        data,
        fit: BoxFit.contain,
      );
    }
    return null;
  }
}
