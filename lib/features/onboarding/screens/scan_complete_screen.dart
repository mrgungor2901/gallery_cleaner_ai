import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../gallery/providers/gallery_provider.dart';

class ScanCompleteScreen extends StatelessWidget {
  const ScanCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<GalleryProvider>(
          builder: (context, provider, child) {
            if (provider.state == GalleryState.scanning) {
              return _buildScanning();
            }
            return _buildComplete(context, provider);
          },
        ),
      ),
    );
  }

  Widget _buildScanning() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text(
            'Medya dosyaları taranıyor...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildComplete(BuildContext context, GalleryProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.check_circle,
              size: 60,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 32),

          // Title
          const Text(
            'Tarama Tamamlandı!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 48),

          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '${provider.photoCount}',
                  'Fotoğraf',
                  AppColors.primary,
                  Icons.image,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  '${provider.videoCount}',
                  'Video',
                  AppColors.secondary,
                  Icons.videocam,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            '${provider.totalMediaCount}',
            'Toplam',
            AppColors.warning,
            Icons.folder,
          ),
          const SizedBox(height: 48),

          // Start Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                // Önce galeriye git
                Navigator.of(context)
                    .pushReplacementNamed(AppRoutes.mainGallery);

                // Sonra arka planda fotoğrafları yükle
                await provider.startCleaning();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Temizliğe Başla'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String value, String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
