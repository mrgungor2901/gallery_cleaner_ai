import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../core/services/gallery_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/preferences_service.dart';

enum GalleryState {
  initial,
  loading,
  loaded,
  error,
  permissionDenied,
  scanning,
  scanned,
}

enum MediaTypeFilter {
  all,
  photosOnly,
  videosOnly,
}

class GalleryProvider extends ChangeNotifier {
  GalleryState _state = GalleryState.initial;
  List<AssetEntity> _allPhotos = [];
  List<AssetEntity> _filteredPhotos = [];
  String _searchQuery = '';
  MediaTypeFilter _mediaTypeFilter = MediaTypeFilter.all;
  bool _hasPermission = false;
  String? _errorMessage;

  // Pagination
  int _currentPage = 0;
  final int _pageSize = 500;
  bool _hasMorePhotos = false;
  bool _isLoadingMore = false;
  bool _isLoadingInBackground = false;

  // Media counts - displayed (animated/doubled)
  int _displayPhotoCount = 0;
  int _displayVideoCount = 0;
  int _displayTotalCount = 0;

  // Media counts - actual (real values)
  int _actualPhotoCount = 0;
  int _actualVideoCount = 0;
  int _actualTotalCount = 0;

  // Monthly grouping
  Map<String, List<AssetEntity>> _groupedPhotos = {};

  // Getters
  GalleryState get state => _state;
  List<AssetEntity> get photos => _filteredPhotos;
  List<AssetEntity> get allPhotos => _allPhotos;
  String get searchQuery => _searchQuery;
  MediaTypeFilter get mediaTypeFilter => _mediaTypeFilter;
  bool get hasPermission => _hasPermission;
  String? get errorMessage => _errorMessage;
  bool get hasMorePhotos => _hasMorePhotos;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoadingInBackground => _isLoadingInBackground;

  // Display counts (shown to user during scanning)
  int get photoCount => _displayPhotoCount;
  int get videoCount => _displayVideoCount;
  int get totalMediaCount => _displayTotalCount;

  int get totalPhotos => _allPhotos.length;
  int get displayedPhotos => _filteredPhotos.length;

  Map<String, List<AssetEntity>> get groupedPhotos => _groupedPhotos;

  Future<void> initialize() async {
    _setState(GalleryState.loading);

    try {
      _hasPermission = await PermissionService.checkGalleryPermission();

      if (!_hasPermission) {
        _setState(GalleryState.permissionDenied);
        return;
      }

      // Quick start: Load first 100 photos
      debugPrint('GalleryProvider: Quick loading first 100 photos...');
      final firstBatch =
          await GalleryService.getPhotosWithPagination(page: 0, pageSize: 100);
      _allPhotos = firstBatch;
      _applyFilter();
      _setState(GalleryState.loaded);

      debugPrint(
          'GalleryProvider: ✅ First 100 photos loaded! Loading rest in background...');

      // Load rest in background
      _loadRemainingPhotosInBackground();
    } catch (e) {
      _errorMessage = e.toString();
      _setState(GalleryState.error);
      debugPrint('GalleryProvider: Error loading photos: $e');
    }
  }

  Future<void> requestPermission() async {
    try {
      _hasPermission = await PermissionService.requestGalleryPermission();

      if (_hasPermission) {
        // Don't load photos here, just set permission status
        _setState(GalleryState.initial);
        debugPrint('GalleryProvider: Permission granted, ready to load photos');
      } else {
        _setState(GalleryState.permissionDenied);
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setState(GalleryState.error);
    }
  }

  Future<void> _loadPhotos() async {
    try {
      final photos = await GalleryService.getPhotosWithPagination(
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (_currentPage == 0) {
        _allPhotos = photos;
      } else {
        _allPhotos.addAll(photos);
      }

      _hasMorePhotos = photos.length == _pageSize;
      _applyFilter();
    } catch (e) {
      throw Exception('Fotoğraflar yüklenirken hata oluştu: $e');
    }
  }

  Future<void> loadMorePhotos() async {
    // No longer needed - all photos are loaded in background
    return;
  }

  void searchPhotos(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilter();
  }

  void setMediaTypeFilter(MediaTypeFilter filter) {
    _mediaTypeFilter = filter;
    _applyFilter();
  }

  void _applyFilter() {
    List<AssetEntity> filtered = List.from(_allPhotos);

    // Apply media type filter
    switch (_mediaTypeFilter) {
      case MediaTypeFilter.photosOnly:
        filtered =
            filtered.where((asset) => asset.type == AssetType.image).toList();
        break;
      case MediaTypeFilter.videosOnly:
        filtered =
            filtered.where((asset) => asset.type == AssetType.video).toList();
        break;
      case MediaTypeFilter.all:
        // No filtering needed
        break;
    }

    // Apply search filter (if needed in the future)
    if (_searchQuery.isNotEmpty) {
      // For now, we can't search by filename easily with photo_manager
      // This is a placeholder for future implementation
    }

    _filteredPhotos = filtered;
    _groupPhotosByMonth();
    notifyListeners();
  }

  // Group photos by month
  void _groupPhotosByMonth() {
    _groupedPhotos.clear();

    for (final photo in _filteredPhotos) {
      final date = photo.createDateTime;
      // Format: YYYY-MM (e.g., "2024-01")
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';

      if (_groupedPhotos.containsKey(monthKey)) {
        _groupedPhotos[monthKey]!.add(photo);
      } else {
        _groupedPhotos[monthKey] = [photo];
      }
    }
  }

  // Format month key for display (e.g., "2024-01" -> "Ocak 2024")
  String formatMonthForDisplay(String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length != 2) return monthKey;

    final year = parts[0];
    final month = int.parse(parts[1]);

    const monthNames = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];

    return '${monthNames[month - 1]} $year';
  }

