import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'routine.dart';

class ExercisePicker extends StatefulWidget {
  const ExercisePicker({super.key, this.excluded = const {}});
  final Set<String> excluded;
  @override
  State<ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<ExercisePicker> {
  List<LibraryExercise> _items = exerciseLibrary;
  String _query = '';
  String _group = 'Todos';
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await loadExerciseLibrary();
    if (mounted) setState(() => _items = items);
  }

  String _normalize(String text) => text
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');
  @override
  Widget build(BuildContext context) {
    final items = _items
        .where(
          (e) =>
              (_group == 'Todos' || e.group == _group) &&
              _normalize(e.name).contains(_normalize(_query)),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Biblioteca de ejercicios')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar ejercicio',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final group in [
                  'Todos',
                  ..._items.map((e) => e.group).toSet(),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(group),
                      selected: _group == group,
                      onSelected: (_) => setState(() => _group = group),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text('No encontramos ejercicios con esa búsqueda.'),
                  )
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final exercise = items[index];
                      final added = widget.excluded.contains(exercise.id);
                      return ListTile(
                        title: Text(exercise.name),
                        subtitle: Text(exercise.group),
                        leading: const Icon(
                          Icons.fitness_center,
                          color: AppColors.lime,
                        ),
                        trailing: Icon(
                          added ? Icons.check_circle : Icons.add_circle_outline,
                        ),
                        enabled: !added,
                        onTap: () => Navigator.pop(context, exercise),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
