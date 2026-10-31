import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/app_theme.dart';
import '../../core/widgets.dart';
import '../training/workout_screen.dart';
import 'routine.dart';

class TeacherRoutines extends StatefulWidget {
  const TeacherRoutines({super.key, this.client});
  final http.Client? client;
  @override
  State<TeacherRoutines> createState() => _TeacherRoutinesState();
}

class _TeacherRoutinesState extends State<TeacherRoutines> {
  final _code = TextEditingController();
  final _teacher = TextEditingController();
  final _repository = RoutineRepository();
  late final http.Client _client;
  List<TrainingRoutine> _routines = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _client = widget.client ?? http.Client();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _repository.load();
      if (mounted) {
        setState(() {
          _routines = data.where((r) => r.source == 'teacher').toList();
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'No pudimos leer tus rutinas guardadas. Volvé a abrir esta sección.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _receive() async {
    final code = _code.text.trim().toLowerCase();
    if (!RegExp(r'^[a-fA-F0-9-]{36}$').hasMatch(code)) {
      setState(
        () => _error = 'Pegá el código completo que te compartió tu profe.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      const api = String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://entrenaya-production.up.railway.app',
      );
      final response = await _client
          .get(Uri.parse('$api/api/v1/routines/$code'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 404) {
        throw const FormatException(
          'El código no corresponde a una rutina publicada. Revisalo con tu profe.',
        );
      }
      if (response.statusCode != 200) {
        throw const FormatException('No pudimos obtener la rutina. Reintentá.');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routine = TrainingRoutine.fromJson({
        ...data,
        'id': 'teacher-${data['id']}',
        'source': 'teacher',
        'assigned_by': _teacher.text.trim().isEmpty
            ? 'Tu profe'
            : _teacher.text.trim(),
      });
      final saved = await _repository.load();
      await _repository.save([
        ...saved.where((r) => r.id != routine.id),
        routine,
      ]);
      if (!mounted) return;
      _code.clear();
      FocusScope.of(context).unfocus();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rutina del profe agregada. Ya podés entrenar.'),
          ),
        );
      }
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'No pudimos cargar o guardar la rutina. Revisá tu conexión y reintentá.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    if (widget.client == null) _client.close();
    _code.dispose();
    _teacher.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Rutina de mi profe')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_routines.isEmpty)
                const SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.sports_rounded,
                        color: AppColors.lime,
                        size: 32,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Todavía no agregaste una rutina de tu profe',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Pedile el código de la rutina publicada en EntrenaYa y pegalo abajo.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              for (final routine in _routines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routine.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Compartida por ${routine.assignedBy ?? 'tu profe'}',
                          style: const TextStyle(color: AppColors.lime),
                        ),
                        Text(
                          '${routine.exercises.length} ejercicios · ${routine.days.map((d) => weekDays[d - 1]).join(' · ')}',
                        ),
                        const SizedBox(height: 16),
                        LimeButton(
                          label: 'Hacer esta rutina',
                          icon: Icons.play_arrow,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => WorkoutScreen(routine: routine),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 22),
              const Text(
                'Agregar rutina con código',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _code,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Código de la rutina',
                  hintText: 'Pegá el código que te pasó tu profe',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _teacher,
                maxLength: 80,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre de tu profe (opcional)',
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              LimeButton(
                label: 'Agregar rutina del profe',
                loading: _busy,
                icon: Icons.add,
                onPressed: _busy ? null : _receive,
              ),
              const SizedBox(height: 12),
              const Text(
                'Se guarda una copia en este dispositivo. Si el profe la cambia, podés volver a cargar el mismo código para actualizarla.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
  );
}
