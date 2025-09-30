import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/gallery_provider.dart';
import '../widgets/gallery_app_bar.dart';
import '../widgets/gallery_stats.dart';
import '../widgets/photo_grid.dart';
import '../widgets/analysis_fab.dart';

class MainGalleryScreen extends StatefulWidget {
  const MainGalleryScreen({super.key});

  @override
  State<MainGalleryScreen> createState() => _MainGalleryScreenState();
}

class _MainGalleryScreenState extends State<MainGalleryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeGallery();
    _setupScrollListener();
  }

  void _initializeGallery() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GalleryProvider>().initialize();
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<GalleryProvider>().loadMorePhotos();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _startAnalysis() {
    final galleryProvider = context.read<GalleryProvider>();
    if (galleryProvider.allPhotos.isNotEmpty) {
      Navigator.of(context).pushNamed(
        AppRoutes.aiAnalysis,
        arguments: galleryProvider.allPhotos,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<GalleryProvider>(
        builder: (context, galleryProvider, child) {
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // App Bar
              const GalleryAppBar(),

              // Stats Card
              if (galleryProvider.state == GalleryState.loaded)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GalleryStats(
                      totalPhotos: galleryProvider.totalPhotos,
                      displayedPhotos: galleryProvider.displayedPhotos,
                    ),
                  ),
                ),

              // Content based on state
              _buildContent(galleryProvider),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<GalleryProvider>(
        builder: (context, galleryProvider, child) {
          if (galleryProvider.state == GalleryState.loaded &&
              galleryProvider.allPhotos.isNotEmpty) {
            return AnalysisFAB(onPressed: _startAnalysis);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(GalleryProvider galleryProvider) {
    switch (galleryProvider.state) {
      case GalleryState.initial:
      case GalleryState.loading:
        return const SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Fotoğraflar yükleniyor...'),
              ],
            ),
          ),
        );

      case GalleryState.permissionDenied:
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.photo_library_outlined,
                  size: 64,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Galeri Erişimi Gerekli',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fotoğraflarınızı görüntülemek için
galeri erişim izni gerekiyor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => galleryProvider.requestPermission(),
                  child: const Text('İzin Ver'),
                ),
              ],
            ),
          ),
        );

      case GalleryState.error:
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bir Hata Oluştu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  galleryProvider.errorMessage ?? 'Bilinmeyen hata',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => galleryProvider.refresh(),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        );

      case GalleryState.loaded:
        if (galleryProvider.photos.isEmpty) {
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

        return PhotoGrid(
          photos: galleryProvider.photos,
          isLoadingMore: galleryProvider.isLoadingMore,
        );
    }
  }
}
