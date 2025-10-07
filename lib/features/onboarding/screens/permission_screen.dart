import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/preferences_service.dart';
import '../../gallery/providers/gallery_provider.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    if (_isRequesting) return;

    setState(() {
      _isRequesting = true;
    });

    try {
      final galleryProvider = context.read<GalleryProvider>();
      await galleryProvider.requestPermission();

      if (galleryProvider.hasPermission) {
        // İzin durumunu kaydet
        await PreferencesService.setPermissionGranted(true);
        await PreferencesService.setOnboardingCompleted(true);
        await PreferencesService.setFirstLaunch(false);

        // Taramayı başlat ve tamamlanmasını bekle
        await galleryProvider.scanMedia();

        // Tarama tamamlandıktan sonra galeri ekranına geç
        if (mounted && galleryProvider.state == GalleryState.scanned) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.mainGallery);

          // Arka planda fotoğrafları yükle
          galleryProvider.startCleaning();
        }
      } else {
        _showPermissionDeniedDialog();
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İzin Gerekli'),
        content: const Text(
          'Uygulamanın çalışması için galeri erişim izni gereklidir. '
          'Lütfen ayarlardan izin verin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hata'),
        content: Text('Bir hata oluştu: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<GalleryProvider>(
          builder: (context, galleryProvider, child) {
            // Show scanning state if scanning
            if (galleryProvider.state == GalleryState.scanning) {
              return _buildScanningState(galleryProvider);
            }

            // Show permission request
            return _buildPermissionRequest();
          },
        ),
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Permission icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: const Icon(
                      Icons.photo_library,
                      size: 60,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Title
                  const Text(
                    'Galeri Erişimi',
                    style: AppTextStyles.heading2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Description
                  Text(
                    'Fotoğraflarınızı analiz edebilmek için galeri erişim izni gerekiyor. '
                    'Verileriniz güvende kalacak ve hiçbir yerde saklanmayacak.',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Permission features
                  _buildPermissionFeature(
                    Icons.security,
                    'Güvenli Erişim',
                    'Fotoğraflarınız sadece analiz için kullanılır',
                  ),
                  const SizedBox(height: 16),
                  _buildPermissionFeature(
                    Icons.cloud_off,
                    'Yerel İşlem',
                    'Hiçbir veri internete gönderilmez',
                  ),
                  const SizedBox(height: 16),
                  _buildPermissionFeature(
                    Icons.delete_outline,
                    'Kontrollü Silme',
                    'Sadece onayladığınız fotoğraflar silinir',
                  ),
                  const SizedBox(height: 64),

                  // Allow button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isRequesting ? null : _requestPermission,
                      child: _isRequesting
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('İzin İsteniyor...'),
                              ],
                            )
                          : const Text('İzin Ver'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScanningState(GalleryProvider galleryProvider) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Scanning Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.search_rounded,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 48),

          const CircularProgressIndicator(),
          const SizedBox(height: 24),

          const Text(
            'Medya Dosyaları Taranıyor...',
            style: AppTextStyles.heading2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          Text(
            'Galerinizde bulunan tüm fotoğraf ve videolar sayılıyor.',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Live count display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCountCard(
                'Fotoğraf',
                galleryProvider.photoCount.toString(),
                Icons.photo,
                AppColors.primary,
              ),
              _buildCountCard(
                'Video',
                galleryProvider.videoCount.toString(),
                Icons.videocam,
                AppColors.secondary,
              ),
              _buildCountCard(
                'Toplam',
                galleryProvider.totalMediaCount.toString(),
                Icons.folder,
                AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountCard(
      String title, String count, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: color,
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: AppTextStyles.heading3.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: AppTextStyles.bodySmall.copyWith(
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionFeature(
      IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            icon,
            color: AppColors.success,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.heading4,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
