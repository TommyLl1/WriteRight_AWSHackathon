import 'package:flutter/material.dart';
import 'package:writeright/new/data/services/image_cache.dart';
class ExerciseCard extends StatelessWidget {
  final String title;
  final String duration;
  final String imagePath;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final double width;
  final double height;

  const ExerciseCard({
    super.key,
    required this.title,
    required this.duration,
    required this.imagePath,
    required this.onTap,
    this.backgroundColor,
    this.width = 180,
    this.height = 280,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white.withAlpha((0.2 * 255).toInt()),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 255).toInt()),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular Image
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.3 * 255).toInt()),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: CommonImageCache().getExerciseCardImage(
                  imagePath: imagePath,
                  size: 120,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Duration
            Text(
              duration,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Start Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002B45),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onPressed: onTap,
              child: const Text(
                '開始',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
