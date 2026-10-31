import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'exercise_video.dart';

class ExerciseCover extends StatelessWidget {
  const ExerciseCover({
    super.key,
    required this.name,
    this.imageUrl,
    this.videoUrl,
    this.height = 225,
  });
  final String name;
  final String? imageUrl;
  final String? videoUrl;
  final double height;
  @override
  Widget build(BuildContext context) {
    final hasVideo = videoUrl != null && videoUrl!.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: AppColors.surfaceRaised,
              child: const Icon(
                Icons.fitness_center,
                size: 55,
                color: AppColors.muted,
              ),
            ),
            if (imageUrl != null)
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, error, trace) => const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 45,
                    color: AppColors.muted,
                  ),
                ),
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const Center(child: CircularProgressIndicator()),
              ),
            if (hasVideo)
              Center(
                child: Material(
                  color: AppColors.background.withValues(alpha: 0.85),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Ver video del ejercicio',
                    iconSize: 38,
                    padding: const EdgeInsets.all(15),
                    color: AppColors.lime,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ExerciseVideo(name: name, url: videoUrl!),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                  ),
                ),
              ),
            if (!hasVideo)
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Video próximamente',
                    style: TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
