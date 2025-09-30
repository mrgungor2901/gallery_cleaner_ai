import 'package:photo_manager/photo_manager.dart';
import '../../../core/services/ai_service.dart';

class AnalysisResult {
  final List<AssetEntity> blurryPhotos;
  final List<AssetEntity> smallPhotos;
  final List<AssetEntity> nonPersonPhotos;
  final List<AssetEntity> goodPhotos;
  final DateTime analyzedAt;

  AnalysisResult({
    required this.blurryPhotos,
    required this.smallPhotos,
    required this.nonPersonPhotos,
    required this.goodPhotos,
    required this.analyzedAt,
  });

  factory AnalysisResult.fromCategoryMap(
    Map<PhotoCategory, List<AssetEntity>> categoryMap,
  ) {
    return AnalysisResult(
      blurryPhotos: categoryMap[PhotoCategory.blurry] ?? [],
      smallPhotos: categoryMap[PhotoCategory.small] ?? [],
      nonPersonPhotos: categoryMap[PhotoCategory.nonPerson] ?? [],
      goodPhotos: categoryMap[PhotoCategory.good] ?? [],
      analyzedAt: DateTime.now(),
    );
  }

  int get totalPhotos =>
      blurryPhotos.length + smallPhotos.length + nonPersonPhotos.length + goodPhotos.length;

  int get problematicPhotos =>
      blurryPhotos.length + smallPhotos.length + nonPersonPhotos.length;

  double get problematicPercentage =>
      totalPhotos > 0 ? (problematicPhotos / totalPhotos) * 100 : 0;

  Map<String, dynamic> toJson() => {
        'blurryCount': blurryPhotos.length,
        'smallCount': smallPhotos.length,
        'nonPersonCount': nonPersonPhotos.length,
        'goodCount': goodPhotos.length,
        'totalCount': totalPhotos,
        'analyzedAt': analyzedAt.toIso8601String(),
      };

  // Get category by type
  List<AssetEntity> getPhotosByCategory(PhotoCategory category) {
    switch (category) {
      case PhotoCategory.blurry:
        return blurryPhotos;
      case PhotoCategory.small:
        return smallPhotos;
      case PhotoCategory.nonPerson:
        return nonPersonPhotos;
      case PhotoCategory.good:
        return goodPhotos;
    }
  }

  // Get category name in Turkish
  String getCategoryName(PhotoCategory category) {
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

  // Get category description
  String getCategoryDescription(PhotoCategory category) {
    switch (category) {
      case PhotoCategory.blurry:
        return 'Bulanık veya odaksız fotoğraflar';
      case PhotoCategory.small:
        return 'Düşük çözünürlüklü küçük fotoğraflar';
      case PhotoCategory.nonPerson:
        return 'İçinde kişi bulunmayan fotoğraflar';
      case PhotoCategory.good:
        return 'Kaliteli ve temiz fotoğraflar';
    }
  }
}
