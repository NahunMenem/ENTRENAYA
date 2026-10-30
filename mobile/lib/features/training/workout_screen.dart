import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_theme.dart';
import '../../core/widgets.dart';
import 'exercise_video.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _Series {
  final weight = TextEditingController();
  final reps = TextEditingController();
  bool completed = false;

  Map<String, dynamic> toJson() => {
    'weight': weight.text,
    'reps': reps.text,
    'completed': completed,
  };

  void restore(Map<String, dynamic> data) {
    weight.text = data['weight'] as String? ?? '';
    reps.text = data['reps'] as String? ?? '';
    completed = data['completed'] == true;
  }

  void dispose() {
    weight.dispose();
    reps.dispose();
  }
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  static const _catalog = [
    ('press-banca', 'Press de banca'),
    ('aperturas-mancuernas', 'Aperturas con mancuernas'),
    ('press-inclinado', 'Press inclinado'),
    ('flexiones', 'Flexiones'),
    ('fondos-banco', 'Fondos en banco'),
    ('extension-triceps', 'Extensión de tríceps'),
  ];
  static const _storageKey = 'entrenaya.workouts.v1';
  static const _api = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://entrenaya-production.up.railway.app',
  );
  final _preferences = SharedPreferencesAsync();
  final _series = List.generate(6, (_) => List.generate(4, (_) => _Series()));
  final _videos = <String, String>{};
  List<dynamic> _history = [];
  DateTime _started = DateTime.now();
  DateTime? _restUntil;
  Timer? _timer;
  static Future<void> _writes = Future.value();
  bool _loading = true;
  bool _saving = false;
  bool _loadingVideo = false;
  bool _catalogUnavailable = false;
  String? _storageError;
  int _exercise = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _loadVideos();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _load() async {
    try {
      await _writes;
      final raw = await _preferences.getString(_storageKey);
      if (!mounted) return;
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _history = data['history'] as List<dynamic>? ?? [];
        final draft = data['draft'] as Map<String, dynamic>?;
        if (draft != null) {
          _started = DateTime.parse(draft['started_at'] as String);
          _exercise = (draft['exercise'] as int? ?? 0).clamp(0, 5);
          final saved = draft['exercises'] as Map<String, dynamic>;
          for (var e = 0; e < _catalog.length; e++) {
            final rows = saved[_catalog[e].$1] as List<dynamic>? ?? [];
            for (var s = 0; s < rows.length && s < 4; s++) {
              _series[e][s].restore(rows[s] as Map<String, dynamic>);
            }
          }
        }
      }
    } catch (_) {
      _storageError =
          'No pudimos leer tus registros. Volvé a abrir el entrenamiento.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadVideos() async {
    try {
      final response = await http
          .get(Uri.parse('$_api/api/v1/exercises'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) throw const FormatException();
      final items = jsonDecode(response.body) as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _catalogUnavailable = false;
        _videos.clear();
        for (final item in items.cast<Map<String, dynamic>>()) {
          final url = item['video_url'] as String?;
          final uri = url == null ? null : Uri.tryParse(url);
          if (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty) {
            _videos[item['id'] as String] = url!;
          }
        }
      });
    } catch (_) {
      if (mounted) setState(() => _catalogUnavailable = true);
    }
  }

  Map<String, dynamic> _draft() => {
    'started_at': _started.toIso8601String(),
    'exercise': _exercise,
    'exercises': {
      for (var e = 0; e < _catalog.length; e++)
        _catalog[e].$1: _series[e].map((s) => s.toJson()).toList(),
    },
  };

  Future<void> _persist({bool finish = false}) {
    final draft = _draft();
    final nextHistory = finish
        ? [
            ..._history,
            {...draft, 'finished_at': DateTime.now().toIso8601String()},
          ]
        : _history;
    final encoded = jsonEncode({
      'history': nextHistory,
      'draft': finish ? null : draft,
    });
    // Serialize writes so rapid edits cannot overwrite newer values.
    final write = _writes.then(
      (_) => _preferences.setString(_storageKey, encoded),
    );
    _writes = write.catchError((Object error) {
      if (mounted) {
        setState(
          () => _storageError =
              'No pudimos guardar los cambios en este teléfono.',
        );
      }
    });
    return write;
  }

  void _edited() {
    setState(() {});
    unawaited(_persist().catchError((Object _) {}));
  }

  String _previous(int index) {
    for (final session in _history.reversed) {
      final rows =
          (session['exercises'] as Map<String, dynamic>)[_catalog[_exercise].$1]
              as List<dynamic>?;
      if (rows != null &&
          index < rows.length &&
          rows[index]['completed'] == true) {
        return '${rows[index]['weight']} kg × ${rows[index]['reps']}';
      }
    }
    return '—';
  }

  int get _completed =>
      _series.expand((rows) => rows).where((s) => s.completed).length;

  String _clock(Duration duration) {
    final seconds = duration.inSeconds.clamp(0, 999999);
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _completeSet() async {
    final index = _series[_exercise].indexWhere((s) => !s.completed);
    if (index < 0) return;
    final row = _series[_exercise][index];
    if (!_valid(row)) {
      _message(
        'Ingresá los kilos (0 si usás tu peso corporal) y las repeticiones de la serie ${index + 1}.',
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      row.completed = true;
      _restUntil = DateTime.now().add(const Duration(seconds: 90));
    });
    try {
      await _persist();
    } catch (_) {
      /* Error shown by the write queue. */
    }
  }

  bool _valid(_Series row) {
    final weight = double.tryParse(row.weight.text.replaceAll(',', '.'));
    final reps = int.tryParse(row.reps.text);
    return weight != null &&
        weight.isFinite &&
        weight >= 0 &&
        weight <= 2000 &&
        reps != null &&
        reps > 0 &&
        reps <= 999;
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _finish() async {
    if (_completed == 0) {
      _message('Completá al menos una serie para guardar el entrenamiento.');
      return;
    }
    if (_series.expand((rows) => rows).any((s) => s.completed && !_valid(s))) {
      _message('Revisá los kilos y repeticiones de las series completadas.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Guardar entrenamiento?'),
        content: Text(
          'Se guardarán $_completed series completadas en este teléfono.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir entrenando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar y finalizar'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _saving = true);
    try {
      await _persist(finish: true);
      if (!mounted) return;
      _message('Entrenamiento guardado: $_completed series.');
      Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showVideo() async {
    if (_loadingVideo) return;
    setState(() => _loadingVideo = true);
    // Refresh when opened so newly published administrator videos are picked up.
    await _loadVideos();
    if (!mounted) return;
    setState(() => _loadingVideo = false);
    final url = _videos[_catalog[_exercise].$1];
    if (url == null) {
      _message(
        _catalogUnavailable
            ? 'No pudimos consultar el video. Revisá tu conexión y reintentá.'
            : 'Este ejercicio todavía no tiene un video disponible.',
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ExerciseVideo(name: _catalog[_exercise].$2, url: url),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final row in _series.expand((rows) => rows)) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _series[_exercise];
    final current = rows.indexWhere((s) => !s.completed);
    final remaining = _restUntil?.difference(DateTime.now()) ?? Duration.zero;
    return Scaffold(
      appBar: AppBar(
        title: const Text('PECHO Y TRÍCEPS', style: TextStyle(fontSize: 12)),
        actions: [
          TextButton(
            onPressed: _loading || _saving || _storageError != null
                ? null
                : _finish,
            child: Text(_saving ? 'Guardando…' : 'Finalizar'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : AbsorbPointer(
              absorbing: _saving || _storageError != null,
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_storageError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _storageError!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    const Text(
                      'Tiempo entrenando',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    Text(
                      _clock(DateTime.now().difference(_started)),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'EJERCICIO ${_exercise + 1} DE 6 · ${current < 0 ? '4 SERIES LISTAS' : 'SERIE ${current + 1} DE 4'}',
                      style: const TextStyle(
                        color: AppColors.lime,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _catalog[_exercise].$2,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _loadingVideo ? null : _showVideo,
                        icon: const Icon(Icons.play_circle_outline),
                        label: Text(
                          _loadingVideo
                              ? 'Buscando video…'
                              : 'Ver técnica del ejercicio',
                        ),
                      ),
                    ),
                    const Text(
                      'Ingresá la carga y las repeticiones de cada serie. Usá 0 kg para peso corporal.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    SurfaceCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Row(
                            children: [
                              SizedBox(
                                width: 34,
                                child: Text(
                                  'Serie',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Kilos',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Reps',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                              SizedBox(width: 8),
                              SizedBox(
                                width: 75,
                                child: Text(
                                  'Última vez',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                          for (var index = 0; index < 4; index++)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 34,
                                    child: rows[index].completed
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: AppColors.lime,
                                            size: 20,
                                          )
                                        : Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              color: index == current
                                                  ? AppColors.lime
                                                  : null,
                                            ),
                                          ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      key: ValueKey('${_exercise}_${index}_kg'),
                                      controller: rows[index].weight,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'[0-9,.]'),
                                        ),
                                        LengthLimitingTextInputFormatter(7),
                                      ],
                                      decoration: InputDecoration(
                                        hintText: '0',
                                        isDense: true,
                                        contentPadding: const EdgeInsets.all(
                                          10,
                                        ),
                                        semanticCounterText:
                                            'Kilos serie ${index + 1}',
                                      ),
                                      onChanged: (_) => _edited(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      key: ValueKey(
                                        '${_exercise}_${index}_reps',
                                      ),
                                      controller: rows[index].reps,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(3),
                                      ],
                                      decoration: InputDecoration(
                                        hintText: '12',
                                        isDense: true,
                                        contentPadding: const EdgeInsets.all(
                                          10,
                                        ),
                                        semanticCounterText:
                                            'Repeticiones serie ${index + 1}',
                                      ),
                                      onChanged: (_) => _edited(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 75,
                                    child: Text(
                                      _previous(index),
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (remaining > Duration.zero) ...[
                      SurfaceCard(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              color: AppColors.lime,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('DESCANSO ${_clock(remaining)}'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _restUntil = null),
                              child: const Text('Omitir'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    LimeButton(
                      label: current < 0
                          ? 'Ejercicio completado'
                          : 'Completar serie ${current + 1}',
                      icon: Icons.check_rounded,
                      onPressed: current < 0 ? null : _completeSet,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _exercise == 0
                              ? null
                              : () {
                                  setState(() {
                                    _exercise--;
                                    _restUntil = null;
                                  });
                                  _edited();
                                },
                          child: const Text('← Anterior'),
                        ),
                        TextButton(
                          onPressed: _exercise == 5
                              ? null
                              : () {
                                  setState(() {
                                    _exercise++;
                                    _restUntil = null;
                                  });
                                  _edited();
                                },
                          child: const Text('Siguiente →'),
                        ),
                      ],
                    ),
                    const Text(
                      'Tus series se guardan en este teléfono. Podés cerrar y retomar el entrenamiento.',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
