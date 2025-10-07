import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../core/constants/app_colors.dart';
import 'photo_tile.dart';

class GroupedPhotoGrid extends StatelessWidget {
  final Map<String, List<AssetEntity>> groupedPhotos;
  final String Function(String) formatDateForDisplay;

  const GroupedPhotoGrid({
    super.key,
    required this.groupedPhotos,
    required this.formatDateForDisplay,
  });

  @override
  Widget build(BuildContext context) {
    if (groupedPhotos.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_outlined,
                size: 64,
                color: AppColors.textTertiary,
              ),
              SizedBox(height: 16),
              Text(
                'Fotoğraf Bulunamadı',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Galerinizde henüz fotoğraf yok.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    // Tarihleri sırala (en yeni önce)
    final sortedDates = groupedPhotos.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final dateKey = sortedDates[index];
          final photos = groupedPhotos[dateKey]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ay başlığı - Resimdeki gibi büyük ve belirgin
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.textTertiary.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatDateForDisplay(dateKey),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${photos.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Fotoğraf grid'i - Resimdeki gibi düzenli grid
              Padding(
                padding: const EdgeInsets.all(4),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: 1, // Kare fotoğraflar
                  ),
                  itemCount: photos.length,
                  itemBuilder: (context, photoIndex) {
                    return PhotoTile(
                      photo: photos[photoIndex],
                      onTap: () =>
                          _showPhotoDetail(context, photos[photoIndex]),
                    );
                  },
                ),
              ),
            ],
          );
        },
        childCount: sortedDates.length,
      ),
    );
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
                future: _buildPhotoWidget(photo),
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
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Widget?> _buildPhotoWidget(AssetEntity photo) async {
    final file = await photo.file;
    if (file != null) {
      return Image.file(
        file,
        fit: BoxFit.contain,
      );
    }
    return null;
  }
}
