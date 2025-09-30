import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class AnalysisProgress extends StatefulWidget {
  final int currentProgress;
  final int totalPhotos;
  final String currentStep;
  final double progressPercentage;

  const AnalysisProgress({
    super.key,
    required this.currentProgress,
    required this.totalPhotos,
    required this.currentStep,
    required this.progressPercentage,
  });

  @override
  State<AnalysisProgress> createState() => _AnalysisProgressState();
}

class _AnalysisProgressState extends State<AnalysisProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // AI Icon with pulse animation
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_fix_high,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 48),

          // Current step
          Text(
            widget.currentStep,
            style: AppTextStyles.heading3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Progress bar
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: widget.progressPercentage,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Progress text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.currentProgress} / ${widget.totalPhotos}',
                style: AppTextStyles.bodyMedium,
              ),
              Text(
                '${(widget.progressPercentage * 100).toInt()}%',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),

          // Analysis steps
          _buildAnalysisSteps(),
          const SizedBox(height: 32),

          // Info text
          Text(
            'Fotoğraflarınız analiz ediliyor. Bu işlem birkaç dakika sürebilir.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSteps() {
    final steps = [
      {'icon': Icons.photo_size_select_small, 'title': 'Boyut Analizi'},
      {'icon': Icons.blur_on, 'title': 'Bulanıklık Tespiti'},
      {'icon': Icons.face, 'title': 'Kişi Tespiti'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: steps.map((step) {
        final isActive = _isStepActive(step['title'] as String);
        final isCompleted = _isStepCompleted(step['title'] as String);

        return Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success
                    : isActive
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                isCompleted ? Icons.check : step['icon'] as IconData,
                color: isCompleted || isActive
                    ? Colors.white
                    : AppColors.textTertiary,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              step['title'] as String,
              style: AppTextStyles.bodySmall.copyWith(
                color: isCompleted || isActive
                    ? AppColors.textPrimary
                    : AppColors.textTertiary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  bool _isStepActive(String stepTitle) {
    if (widget.currentStep.contains('Küçük fotoğraflar')) {
      return stepTitle == 'Boyut Analizi';
    } else if (widget.currentStep.contains('Bulanık fotoğraflar')) {
      return stepTitle == 'Bulanıklık Tespiti';
    } else if (widget.currentStep.contains('Kişi tespiti')) {
      return stepTitle == 'Kişi Tespiti';
    }
    return false;
  }

  bool _isStepCompleted(String stepTitle) {
    final progress = widget.progressPercentage;

    if (stepTitle == 'Boyut Analizi') {
      return progress > 0.3;
    } else if (stepTitle == 'Bulanıklık Tespiti') {
      return progress > 0.7;
    } else if (stepTitle == 'Kişi Tespiti') {
      return progress >= 1.0;
    }

    return false;
  }
}
