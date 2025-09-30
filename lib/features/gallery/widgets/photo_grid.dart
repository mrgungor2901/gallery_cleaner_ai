import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../core/constants/app_colors.dart';
import 'photo_tile.dart';

class PhotoGrid extends StatelessWidget {
  final List<AssetEntity> photos;
  final bool isLoadingMore;

  const PhotoGrid({
    super.key,
    required this.photos,
    this.isLoadingMore = false,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childCount: photos.length + (isLoadingMore ? 3 : 0),
        itemBuilder: (context, index) {
          if (index >= photos.length) {
            // Loading placeholder
            return Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            );
          }

          return PhotoTile(
            photo: photos[index],
            onTap: () => _showPhotoDetail(context, photos[index]),
          );
        },
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
