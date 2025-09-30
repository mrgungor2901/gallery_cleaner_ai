import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'features/gallery/providers/gallery_provider.dart';
import 'features/ai_analysis/providers/ai_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GalleryProvider()),
        ChangeNotifierProvider(create: (_) => AIProvider()),
      ],
      child: const GalleryCleanerApp(),
    ),
  );
}
