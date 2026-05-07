import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class GymLogoWidget extends StatelessWidget {
  final double size;
  final bool showShadow;

  const GymLogoWidget({
    super.key,
    this.size = 80,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent,
            const Color(0xFFFF9D72), // Lighter accent for premium gradient
          ],
        ),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Icon(
        Icons.fitness_center_rounded,
        color: Colors.white,
        size: size * 0.55,
      ),
    );
  }
}
