import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  // Keys
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyPermissionGranted = 'permission_granted';
  static const String _keyFirstLaunch = 'first_launch';

  // Cache keys - yeni!
  static const String _keyPhotoCount = 'cached_photo_count';
  static const String _keyVideoCount = 'cached_video_count';
  static const String _keyLastScanTime = 'last_scan_time';
  static const String _keyGalleryScanned = 'gallery_scanned';

  // Onboarding
  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  static Future<void> setOnboardingCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingCompleted, value);
  }

  // Permission
  static Future<bool> isPermissionGranted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPermissionGranted) ?? false;
  }

  static Future<void> setPermissionGranted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPermissionGranted, value);
  }

  // First Launch
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFirstLaunch) ?? true;
  }

  static Future<void> setFirstLaunch(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstLaunch, value);
  }

  // Gallery Cache - YENİ!
  static Future<bool> isGalleryScanned() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyGalleryScanned) ?? false;
  }

  static Future<void> setGalleryScanned(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyGalleryScanned, value);
  }

  static Future<Map<String, int>> getCachedMediaCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final photoCount = prefs.getInt(_keyPhotoCount) ?? 0;
    final videoCount = prefs.getInt(_keyVideoCount) ?? 0;
    return {
      'photos': photoCount,
      'videos': videoCount,
      'total': photoCount + videoCount,
    };
  }

  static Future<void> setCachedMediaCounts({
    required int photoCount,
    required int videoCount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPhotoCount, photoCount);
    await prefs.setInt(_keyVideoCount, videoCount);
    await prefs.setInt(_keyLastScanTime, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<DateTime?> getLastScanTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_keyLastScanTime);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  // Fotoğraf yükleme durumunu kaydet - YENİ!
  static Future<void> setPhotosLoaded(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('photos_loaded', value);
  }

  static Future<bool> arePhotosLoaded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('photos_loaded') ?? false;
  }

  // Medya sayılarını cache'den al - YENİ!
  static Future<int> getCachedPhotoCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyPhotoCount) ?? 0;
  }

  static Future<int> getCachedVideoCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyVideoCount) ?? 0;
  }

  static Future<int> getCachedTotalMediaCount() async {
    final photoCount = await getCachedPhotoCount();
    final videoCount = await getCachedVideoCount();
    return photoCount + videoCount;
  }

  // Medya sayılarını cache'e kaydet - YENİ!
  static Future<void> setCachedPhotoCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPhotoCount, count);
  }

  static Future<void> setCachedVideoCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyVideoCount, count);
  }

  static Future<void> setCachedTotalMediaCount(int count) async {
    // Bu metod sadece uyumluluk için - aslında photo + video toplamı
    // Gerçek değerler setCachedPhotoCount ve setCachedVideoCount ile kaydedilir
  }

  static Future<void> setLastScanTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastScanTime, time.millisecondsSinceEpoch);
  }

  // Clear all (for testing)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
