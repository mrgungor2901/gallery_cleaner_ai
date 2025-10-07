import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/services/permission_service.dart';
import '../../gallery/providers/gallery_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _navigateToNext();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 3000));

    if (!mounted) return;

    // Kaydedilmiş durumu kontrol et
    final isOnboardingCompleted =
        await PreferencesService.isOnboardingCompleted();

    if (!mounted) return;

    if (isOnboardingCompleted) {
      // Onboarding tamamlanmış - izin durumunu kontrol et
      debugPrint('SplashScreen: Onboarding completed, checking permission...');

      final galleryProvider = context.read<GalleryProvider>();
      final hasPermission = await PermissionService.checkGalleryPermission();

      if (!mounted) return;

      if (hasPermission) {
        // İzin var - direkt galeri ekranına git (fotoğraflar arka planda yüklenecek)
        debugPrint(
            'SplashScreen: Permission granted, navigating to gallery...');

        Navigator.of(context).pushReplacementNamed(AppRoutes.mainGallery);

        // Arka planda fotoğrafları yükle
        galleryProvider.startCleaning();
      } else {
        // İzin yok - permission ekranına git
        debugPrint(
            'SplashScreen: Permission not granted, navigating to permission screen...');
        Navigator.of(context).pushReplacementNamed(AppRoutes.permission);
      }
    } else {
      // İlk açılış - onboarding'e git
      debugPrint('SplashScreen: First launch, navigating to onboarding...');
      Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_fix_high,
                          size: 60,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // App Name
                      const Text(
                        'Galeri Temizleyici',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      const Text(
                        'AI Destekli',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 60),

                      // Loading indicator
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
