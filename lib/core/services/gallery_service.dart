import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryService {
  // Medya sayılarını al (sadece toplam sayı - çok hızlı!)
  static Future<Map<String, int>> getMediaCount() async {
    try {
      final photoAlbums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
      );

      final videoAlbums = await PhotoManager.getAssetPathList(
        type: RequestType.video,
        onlyAll: true,
      );

      int photoCount = 0;
      int videoCount = 0;

      if (photoAlbums.isNotEmpty) {
        photoCount = await photoAlbums.first.assetCountAsync;
      }

      if (videoAlbums.isNotEmpty) {
        videoCount = await videoAlbums.first.assetCountAsync;
      }

      debugPrint(
          'Gallery scan completed - Photos: $photoCount, Videos: $videoCount');

      return {
        'photos': photoCount,
        'videos': videoCount,
        'total': photoCount + videoCount,
      };
    } catch (e) {
      debugPrint('Error getting media count: $e');
      return {
        'photos': 0,
        'videos': 0,
        'total': 0,
      };
    }
  }

  // Sayfalama ile tüm medyayı yükle (fotoğraf + video)
  static Future<List<AssetEntity>> getPhotosWithPagination({
    required int page,
    required int pageSize,
  }) async {
    try {
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.all, // Hem fotoğraf hem video
        onlyAll: true,
      );

      if (albums.isEmpty) return [];

      final recentAlbum = albums.first;
      final media = await recentAlbum.getAssetListPaged(
        page: page,
        size: pageSize,
      );

      if (media.isNotEmpty) {
        final photoCount =
            media.where((asset) => asset.type == AssetType.image).length;
        final videoCount =
            media.where((asset) => asset.type == AssetType.video).length;
        debugPrint(
            'GalleryService: Page $page loaded $photoCount photos, $videoCount videos');
      }

      return media;
    } catch (e) {
      debugPrint('Error getting media with pagination: $e');
      return [];
    }
  }

  // Tüm medyayı al (sadece gerektiğinde kullan - YAVAŞ!)
  static Future<List<AssetEntity>> getAllPhotos() async {
    try {
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.all, // Hem fotoğraf hem video
        onlyAll: true,
      );

      if (albums.isEmpty) return [];

      final recentAlbum = albums.first;
      final totalCount = await recentAlbum.assetCountAsync;

      debugPrint('GalleryService: Loading ALL $totalCount media items...');

      final media = await recentAlbum.getAssetListPaged(
        page: 0,
        size: totalCount,
      );

      final photoCount =
          media.where((asset) => asset.type == AssetType.image).length;
      final videoCount =
          media.where((asset) => asset.type == AssetType.video).length;
      debugPrint(
          'GalleryService: Retrieved $photoCount photos, $videoCount videos');
      return media;
    } catch (e) {
      debugPrint('Error getting all photos: $e');
      return [];
    }
  }

  static Future<Uint8List?> getPhotoThumbnail(AssetEntity asset) async {
    return await asset.thumbnailDataWithSize(
      const ThumbnailSize(100, 100), // Küçük thumbnail - çok hızlı
    );
  }

  static Future<Uint8List?> getPhotoData(AssetEntity asset) async {
    return await asset.originBytes;
  }

  static Future<bool> deletePhoto(AssetEntity asset) async {
    try {
      final result = await PhotoManager.editor.deleteWithIds([asset.id]);
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('Error deleting photo: $e');
      return false;
    }
  }

  static Future<bool> deletePhotos(List<AssetEntity> assets) async {
    try {
      final ids = assets.map((asset) => asset.id).toList();
      final result = await PhotoManager.editor.deleteWithIds(ids);
      return result.length == assets.length;
    } catch (e) {
      debugPrint('Error deleting photos: $e');
      return false;
    }
  }
}
