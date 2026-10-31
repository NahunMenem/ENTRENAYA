import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/app_theme.dart';
import '../../core/widgets.dart';
import 'routine.dart';

class PublishedRoutines extends StatefulWidget {
  const PublishedRoutines({super.key});
  @override
  State<PublishedRoutines> createState() => _PublishedRoutinesState();
}

class _PublishedRoutinesState extends State<PublishedRoutines> {
  List<Map<String, dynamic>> _routines = [];
  bool _loading = true;
  String? _error;
  String _category = 'Todas';
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      const api = String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://entrenaya-production.up.railway.app',
      );
      final response = await http
          .get(Uri.parse('$api/api/v1/routines'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) throw const FormatException();
      final data = (jsonDecode(response.body) as List)
          .cast<Map<String, dynamic>>();
      if (mounted) setState(() => _routines = data);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'No pudimos cargar las rutinas. Revisá tu conexión y reintentá.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _adopt(Map<String, dynamic> row) {
    Navigator.pop(
      context,
      TrainingRoutine.fromJson({
        ...row,
        'id': 'local-${DateTime.now().microsecondsSinceEpoch}',
      }),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Explorar rutinas')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  TextButton(onPressed: _load, child: const Text('Reintentar')),
                ],
              ),
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SectionHeading(
                title: 'Elegí tu próximo plan',
                subtitle:
                    'Rutinas publicadas por EntrenaYa. Podés agregarlas a tu semana y adaptarlas.',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 6,
                children: [
                  for (final value in [
                    'Todas',
                    'Hipertrofia',
                    'Déficit',
                    'Volumen',
                    'Fuerza',
                    'Mantenimiento',
                  ])
                    ChoiceChip(
                      label: Text(value),
                      selected: _category == value,
                      onSelected: (_) => setState(() => _category = value),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_routines
                  .where(
                    (r) => _category == 'Todas' || r['category'] == _category,
                  )
                  .isEmpty)
                const SurfaceCard(
                  child: Text(
                    'Todavía no hay rutinas publicadas en esta categoría.',
                  ),
                ),
              for (final row in _routines.where(
                (r) => _category == 'Todas' || r['category'] == _category,
              ))
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${row['category']} · ${row['level']}',
                          style: const TextStyle(
                            color: AppColors.lime,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          row['name'] as String,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if ((row['description'] as String).isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(row['description'] as String),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          'Días sugeridos: ${(row['days'] as List).map((d) => weekDays[(d as int) - 1]).join(' · ')}',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 12),
                        for (final exercise in row['exercises'] as List)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '${exercise['name']} · ${exercise['sets']} × ${exercise['reps']} reps · ${exercise['rest_seconds']} s',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        const SizedBox(height: 12),
                        LimeButton(
                          label: 'Usar esta rutina',
                          icon: Icons.add,
                          onPressed: () => _adopt(row),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
  );
}
