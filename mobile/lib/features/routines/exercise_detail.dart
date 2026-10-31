import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/widgets.dart';
import '../training/exercise_cover.dart';
import 'routine.dart';

class ExerciseDetail extends StatelessWidget {
  const ExerciseDetail({super.key, required this.exercise});
  final LibraryExercise exercise;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ejercicio')),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LimeButton(
          label: 'Agregar a mi rutina',
          icon: Icons.add,
          onPressed: () => Navigator.pop(context, exercise),
        ),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        ExerciseCover(
          name: exercise.name,
          imageUrl: exercise.coverUrl,
          videoUrl: exercise.videoUrl,
        ),
        const SizedBox(height: 18),
        Text(exercise.name, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          [
            exercise.group,
            if (exercise.equipment.isNotEmpty) exercise.equipment,
          ].join(' · '),
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        Wrap(
          children: [
            Chip(
              label: Text(exercise.group),
              avatar: const Icon(Icons.fitness_center, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: AppColors.lime),
                  SizedBox(width: 8),
                  Text(
                    'Técnica correcta',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                exercise.instructions.isEmpty
                    ? 'Las indicaciones de este ejercicio estarán disponibles próximamente.'
                    : exercise.instructions,
                style: const TextStyle(color: AppColors.muted, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
