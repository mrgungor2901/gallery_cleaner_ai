import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AnalysisFAB extends StatefulWidget {
  final VoidCallback onPressed;

  const AnalysisFAB({
    super.key,
    required this.onPressed,
  });

  @override
  State<AnalysisFAB> createState() => _AnalysisFABState();
}

class _AnalysisFABState extends State<AnalysisFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
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
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FloatingActionButton.extended(
            onPressed: widget.onPressed,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 8,
            icon: RotationTransition(
              turns: _rotationAnimation,
              child: const Icon(Icons.auto_fix_high),
            ),
            label: const Text(
              'AI Analizi Başlat',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}
