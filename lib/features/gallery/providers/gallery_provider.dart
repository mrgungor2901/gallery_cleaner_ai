import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../core/services/gallery_service.dart';
import '../../../core/services/permission_service.dart';

enum GalleryState {
  initial,
  loading,
  loaded,
  error,
  permissionDenied,
}

class GalleryProvider extends ChangeNotifier {
  GalleryState _state = GalleryState.initial;
  List<AssetEntity> _allPhotos = [];
  List<AssetEntity> _filteredPhotos = [];
  String _searchQuery = '';
  bool _hasPermission = false;
  String? _errorMessage;

  // Pagination
  int _currentPage = 0;
  final int _pageSize = 50;
  bool _hasMorePhotos = true;
  bool _isLoadingMore = false;

  // Getters
  GalleryState get state => _state;
  List<AssetEntity> get photos => _filteredPhotos;
  List<AssetEntity> get allPhotos => _allPhotos;
  String get searchQuery => _searchQuery;
  bool get hasPermission => _hasPermission;
  String? get errorMessage => _errorMessage;
  bool get hasMorePhotos => _hasMorePhotos;
  bool get isLoadingMore => _isLoadingMore;

  int get totalPhotos => _allPhotos.length;
  int get displayedPhotos => _filteredPhotos.length;

  Future<void> initialize() async {
    _setState(GalleryState.loading);

    try {
      // Check permission
      _hasPermission = await PermissionService.checkGalleryPermission();

      if (!_hasPermission) {
        _setState(GalleryState.permissionDenied);
        return;
      }

      await _loadPhotos();
      _setState(GalleryState.loaded);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(GalleryState.error);
    }
  }

  Future<void> requestPermission() async {
    try {
      _hasPermission = await PermissionService.requestGalleryPermission();

      if (_hasPermission) {
        await initialize();
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
    if (_isLoadingMore || !_hasMorePhotos) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      await _loadPhotos();
    } catch (e) {
      _currentPage--; // Revert page increment on error
      _errorMessage = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void searchPhotos(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilter();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredPhotos = List.from(_allPhotos);
    } else {
      // For now, we can't search by filename easily with photo_manager
      // This is a placeholder for future implementation
      _filteredPhotos = List.from(_allPhotos);
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    _currentPage = 0;
    _hasMorePhotos = true;
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
}
