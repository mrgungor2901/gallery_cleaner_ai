import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../core/services/ai_service.dart';
import '../models/analysis_result.dart';

enum AnalysisState {
  idle,
  analyzing,
  completed,
  error,
}

class AIProvider extends ChangeNotifier {
  AnalysisState _state = AnalysisState.idle;
  AnalysisResult? _result;
  int _currentProgress = 0;
  int _totalPhotos = 0;
  String? _errorMessage;
  String _currentAnalysisStep = '';

  // Selection management
  final Map<PhotoCategory, Set<AssetEntity>> _selectedPhotos = {
    PhotoCategory.blurry: {},
    PhotoCategory.small: {},
    PhotoCategory.nonPerson: {},
  };

  // Getters
  AnalysisState get state => _state;
  AnalysisResult? get result => _result;
  int get currentProgress => _currentProgress;
  int get totalPhotos => _totalPhotos;
  String? get errorMessage => _errorMessage;
  String get currentAnalysisStep => _currentAnalysisStep;

  double get progressPercentage => 
      _totalPhotos > 0 ? (_currentProgress / _totalPhotos) : 0.0;

  Map<PhotoCategory, Set<AssetEntity>> get selectedPhotos => _selectedPhotos;

  int get totalSelectedCount => _selectedPhotos.values
      .fold(0, (sum, set) => sum + set.length);

  Future<void> analyzePhotos(List<AssetEntity> photos) async {
    _state = AnalysisState.analyzing;
    _currentProgress = 0;
    _totalPhotos = photos.length;
    _errorMessage = null;
    _result = null;
    notifyListeners();

    try {
      _currentAnalysisStep = 'Fotoğraflar analiz ediliyor...';
      notifyListeners();

      final results = await AIService.analyzePhotos(
        photos,
        (current, total) {
          _currentProgress = current;
          _totalPhotos = total;

          if (current <= total * 0.3) {
            _currentAnalysisStep = 'Küçük fotoğraflar tespit ediliyor...';
          } else if (current <= total * 0.7) {
            _currentAnalysisStep = 'Bulanık fotoğraflar analiz ediliyor...';
          } else {
            _currentAnalysisStep = 'Kişi tespiti yapılıyor...';
          }

          notifyListeners();
        },
      );

      _result = AnalysisResult.fromCategoryMap(results);
      _state = AnalysisState.completed;
      _currentAnalysisStep = 'Analiz tamamlandı!';

      // Initialize selections (select all problematic photos by default)
      _selectedPhotos[PhotoCategory.blurry] = Set.from(_result!.blurryPhotos);
      _selectedPhotos[PhotoCategory.small] = Set.from(_result!.smallPhotos);
      _selectedPhotos[PhotoCategory.nonPerson] = Set.from(_result!.nonPersonPhotos);

    } catch (e) {
      _errorMessage = e.toString();
      _state = AnalysisState.error;
      _currentAnalysisStep = 'Analiz sırasında hata oluştu';
    }

    notifyListeners();
  }

  void togglePhotoSelection(PhotoCategory category, AssetEntity photo) {
    if (_selectedPhotos[category]!.contains(photo)) {
      _selectedPhotos[category]!.remove(photo);
    } else {
      _selectedPhotos[category]!.add(photo);
    }
    notifyListeners();
  }

  void selectAllInCategory(PhotoCategory category) {
    switch (category) {
      case PhotoCategory.blurry:
        _selectedPhotos[category] = Set.from(_result?.blurryPhotos ?? []);
        break;
      case PhotoCategory.small:
        _selectedPhotos[category] = Set.from(_result?.smallPhotos ?? []);
        break;
      case PhotoCategory.nonPerson:
        _selectedPhotos[category] = Set.from(_result?.nonPersonPhotos ?? []);
        break;
      case PhotoCategory.good:
        break;
    }
    notifyListeners();
  }

  void deselectAllInCategory(PhotoCategory category) {
    _selectedPhotos[category]?.clear();
    notifyListeners();
  }

  void selectAll() {
    selectAllInCategory(PhotoCategory.blurry);
    selectAllInCategory(PhotoCategory.small);
    selectAllInCategory(PhotoCategory.nonPerson);
  }

  void deselectAll() {
    deselectAllInCategory(PhotoCategory.blurry);
    deselectAllInCategory(PhotoCategory.small);
    deselectAllInCategory(PhotoCategory.nonPerson);
  }

  bool isPhotoSelected(PhotoCategory category, AssetEntity photo) {
    return _selectedPhotos[category]?.contains(photo) ?? false;
  }

  List<AssetEntity> getAllSelectedPhotos() {
    final allSelected = <AssetEntity>[];
    _selectedPhotos.values.forEach((set) => allSelected.addAll(set));
    return allSelected;
  }

  void reset() {
    _state = AnalysisState.idle;
    _result = null;
    _currentProgress = 0;
    _totalPhotos = 0;
    _errorMessage = null;
    _currentAnalysisStep = '';
    _selectedPhotos.values.forEach((set) => set.clear());
    notifyListeners();
  }

  // Get statistics for selected photos
  Map<String, int> getSelectionStats() {
    return {
      'blurry': _selectedPhotos[PhotoCategory.blurry]?.length ?? 0,
      'small': _selectedPhotos[PhotoCategory.small]?.length ?? 0,
      'nonPerson': _selectedPhotos[PhotoCategory.nonPerson]?.length ?? 0,
      'total': totalSelectedCount,
    };
  }
}
