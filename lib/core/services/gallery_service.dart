import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';

class GalleryService {
  static Future<List<AssetEntity>> getAllPhotos() async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );

    if (albums.isEmpty) return [];

    final recentAlbum = albums.first;
    final photos = await recentAlbum.getAssetListPaged(
      page: 0,
      size: 1000, // Adjust based on needs
    );

    return photos;
  }

  static Future<List<AssetEntity>> getPhotosWithPagination({
    required int page,
    required int pageSize,
  }) async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );

    if (albums.isEmpty) return [];

    final recentAlbum = albums.first;
    final photos = await recentAlbum.getAssetListPaged(
      page: page,
      size: pageSize,
    );

    return photos;
  }

  static Future<Uint8List?> getPhotoThumbnail(AssetEntity asset) async {
    return await asset.thumbnailDataWithSize(
      const ThumbnailSize(200, 200),
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
      return false;
    }
  }

  static Future<bool> deletePhotos(List<AssetEntity> assets) async {
    try {
      final ids = assets.map((asset) => asset.id).toList();
      final result = await PhotoManager.editor.deleteWithIds(ids);
      return result.length == assets.length;
    } catch (e) {
      return false;
    }
  }
}
