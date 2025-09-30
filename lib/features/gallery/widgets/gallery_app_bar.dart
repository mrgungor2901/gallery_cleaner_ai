import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/gallery_provider.dart';

class GalleryAppBar extends StatefulWidget {
  const GalleryAppBar({super.key});

  @override
  State<GalleryAppBar> createState() => _GalleryAppBarState();
}

class _GalleryAppBarState extends State<GalleryAppBar> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        context.read<GalleryProvider>().searchPhotos('');
      }
    });
  }

  void _onSearchChanged(String query) {
    context.read<GalleryProvider>().searchPhotos(query);
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black.withOpacity(0.1),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: _isSearching
            ? Container(
                height: 40,
                margin: const EdgeInsets.only(right: 60),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Fotoğraf ara...',
                    hintStyle: AppTextStyles.bodyMedium,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  style: AppTextStyles.bodyMedium,
                ),
              )
            : const Text(
                'Galeri',
                style: AppTextStyles.heading2,
              ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Color(0xFFF8FAFC),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _toggleSearch,
          icon: Icon(
            _isSearching ? Icons.close : Icons.search,
            color: AppColors.textPrimary,
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_vert,
            color: AppColors.textPrimary,
          ),
          onSelected: (value) {
            switch (value) {
              case 'refresh':
                context.read<GalleryProvider>().refresh();
                break;
              case 'settings':
                // Navigate to settings
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh, size: 20),
                  SizedBox(width: 12),
                  Text('Yenile'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 20),
                  SizedBox(width: 12),
                  Text('Ayarlar'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
