import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/models.dart';
import '../../core/widgets.dart';
import '../routines/published_routines.dart';
import '../routines/routine.dart';
import '../routines/routine_editor.dart';
import '../routines/teacher_routines.dart';
import '../training/workout_screen.dart';

class SimpleHome extends StatefulWidget {
  const SimpleHome({
    super.key,
    required this.profile,
    required this.onSavedRoutines,
    required this.onProgress,
  });
  final AthleteProfile profile;
  final VoidCallback onSavedRoutines;
  final VoidCallback onProgress;
  @override
  State<SimpleHome> createState() => _SimpleHomeState();
}

class _SimpleHomeState extends State<SimpleHome> {
  final _repository = RoutineRepository();
  List<TrainingRoutine> _routines = [];
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final routines = await _repository.load();
      if (mounted) {
        setState(() {
          _routines = routines;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'No pudimos leer tus rutinas. Reintentá para continuar.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(TrainingRoutine routine) async {
    try {
      final saved = await _repository.load();
      await _repository.save([
        ...saved.where((r) => r.id != routine.id),
        routine,
      ]);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('“${routine.name}” ya está en tus rutinas.')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No pudimos guardar la rutina.'),
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: () => _save(routine),
            ),
          ),
        );
      }
    }
  }

  Future<void> _create() async {
    final routine = await Navigator.push<TrainingRoutine>(
      context,
      MaterialPageRoute(builder: (_) => const RoutineEditor()),
    );
    if (mounted && routine != null) await _save(routine);
  }

  Future<void> _choose() async {
    final routine = await Navigator.push<TrainingRoutine>(
      context,
      MaterialPageRoute(builder: (_) => const PublishedRoutines()),
    );
    if (mounted && routine != null) await _save(routine);
  }

  Future<void> _teacher() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const TeacherRoutines()),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.profile.name.trim().split(' ').first;
    final today = _routines
        .where((r) => r.days.contains(DateTime.now().weekday))
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        const BrandMark(compact: true),
        const SizedBox(height: 26),
        Text(
          'Hola${name.isEmpty || name == 'Atleta' ? '' : ', $name'}',
          style: const TextStyle(color: AppColors.muted, fontSize: 15),
        ),
        const SizedBox(height: 6),
        Text(
          '¿Cómo querés entrenar?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Creá una rutina, elegí una lista o seguí la de tu profe.',
          style: TextStyle(color: AppColors.muted, height: 1.45),
        ),
        const SizedBox(height: 24),
        _HomeAction(
          title: 'Crear mi rutina',
          description: 'Elegí los ejercicios y armá tu semana.',
          icon: Icons.add_rounded,
          primary: true,
          onTap: _create,
        ),
        const SizedBox(height: 12),
        _HomeAction(
          title: 'Elegir una rutina',
          description: 'Explorá las rutinas listas de EntrenaYa.',
          icon: Icons.explore_outlined,
          onTap: _choose,
        ),
        const SizedBox(height: 12),
        _HomeAction(
          title: 'Rutina de mi profe',
          description: 'Agregá la que te compartió tu profe y empezá.',
          icon: Icons.sports_rounded,
          onTap: _teacher,
        ),
        const SizedBox(height: 24),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          SurfaceCard(
            child: Column(
              children: [
                Text(_error!),
                TextButton(onPressed: _load, child: const Text('Reintentar')),
              ],
            ),
          )
        else if (today.length == 1)
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TU RUTINA PARA HOY',
                  style: TextStyle(
                    color: AppColors.lime,
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  today.single.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 21,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${today.single.exercises.length} ejercicios',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                LimeButton(
                  label: 'Empezar a entrenar',
                  icon: Icons.play_arrow,
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkoutScreen(routine: today.single),
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (today.length > 1)
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tenés ${today.length} rutinas para hoy',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                TextButton(
                  onPressed: widget.onSavedRoutines,
                  child: const Text('Elegir cuál hacer →'),
                ),
              ],
            ),
          ),
        if (!_loading && _error == null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: OutlinedButton.icon(
              onPressed: widget.onSavedRoutines,
              icon: const Icon(Icons.bookmark_border),
              label: Text('Mis rutinas guardadas (${_routines.length})'),
            ),
          ),
        Center(
          child: TextButton(
            onPressed: widget.onProgress,
            child: const Text('Ver mi progreso'),
          ),
        ),
      ],
    );
  }
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;
  @override
  Widget build(BuildContext context) => Material(
    color: primary ? AppColors.lime.withValues(alpha: 0.08) : AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: primary ? AppColors.lime : AppColors.line),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: primary ? AppColors.lime : AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: primary ? AppColors.background : AppColors.lime,
                size: 25,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.muted,
              size: 21,
            ),
          ],
        ),
      ),
    ),
  );
}