  Future<void> refresh() async {
    _currentPage = 0;
    _hasMorePhotos = false;
    _allPhotos.clear();
    _filteredPhotos.clear();
    await initialize();
  }

  void _setState(GalleryState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> deletePhotos(List<AssetEntity> photosToDelete) async {
    try {
      final success = await GalleryService.deletePhotos(photosToDelete);

      if (success) {
        // Remove deleted photos from local lists
        for (final photo in photosToDelete) {
          _allPhotos.remove(photo);
          _filteredPhotos.remove(photo);
        }
        _groupPhotosByMonth();
        notifyListeners();
      } else {
        throw Exception('Bazı fotoğraflar silinemedi');
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Medya sayılarını tara (gerçek tarama yapar)
  Future<void> scanMedia() async {
    try {
      _setState(GalleryState.scanning);
      debugPrint('GalleryProvider: Starting real media scan...');

      // Reset display and actual counts used for the scanning animation
      _displayPhotoCount = 0;
      _displayVideoCount = 0;
      _displayTotalCount = 0;
      _actualPhotoCount = 0;
      _actualVideoCount = 0;
      _actualTotalCount = 0;
      notifyListeners();

      // Gerçek sayıları al
      final counts = await GalleryService.getMediaCount();
      _actualPhotoCount = counts['photos'] ?? 0;
      _actualVideoCount = counts['videos'] ?? 0;
      _actualTotalCount = _actualPhotoCount + _actualVideoCount;

      debugPrint(
          'GalleryProvider: Actual counts - Photos: $_actualPhotoCount, Videos: $_actualVideoCount');

      // Tarama animasyonu: önce 0'dan çift değerlere kadar yükselt, sonra gerçek değerlere düşür
      const int stepsUp = 20;
      final double photoStepUp = (_actualPhotoCount * 2) / stepsUp;
      final double videoStepUp = (_actualVideoCount * 2) / stepsUp;

      for (int i = 0; i < stepsUp; i++) {
        await Future.delayed(const Duration(milliseconds: 50));
        _displayPhotoCount = ((i + 1) * photoStepUp).round();
        _displayVideoCount = ((i + 1) * videoStepUp).round();
        _displayTotalCount = _displayPhotoCount + _displayVideoCount;
        notifyListeners();
      }

      // Bir süre çift değerlerde bekle
      await Future.delayed(const Duration(milliseconds: 300));

      // Aşağı doğru animasyon: çift değerlerden gerçek değerlere
      const int stepsDown = 20;
      for (int i = stepsDown; i >= 0; i--) {
        await Future.delayed(const Duration(milliseconds: 30));
        final double progress = i / stepsDown; // 1 -> 0
        // display = actual + (actual * progress) => varies from 2*actual down to actual
        _displayPhotoCount =
            (_actualPhotoCount + (_actualPhotoCount * progress)).round();
        _displayVideoCount =
            (_actualVideoCount + (_actualVideoCount * progress)).round();
        _displayTotalCount = _displayPhotoCount + _displayVideoCount;
        notifyListeners();
      }

      // Son olarak gerçek değerleri ayarla
      _displayPhotoCount = _actualPhotoCount;
      _displayVideoCount = _actualVideoCount;
      _displayTotalCount = _actualTotalCount;
      notifyListeners();

      // Cache'e kaydet
      await PreferencesService.setCachedPhotoCount(_actualPhotoCount);
      await PreferencesService.setCachedVideoCount(_actualVideoCount);
      await PreferencesService.setCachedTotalMediaCount(_actualTotalCount);
      await PreferencesService.setGalleryScanned(true);
      await PreferencesService.setLastScanTime(DateTime.now());

      debugPrint(
          'GalleryProvider: ✅ Scan complete - Photos: $_actualPhotoCount, Videos: $_actualVideoCount');

      _setState(GalleryState.scanned);
    } catch (e) {
      debugPrint('GalleryProvider: Error scanning media: $e');
      _errorMessage = e.toString();
      _setState(GalleryState.error);
    }
  }

  // Arka planda medya sayılarını güncelle
  Future<void> _updateMediaCountsInBackground() async {
    try {
      final counts = await GalleryService.getMediaCount();
      final newPhotoCount = counts['photos'] ?? 0;
      final newVideoCount = counts['videos'] ?? 0;
      final newTotalCount = newPhotoCount + newVideoCount;

      // Sayılar değiştiyse güncelle
      if (newPhotoCount != _actualPhotoCount || newVideoCount != _actualVideoCount) {
        _actualPhotoCount = newPhotoCount;
        _actualVideoCount = newVideoCount;
        _actualTotalCount = newTotalCount;
        _displayPhotoCount = newPhotoCount;
        _displayVideoCount = newVideoCount;
        _displayTotalCount = newTotalCount;

        // Cache'i güncelle
        await PreferencesService.setCachedPhotoCount(_actualPhotoCount);
        await PreferencesService.setCachedVideoCount(_actualVideoCount);
        await PreferencesService.setCachedTotalMediaCount(_actualTotalCount);
        await PreferencesService.setLastScanTime(DateTime.now());

        debugPrint(
            'GalleryProvider: 🔄 Background update - Photos: $_actualPhotoCount, Videos: $_actualVideoCount');
        notifyListeners();

        // If permission was revoked meanwhile, update state and stop further processing.
        if (!_hasPermission) {
          debugPrint(
              'GalleryProvider: Permission revoked during background update. Aborting further work.');
          _setState(GalleryState.permissionDenied);
          return;
        }

        // If we still have permission, reapply any active filters and kick off
        // a background load of remaining items so the UI can refresh quickly.
        try {
          debugPrint(
              'GalleryProvider: Quick reloading filtered results after background count update...');
          _applyFilter();

          // Ensure UI shows loaded state for the quick refresh.
          _setState(GalleryState.loaded);

          // Continue loading the rest of the media in background (non-blocking).
          _loadRemainingPhotosInBackground();
        } catch (e) {
          debugPrint(
              'GalleryProvider: Error while reloading media after count update: $e');
        }
      }
    } catch (e) {
      debugPrint('GalleryProvider: Error updating media counts: $e');
    }
  }

  // Temizlik modunu başlat (hızlı başlangıç + arka plan yükleme)
  Future<void> startCleaning() async {
    try {
      debugPrint('GalleryProvider: Starting cleaning mode...');

      if (_allPhotos.isNotEmpty && _state == GalleryState.loaded) {
        debugPrint(
            'GalleryProvider: Photos already loaded (${_allPhotos.length} items), skipping...');
        return;
      }

      _setState(GalleryState.loading);

      if (!_hasPermission) {
        _setState(GalleryState.permissionDenied);
        return;
      }

      // Quick start: Load first 100 photos only
      debugPrint('GalleryProvider: Quick loading first 100 photos...');
      final firstBatch =
          await GalleryService.getPhotosWithPagination(page: 0, pageSize: 500);
      _allPhotos = firstBatch;
      _applyFilter();
      _setState(GalleryState.loaded);

      await PreferencesService.setPhotosLoaded(true);
      debugPrint(
          'GalleryProvider: ✅ First 100 photos loaded! Loading rest in background...');

      // Load rest in background
      _loadRemainingPhotosInBackground();
    } catch (e) {
      debugPrint('GalleryProvider: Error starting cleaning: $e');
      _errorMessage = e.toString();
      _setState(GalleryState.error);
    }
  }

  // Arka planda kalan fotoğrafları yükle
  Future<void> _loadRemainingPhotosInBackground() async {
    _isLoadingInBackground = true;
    int page = 1; // Start from page 1 (page 0 already loaded)
    const pageSize = 100;

    debugPrint('GalleryProvider: 🔄 Background loading started...');

    try {
      while (true) {
        await Future.delayed(const Duration(milliseconds: 100));

        final newPhotos = await GalleryService.getPhotosWithPagination(
          page: page,
          pageSize: pageSize,
        );

        if (newPhotos.isEmpty) {
          debugPrint(
              'GalleryProvider: ✅ Background loading complete - Total: ${_allPhotos.length} photos');
          break;
        }

        _allPhotos.addAll(newPhotos);
        _applyFilter();

        debugPrint(
            'GalleryProvider: Background loaded page $page - Total: ${_allPhotos.length}');
        page++;
      }
    } catch (e) {
      debugPrint('GalleryProvider: Error in background loading: $e');
    } finally {
      _isLoadingInBackground = false;
      notifyListeners();
    }
  }
}
