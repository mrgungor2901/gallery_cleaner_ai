import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/gallery_service.dart';

class PhotoTile extends StatefulWidget {
  final AssetEntity photo;
  final VoidCallback? onTap;
  final bool isSelected;
  final VoidCallback? onSelectionChanged;

  const PhotoTile({
    super.key,
    required this.photo,
    this.onTap,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  @override
  State<PhotoTile> createState() => _PhotoTileState();
}

class _PhotoTileState extends State<PhotoTile> {
  Widget? _thumbnailWidget;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    try {
      final thumbnailData = await GalleryService.getPhotoThumbnail(widget.photo);

      if (thumbnailData != null && mounted) {
        setState(() {
          _thumbnailWidget = Image.memory(
            thumbnailData,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: _calculateHeight(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: widget.isSelected
              ? Border.all(color: AppColors.primary, width: 3)
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail or placeholder
              _buildContent(),

              // Selection overlay
              if (widget.isSelected)
                Container(
                  color: AppColors.primary.withOpacity(0.3),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),

              // Selection button
              if (widget.onSelectionChanged != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: widget.onSelectionChanged,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: widget.isSelected
                            ? AppColors.primary
                            : Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.isSelected
                              ? AppColors.primary
                              : AppColors.textTertiary,
                          width: 2,
                        ),
                      ),
                      child: widget.isSelected
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Container(
        color: AppColors.surfaceVariant,
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_hasError || _thumbnailWidget == null) {
      return Container(
        color: AppColors.surfaceVariant,
        child: const Center(
          child: Icon(
            Icons.broken_image,
            color: AppColors.textTertiary,
            size: 32,
          ),
        ),
      );
    }

    return _thumbnailWidget!;
  }

  double _calculateHeight() {
    // Create varied heights for masonry effect
    final aspectRatio = widget.photo.width / widget.photo.height;

    if (aspectRatio > 1.5) {
      return 80; // Wide photos
    } else if (aspectRatio < 0.7) {
      return 160; // Tall photos
    } else {
      return 120; // Square-ish photos
    }
  }
}
