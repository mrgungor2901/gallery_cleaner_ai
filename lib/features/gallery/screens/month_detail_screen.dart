import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../../core/constants/app_colors.dart';
import '../providers/gallery_provider.dart';

enum PhotoDecision { none, keep, delete, skip }

class PhotoDecisionData {
  final AssetEntity asset;
  PhotoDecision decision;
  PhotoDecisionData({required this.asset, this.decision = PhotoDecision.none});
}

class MonthDetailScreen extends StatefulWidget {
  final String monthName;
  final List<AssetEntity> photos;
  const MonthDetailScreen(
      {super.key, required this.monthName, required this.photos});
  @override
  State<MonthDetailScreen> createState() => _MonthDetailScreenState();
}

class _MonthDetailScreenState extends State<MonthDetailScreen> {
  int _selectedIndex = 0;
  File? _selectedPhotoFile;
  Map<String, dynamic>? _photoInfo;
  bool _isLoading = true;
  late List<PhotoDecisionData> _photoDecisions;
  final List<int> _decisionHistory = [];
  bool _isProcessing = false;

  // Swipe animation - PERFORMANS İYİLEŞTİRMESİ
  final ValueNotifier<double> _dragDistanceNotifier = ValueNotifier<double>(0);
  final ScrollController _thumbnailScrollController = ScrollController();
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _photoDecisions =
        widget.photos.map((asset) => PhotoDecisionData(asset: asset)).toList();
    _loadSelectedPhoto();
  }

  @override
  void dispose() {
    _dragDistanceNotifier.dispose();
    _thumbnailScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSelectedPhoto() async {
    if (widget.photos.isEmpty) return;
    setState(() => _isLoading = true);

    final asset = widget.photos[_selectedIndex];
    final file = await asset.file;
    int? fileSize;
    if (file != null) fileSize = await file.length();

    if (!mounted) return;

    setState(() {
      _selectedPhotoFile = file;
      _photoInfo = {
        'size': _formatFileSize(fileSize ?? 0),
        'type': _getFileType(asset),
        'index': _selectedIndex + 1,
        'total': widget.photos.length,
        'width': asset.width,
        'height': asset.height,
      };
      _isLoading = false;
    });

    // Reset swipe position
    _dragDistanceNotifier.value = 0;

    // Scroll to selected thumbnail
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedThumbnail();
    });
  }

  void _scrollToSelectedThumbnail() {
    if (_thumbnailScrollController.hasClients) {
      const double itemWidth = 68.0; // 60 width + 8 margin
      final double screenWidth = MediaQuery.of(context).size.width;
      final double targetScroll =
          (_selectedIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
      _thumbnailScrollController.animateTo(
        targetScroll.clamp(
            0.0, _thumbnailScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _getFileType(AssetEntity asset) {
    if (asset.type == AssetType.image) {
      final title = asset.title ?? '';
      if (title.toLowerCase().endsWith('.jpg') ||
          title.toLowerCase().endsWith('.jpeg')) {
        return 'JPEG';
      }
      if (title.toLowerCase().endsWith('.png')) return 'PNG';
      if (title.toLowerCase().endsWith('.heic')) return 'HEIC';
      return 'Resim';
    }
    return 'Video';
  }

  void _selectPhoto(int index) {
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
      _loadSelectedPhoto();
    }
  }

  void _makeDecision(PhotoDecision decision) {
    setState(() {
      _decisionHistory.add(_selectedIndex);
      _photoDecisions[_selectedIndex].decision = decision;
    });
    if (_selectedIndex < widget.photos.length - 1) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() => _selectedIndex++);
          _loadSelectedPhoto();
        }
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _undoLastDecision() {
    if (_decisionHistory.isEmpty) return;
    final lastIndex = _decisionHistory.removeLast();
    setState(() {
      _photoDecisions[lastIndex].decision = PhotoDecision.none;
      _selectedIndex = lastIndex;
    });
    _loadSelectedPhoto();
  }

  void _handleSwipeEnd(DragEndDetails details) async {
    if (_isAnimating) return;

    final velocity = details.velocity.pixelsPerSecond.dx;
    final screenWidth = MediaQuery.of(context).size.width;
    final currentDrag = _dragDistanceNotifier.value;

    // Sağa kaydırma - SAKLA (Keep)
    if (currentDrag > screenWidth * 0.3 || velocity > 500) {
      await _animateSwipeDecision(PhotoDecision.keep, screenWidth);
    }
    // Sola kaydırma - SİL (Delete)
    else if (currentDrag < -screenWidth * 0.3 || velocity < -500) {
      await _animateSwipeDecision(PhotoDecision.delete, -screenWidth);
    }
    // Geri dön
    else {
      await _animateToPosition(0);
    }
  }

  Future<void> _animateToPosition(double targetPosition) async {
    if (_isAnimating) return;
    _isAnimating = true;

    final startPosition = _dragDistanceNotifier.value;
    final distance = targetPosition - startPosition;
    const duration = Duration(milliseconds: 200);
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < duration) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final progress = (elapsed / duration.inMilliseconds).clamp(0.0, 1.0);

      // Easing function for smooth animation
      final easedProgress = Curves.easeOut.transform(progress);
      _dragDistanceNotifier.value = startPosition + (distance * easedProgress);

      await Future.delayed(const Duration(milliseconds: 16)); // ~60fps
    }

    _dragDistanceNotifier.value = targetPosition;
    _isAnimating = false;
  }

  Future<void> _animateSwipeDecision(
      PhotoDecision decision, double targetDistance) async {
    if (_isAnimating) return;

    await _animateToPosition(targetDistance);
    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      _makeDecision(decision);
    }
  }

  void _showCompletionDialog() {
    final deleteCount =
        _photoDecisions.where((d) => d.decision == PhotoDecision.delete).length;
    final keepCount =
        _photoDecisions.where((d) => d.decision == PhotoDecision.keep).length;
    final skipCount =
        _photoDecisions.where((d) => d.decision == PhotoDecision.skip).length;
    final noneCount =
        _photoDecisions.where((d) => d.decision == PhotoDecision.none).length;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('İnceleme Tamamlandı',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Toplam: ${widget.photos.length} fotoğraf',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            _buildDecisionSummary(
                'Silinecek', deleteCount, Icons.delete, AppColors.error),
            _buildDecisionSummary(
                'Saklanacak', keepCount, Icons.check_circle, AppColors.success),
            _buildDecisionSummary(
                'Atlanacak', skipCount, Icons.skip_next, AppColors.warning),
            if (noneCount > 0)
              _buildDecisionSummary('Karar verilmedi', noneCount, Icons.help,
                  AppColors.textTertiary),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          if (deleteCount > 0)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _processDecisions();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: Text('$deleteCount Fotoğrafı Sil'),
            ),
          if (deleteCount == 0)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Tamam'),
            ),
        ],
      ),
    );
  }

  Widget _buildDecisionSummary(
      String label, int count, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text('$label: $count',
              style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _processDecisions() async {
    setState(() => _isProcessing = true);
    final photosToDelete = _photoDecisions
        .where((d) => d.decision == PhotoDecision.delete)
        .map((d) => d.asset)
        .toList();

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${photosToDelete.length} fotoğraf siliniyor...'),
            backgroundColor: AppColors.warning,
          ),
        );
      }

      // Silme işlemini provider üzerinden yap - sadece silinen fotoğrafları listeden çıkar
      final galleryProvider =
          Provider.of<GalleryProvider>(context, listen: false);
      await galleryProvider.deletePhotos(photosToDelete);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fotoğraflar başarıyla silindi'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  int get _decidedCount =>
      _photoDecisions.where((d) => d.decision != PhotoDecision.none).length;

  Color _getDecisionColor(PhotoDecision decision) {
    switch (decision) {
      case PhotoDecision.keep:
        return AppColors.success;
      case PhotoDecision.delete:
        return AppColors.error;
      case PhotoDecision.skip:
        return AppColors.warning;
      default:
        return AppColors.textTertiary;
    }
  }

  IconData _getDecisionIcon(PhotoDecision decision) {
    switch (decision) {
      case PhotoDecision.keep:
        return Icons.check_circle;
      case PhotoDecision.delete:
        return Icons.delete;
      case PhotoDecision.skip:
        return Icons.skip_next;
      default:
        return Icons.help;
    }
  }

  String _getDecisionText(PhotoDecision decision) {
    switch (decision) {
      case PhotoDecision.keep:
        return 'Saklandı';
      case PhotoDecision.delete:
        return 'Silinecek';
      case PhotoDecision.skip:
        return 'Atlandı';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildThumbnailStrip(),
            Expanded(child: _buildMainPhotoView()),
            _buildActionButtons(),
            _buildPhotoInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final currentDecision = _photoDecisions[_selectedIndex].decision;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outline, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.monthName,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text('$_decidedCount/${widget.photos.length} karar verildi',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (currentDecision != PhotoDecision.none)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getDecisionColor(currentDecision),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_getDecisionText(currentDecision),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary)),
              ),
            ),
          // Tamamlama Butonu
          if (_decidedCount > 0 && !_isProcessing)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ElevatedButton.icon(
                onPressed: _showCompletionDialog,
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text('Tamamla'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThumbnailStrip() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        controller: _thumbnailScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: widget.photos.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedIndex;
          final decision = _photoDecisions[index].decision;
          return GestureDetector(
            onTap: () => _selectPhoto(index),
            child: Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.outline,
                        width: isSelected ? 3 : 1),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 2)
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: FutureBuilder<Uint8List?>(
                      future: widget.photos[index].thumbnailDataWithSize(
                        const ThumbnailSize(150, 150),
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                            width: 60,
                            height: 60,
                          );
                        }
                        return Container(
                          color: AppColors.surfaceVariant,
                          child: const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary))),
                        );
                      },
                    ),
                  ),
                ),
                if (decision != PhotoDecision.none)
                  Positioned(
                    top: 2,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _getDecisionColor(decision),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4)
                        ],
                      ),
                      child: Icon(_getDecisionIcon(decision),
                          size: 14, color: Colors.white),
                    ),
                  ),
                // Video ikonu
                if (widget.photos[index].type == AssetType.video)
                  Positioned(
                    bottom: 2,
                    left: 2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainPhotoView() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)));
    }
    if (_selectedPhotoFile == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 60, color: AppColors.textTertiary),
            SizedBox(height: 12),
            Text('Fotoğraf yüklenemedi',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    return ValueListenableBuilder<double>(
      valueListenable: _dragDistanceNotifier,
      builder: (context, dragDistance, child) {
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            _dragDistanceNotifier.value += details.delta.dx;
          },
          onHorizontalDragEnd: _handleSwipeEnd,
          child: Stack(
            children: [
              // Ana fotoğraf - Center ile ortala
              Center(
                child: Transform.translate(
                  offset: Offset(dragDistance, 0),
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child:
                          Image.file(_selectedPhotoFile!, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),

              // Sağa kaydırma göstergesi (SAKLA)
              if (dragDistance > 50)
                Positioned(
                  left: 20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Opacity(
                      opacity: (dragDistance / 200).clamp(0.0, 1.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.white, size: 48),
                            SizedBox(height: 8),
                            Text(
                              'SAKLA',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Sola kaydırma göstergesi (SİL)
              if (dragDistance < -50)
                Positioned(
                  right: 20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Opacity(
                      opacity: (-dragDistance / 200).clamp(0.0, 1.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.error.withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete, color: Colors.white, size: 48),
                            SizedBox(height: 8),
                            Text(
                              'SİL',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Video ikonu - ana görünümde
              if (_photoDecisions[_selectedIndex].asset.type == AssetType.video)
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Video',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outline, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Geri Al
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _decisionHistory.isEmpty ? null : _undoLastDecision,
              icon: const Icon(Icons.undo, size: 20),
              label: const Text('Geri Al'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.outline),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Sil
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _makeDecision(PhotoDecision.delete),
              icon: const Icon(Icons.delete, size: 20),
              label: const Text('Sil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Atla
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _makeDecision(PhotoDecision.skip),
              icon: const Icon(Icons.skip_next, size: 20),
              label: const Text('Atla'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
                side: const BorderSide(color: AppColors.warning),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Sakla
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _makeDecision(PhotoDecision.keep),
              icon: const Icon(Icons.check_circle, size: 20),
              label: const Text('Sakla'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoInfo() {
    if (_photoInfo == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
              Icons.photo, '${_photoInfo!['index']}/${_photoInfo!['total']}'),
          _buildInfoItem(Icons.image, _photoInfo!['type']),
          _buildInfoItem(Icons.straighten,
              '${_photoInfo!['width']}x${_photoInfo!['height']}'),
          _buildInfoItem(Icons.storage, _photoInfo!['size']),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
