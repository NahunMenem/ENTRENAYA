import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/widgets.dart';
import '../training/workout_screen.dart';
import 'routine.dart';
import 'routine_editor.dart';

class RoutinesScreen extends StatefulWidget {
  const RoutinesScreen({super.key});
  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  final _repository = RoutineRepository();
  List<TrainingRoutine> _routines = [];
  bool _loading = true;
  bool _failed = false;
  bool _saving = false;
  int? _day;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _repository.load();
      if (mounted) {
        setState(() {
          _routines = data;
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(List<TrainingRoutine> routines) async {
    setState(() => _saving = true);
    try {
      await _repository.save(routines);
      if (mounted) setState(() => _routines = routines);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No pudimos guardar la rutina.'),
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: () => _save(routines),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _edit([TrainingRoutine? previous]) async {
    final routine = await Navigator.push<TrainingRoutine>(
      context,
      MaterialPageRoute(builder: (_) => RoutineEditor(routine: previous)),
    );
    if (mounted && routine != null) {
      await _save([..._routines.where((e) => e.id != routine.id), routine]);
    }
  }

  Future<void> _delete(TrainingRoutine routine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar rutina?'),
        content: Text(
          'Se eliminará “${routine.name}” de tu semana. Los entrenamientos registrados se conservan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (mounted && confirmed == true) {
      await _save(_routines.where((e) => e.id != routine.id).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final routines = _routines
        .where((routine) => _day == null || routine.days.contains(_day))
        .toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionHeading(
          title: 'Mis rutinas',
          subtitle: 'Armá tu semana y entrená a tu manera.',
        ),
        const SizedBox(height: 18),
        LimeButton(
          label: 'Crear mi rutina',
          icon: Icons.add,
          onPressed: _loading || _saving || _failed ? null : _edit,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 6,
          children: [
            ChoiceChip(
              label: const Text('Todas'),
              selected: _day == null,
              onSelected: (_) => setState(() => _day = null),
            ),
            for (var day = 1; day <= 7; day++)
              ChoiceChip(
                label: Text(weekDays[day - 1]),
                selected: _day == day,
                onSelected: (_) => setState(() => _day = day),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_loading || _saving)
          const Center(child: CircularProgressIndicator())
        else if (_failed)
          TextButton(
            onPressed: _load,
            child: const Text('No pudimos leer tus rutinas. Reintentar'),
          )
        else if (routines.isEmpty)
          const SurfaceCard(
            child: Text(
              'Todavía no tenés rutinas para estos días. Creá una, elegí los ejercicios y asignala a tu semana.',
            ),
          ),
        if (!_loading && !_saving && !_failed)
          for (final routine in routines)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.name,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      routine.days.map((d) => weekDays[d - 1]).join(' · '),
                      style: const TextStyle(color: AppColors.lime),
                    ),
                    const SizedBox(height: 10),
                    for (final e in routine.exercises)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '${e.name} · ${e.sets} × ${e.reps} reps · ${e.restSeconds} s',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    LimeButton(
                      label: 'Entrenar esta rutina',
                      icon: Icons.play_arrow,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => WorkoutScreen(routine: routine),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _edit(routine),
                          child: const Text('Editar'),
                        ),
                        TextButton(
                          onPressed: () => _delete(routine),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 10),
        const Text(
          'Rutinas guardadas en este dispositivo. Elegí varios días si querés repetir la misma rutina.',
          style: TextStyle(color: AppColors.muted, fontSize: 11),
        ),
      ],
    );
  }
}
