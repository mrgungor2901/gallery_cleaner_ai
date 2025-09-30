import 'dart:typed_data';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';

enum PhotoCategory {
  blurry,
  small,
  nonPerson,
  good,
}

class AIService {
  // Blurry detection using Laplacian variance
  static Future<bool> isBlurry(Uint8List imageData) async {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) return false;

      // Convert to grayscale
      final grayscale = img.grayscale(image);

      // Apply Laplacian filter
      final laplacian = _applyLaplacian(grayscale);

      // Calculate variance
      final variance = _calculateVariance(laplacian);

      // Threshold for blur detection (adjust based on testing)
      return variance < 100;
    } catch (e) {
      return false;
    }
  }

  // Small image detection
  static Future<bool> isSmall(AssetEntity asset) async {
    try {
      final width = asset.width;
      final height = asset.height;

      // Consider image small if either dimension is less than 500px
      // or total pixels less than 250,000 (500x500)
      return width < 500 || height < 500 || (width * height) < 250000;
    } catch (e) {
      return false;
    }
  }

  // Simple person detection (placeholder - in real app, use ML model)
  static Future<bool> hasNoPerson(Uint8List imageData) async {
    try {
      // This is a placeholder implementation
      // In a real app, you would use a person detection ML model
      // For now, we'll use a simple heuristic based on image properties

      final image = img.decodeImage(imageData);
      if (image == null) return true;

      // Simple heuristic: check for skin-tone colors
      final skinTonePixels = _countSkinTonePixels(image);
      final totalPixels = image.width * image.height;
      final skinToneRatio = skinTonePixels / totalPixels;

      // If less than 5% skin tone pixels, likely no person
      return skinToneRatio < 0.05;
    } catch (e) {
      return true;
    }
  }

  // Batch analysis
  static Future<Map<PhotoCategory, List<AssetEntity>>> analyzePhotos(
    List<AssetEntity> photos,
    Function(int, int) onProgress,
  ) async {
    final results = <PhotoCategory, List<AssetEntity>>{
      PhotoCategory.blurry: [],
      PhotoCategory.small: [],
      PhotoCategory.nonPerson: [],
      PhotoCategory.good: [],
    };

    for (int i = 0; i < photos.length; i++) {
      final photo = photos[i];
      onProgress(i + 1, photos.length);

      try {
        // Check if small first (fastest check)
        if (await isSmall(photo)) {
          results[PhotoCategory.small]!.add(photo);
          continue;
        }

        // Get image data for other checks
        final imageData = await photo.originBytes;
        if (imageData == null) continue;

        // Check if blurry
        if (await isBlurry(imageData)) {
          results[PhotoCategory.blurry]!.add(photo);
          continue;
        }

        // Check if has no person
        if (await hasNoPerson(imageData)) {
          results[PhotoCategory.nonPerson]!.add(photo);
          continue;
        }

        // If none of the above, it's a good photo
        results[PhotoCategory.good]!.add(photo);
      } catch (e) {
        // If error occurs, consider it a good photo
        results[PhotoCategory.good]!.add(photo);
      }
    }

    return results;
  }

  // Helper methods
  static img.Image _applyLaplacian(img.Image image) {
    final result = img.Image(width: image.width, height: image.height);

    // Laplacian kernel
    final kernel = [
      [0, -1, 0],
      [-1, 4, -1],
      [0, -1, 0],
    ];

    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        int sum = 0;

        for (int ky = 0; ky < 3; ky++) {
          for (int kx = 0; kx < 3; kx++) {
            final pixel = image.getPixel(x + kx - 1, y + ky - 1);
            final gray = img.getLuminance(pixel);
            sum += (gray * kernel[ky][kx]).round();
          }
        }

        sum = math.max(0, math.min(255, sum));
        result.setPixel(x, y, img.ColorRgb8(sum, sum, sum));
      }
    }

    return result;
  }

  static double _calculateVariance(img.Image image) {
    double sum = 0;
    double sumSquared = 0;
    int count = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final gray = img.getLuminance(pixel).toDouble();
        sum += gray;
        sumSquared += gray * gray;
        count++;
      }
    }

    final mean = sum / count;
    final variance = (sumSquared / count) - (mean * mean);
    return variance;
  }

  static int _countSkinTonePixels(img.Image image) {
    int skinPixels = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;

        // Simple skin tone detection
        if (_isSkinTone(r.toInt(), g.toInt(), b.toInt())) {
          skinPixels++;
        }
      }
    }

    return skinPixels;
  }

  static bool _isSkinTone(int r, int g, int b) {
    // Simple skin tone detection heuristic
    return r > 95 && g > 40 && b > 20 &&
           r > g && r > b &&
           r - g > 15 &&
           (r - g).abs() > 15;
  }
}
