import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/widgets.dart';
import 'exercise_picker.dart';
import 'routine.dart';

class RoutineEditor extends StatefulWidget {
  const RoutineEditor({super.key, this.routine});
  final TrainingRoutine? routine;
  @override
  State<RoutineEditor> createState() => _RoutineEditorState();
}

class _RoutineEditorState extends State<RoutineEditor> {
  late final TextEditingController _name;
  late final Set<int> _days;
  late final List<RoutineExercise> _exercises;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.routine?.name ?? '');
    _days = {...?widget.routine?.days};
    _exercises = [...?widget.routine?.exercises];
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final exercise = await Navigator.push<LibraryExercise>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ExercisePicker(excluded: _exercises.map((e) => e.id).toSet()),
      ),
    );
    if (mounted && exercise != null) {
      setState(
        () => _exercises.add(
          RoutineExercise(id: exercise.id, name: exercise.name),
        ),
      );
    }
  }

  void _save() {
    final error = _name.text.trim().isEmpty
        ? 'Poné un nombre a tu rutina.'
        : _days.isEmpty
        ? 'Elegí al menos un día de la semana.'
        : _exercises.isEmpty
        ? 'Agregá al menos un ejercicio.'
        : null;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.pop(
      context,
      TrainingRoutine(
        id:
            widget.routine?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        name: _name.text.trim(),
        days: _days.toList()..sort(),
        exercises: List.of(_exercises),
      ),
    );
  }

  void _move(int index, int offset) {
    setState(() {
      final exercise = _exercises.removeAt(index);
      _exercises.insert(index + offset, exercise);
    });
  }

  Widget _number(
    int index,
    String label,
    int value,
    List<int> options,
    String field,
  ) => Expanded(
    child: DropdownButtonFormField<int>(
      key: ValueKey('${_exercises[index].id}_$field'),
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),
      ),
      isExpanded: true,
      items: options
          .map(
            (v) => DropdownMenuItem(
              value: v,
              child: Text('$v', style: const TextStyle(fontSize: 13)),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        final e = _exercises[index];
        setState(
          () => _exercises[index] = RoutineExercise(
            id: e.id,
            name: e.name,
            sets: field == 'sets' ? value : e.sets,
            reps: field == 'reps' ? value : e.reps,
            restSeconds: field == 'rest' ? value : e.restSeconds,
          ),
        );
      },
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.routine == null ? 'Crear mi rutina' : 'Editar rutina'),
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LimeButton(
          label: 'Guardar rutina',
          icon: Icons.check,
          onPressed: _save,
        ),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          key: const ValueKey('routine_name'),
          controller: _name,
          maxLength: 80,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Nombre de la rutina',
            hintText: 'Ej.: Piernas y glúteos',
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '¿Qué días la vas a hacer?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: [
            for (var day = 1; day <= 7; day++)
              FilterChip(
                label: Text(weekDays[day - 1]),
                selected: _days.contains(day),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _days.add(day);
                  } else {
                    _days.remove(day);
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Ejercicios en orden',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        const Text(
          'Definí las series, repeticiones objetivo y descanso en segundos. El peso lo vas a cargar al entrenar.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 14),
        if (_exercises.isEmpty)
          const Text('Agregá ejercicios desde la biblioteca para empezar.'),
        for (var i = 0; i < _exercises.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}. ${_exercises[i].name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _number(
                        i,
                        'Series',
                        _exercises[i].sets,
                        List.generate(10, (i) => i + 1),
                        'sets',
                      ),
                      const SizedBox(width: 8),
                      _number(
                        i,
                        'Reps',
                        _exercises[i].reps,
                        List.generate(50, (i) => i + 1),
                        'reps',
                      ),
                      const SizedBox(width: 8),
                      _number(i, 'Descanso (s)', _exercises[i].restSeconds, [
                        0,
                        30,
                        60,
                        90,
                        120,
                        180,
                        240,
                        300,
                      ], 'rest'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: 'Subir ejercicio',
                        onPressed: i == 0 ? null : () => _move(i, -1),
                        icon: const Icon(Icons.arrow_upward, size: 20),
                      ),
                      IconButton(
                        tooltip: 'Bajar ejercicio',
                        onPressed: i == _exercises.length - 1
                            ? null
                            : () => _move(i, 1),
                        icon: const Icon(Icons.arrow_downward, size: 20),
                      ),
                      IconButton(
                        tooltip: 'Quitar ejercicio',
                        onPressed: () => setState(() => _exercises.removeAt(i)),
                        icon: const Icon(Icons.delete_outline, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: _add,
          icon: const Icon(Icons.add),
          label: const Text('Agregar ejercicio'),
        ),
        const SizedBox(height: 20),
      ],
    ),
  );
}
