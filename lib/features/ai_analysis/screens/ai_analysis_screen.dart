import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/ai_service.dart';
import '../providers/ai_provider.dart';
import '../../gallery/providers/gallery_provider.dart';
import '../widgets/analysis_progress.dart';
import '../widgets/analysis_results.dart';

class AIAnalysisScreen extends StatefulWidget {
  const AIAnalysisScreen({super.key});

  @override
  State<AIAnalysisScreen> createState() => _AIAnalysisScreenState();
}

class _AIAnalysisScreenState extends State<AIAnalysisScreen> {
  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  void _startAnalysis() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final photos =
          ModalRoute.of(context)?.settings.arguments as List<AssetEntity>?;
      if (photos != null && photos.isNotEmpty) {
        context.read<AIProvider>().analyzePhotos(photos);
      }
    });
  }

  void _navigateToCategory(PhotoCategory category, List<AssetEntity> photos) {
    Navigator.of(context).pushNamed(
      AppRoutes.categoryResults,
      arguments: {
        'category': category,
        'photos': photos,
      },
    );
  }

  Future<void> _deleteSelectedPhotos() async {
    final aiProvider = context.read<AIProvider>();
    final galleryProvider = context.read<GalleryProvider>();

    final selectedPhotos = aiProvider.getAllSelectedPhotos();

    if (selectedPhotos.isEmpty) {
      _showMessage('Silinecek fotoğraf seçilmedi');
      return;
    }

    final confirmed = await _showDeleteConfirmation(selectedPhotos.length);
    if (!confirmed || !mounted) return;

    try {
      await galleryProvider.deletePhotos(selectedPhotos);
      if (!mounted) return;

      _showMessage('${selectedPhotos.length} fotoğraf başarıyla silindi');

      // Navigate back to gallery
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Silme işlemi sırasında hata oluştu: $e');
    }
  }

  Future<bool> _showDeleteConfirmation(int count) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fotoğrafları Sil'),
        content: Text(
          '$count fotoğraf silinecek. Bu işlem geri alınamaz. '
          'Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Analizi'),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: Consumer<AIProvider>(
        builder: (context, aiProvider, child) {
          switch (aiProvider.state) {
            case AnalysisState.idle:
              return const Center(
                child: Text('Analiz başlatılıyor...'),
              );

            case AnalysisState.analyzing:
              return AnalysisProgress(
                currentProgress: aiProvider.currentProgress,
                totalPhotos: aiProvider.totalPhotos,
                currentStep: aiProvider.currentAnalysisStep,
                progressPercentage: aiProvider.progressPercentage,
              );

            case AnalysisState.completed:
              if (aiProvider.result == null) {
                return const Center(
                  child: Text('Analiz sonucu bulunamadı'),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: AnalysisResults(
                      result: aiProvider.result!,
                      selectedPhotos: aiProvider.selectedPhotos,
                      onCategoryTap: _navigateToCategory,
                      onPhotoSelectionChanged: aiProvider.togglePhotoSelection,
                      onSelectAll: aiProvider.selectAll,
                      onDeselectAll: aiProvider.deselectAll,
                    ),
                  ),
                  _buildBottomActions(aiProvider),
                ],
              );

            case AnalysisState.error:
              return Center(
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
                      'Analiz Hatası',
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      aiProvider.errorMessage ?? 'Bilinmeyen hata',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _startAnalysis,
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              );
          }
        },
      ),
    );
  }

  Widget _buildBottomActions(AIProvider aiProvider) {
    final selectedCount = aiProvider.totalSelectedCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selection info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$selectedCount fotoğraf seçildi',
                  style: AppTextStyles.bodyLarge,
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: aiProvider.selectAll,
                      child: const Text('Tümünü Seç'),
                    ),
                    TextButton(
                      onPressed: aiProvider.deselectAll,
                      child: const Text('Temizle'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('İptal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: selectedCount > 0 ? _deleteSelectedPhotos : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    child: Text('Sil ($selectedCount)'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
