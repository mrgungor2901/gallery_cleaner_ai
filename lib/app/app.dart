import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../shared/themes/app_theme.dart';
import 'routes.dart';

class GalleryCleanerApp extends StatelessWidget {
  const GalleryCleanerApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'Galeri Temizleyici AI',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
