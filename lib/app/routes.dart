import 'package:flutter/material.dart';
import '../features/onboarding/screens/splash_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/onboarding/screens/permission_screen.dart';
import '../features/gallery/screens/main_gallery_screen.dart';
import '../features/gallery/screens/month_detail_screen.dart';
import '../features/ai_analysis/screens/ai_analysis_screen.dart';
import '../features/ai_analysis/screens/category_results_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String permission = '/permission';
  static const String mainGallery = '/main-gallery';
  static const String monthDetail = '/month-detail';
  static const String aiAnalysis = '/ai-analysis';
  static const String categoryResults = '/category-results';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case permission:
        return MaterialPageRoute(builder: (_) => const PermissionScreen());
      case mainGallery:
        return MaterialPageRoute(builder: (_) => const MainGalleryScreen());
      case monthDetail:
        final monthArgs = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => MonthDetailScreen(
            monthName: monthArgs['monthName'],
            photos: monthArgs['photos'],
          ),
        );
      case aiAnalysis:
        return MaterialPageRoute(builder: (_) => const AIAnalysisScreen());
      case categoryResults:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => CategoryResultsScreen(
            category: args['category'],
            photos: args['photos'],
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Sayfa bulunamadı')),
          ),
        );
    }
  }
}
