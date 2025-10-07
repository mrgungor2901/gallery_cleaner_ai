import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.auto_fix_high,
      title: 'AI Destekli Temizlik',
      description: 'Yapay zeka teknolojisi ile galerinizi otomatik olarak analiz eder ve gereksiz fotoğrafları tespit eder.',
    ),
    OnboardingPage(
      icon: Icons.blur_on,
      title: 'Bulanık Fotoğrafları Bul',
      description: 'Bulanık, odaksız ve kalitesiz fotoğrafları otomatik olarak tespit eder ve silmenizi önerir.',
    ),
    OnboardingPage(
      icon: Icons.photo_size_select_small,
      title: 'Küçük Fotoğrafları Temizle',
      description: 'Düşük çözünürlüklü ve küçük boyutlu fotoğrafları bulur, depolama alanınızı optimize eder.',
    ),
    OnboardingPage(
      icon: Icons.storage,
      title: 'Depolama Alanı Kazanın',
      description: 'Gereksiz fotoğrafları silerek telefonunuzda daha fazla yer açın ve performansı artırın.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.permission);
    }
  }

  void _skipOnboarding() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.permission);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: const Text(
                    'Geç',
                    style: AppTextStyles.buttonTextSmall,
                  ),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(_pages[index]);
                },
              ),
            ),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => _buildPageIndicator(index),
              ),
            ),
            const SizedBox(height: 32),

            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  child: Text(
                    _currentPage == _pages.length - 1 
                        ? 'Başlayalım' 
                        : 'Devam',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              page.icon,
              size: 60,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 48),

          // Title
          Text(
            page.title,
            style: AppTextStyles.heading2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Description
          Text(
            page.description,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index 
            ? AppColors.primary 
            : AppColors.primary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });
}
