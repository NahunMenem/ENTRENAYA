import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_theme.dart';
import '../../core/widgets.dart';
import 'exercise_video.dart';
import '../routines/routine.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key, this.routine});
  final TrainingRoutine? routine;

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
  static const _defaultCatalog = [
    ('press-banca', 'Press de banca'),
    ('aperturas-mancuernas', 'Aperturas con mancuernas'),
    ('press-inclinado', 'Press inclinado'),
    ('flexiones', 'Flexiones'),
    ('fondos-banco', 'Fondos en banco'),
    ('extension-triceps', 'Extensión de tríceps'),
  ];
  String get _storageKey => widget.routine == null
      ? 'entrenaya.workouts.v1'
      : 'entrenaya.workouts.routine.${widget.routine!.id}';
  late final List<RoutineExercise> _plan;
  late final List<(String, String)> _catalog;
  static const _api = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://entrenaya-production.up.railway.app',
  );
  late final _preferences = SharedPreferencesAsync();
  late final List<List<_Series>> _series;
  final _videos = <String, String>{};
  List<dynamic> _history = [];
  DateTime _started = DateTime.now();
  DateTime? _restUntil;
  Timer? _timer;
  static Future<void>? _writes;
  bool _loading = true;
  bool _saving = false;
  bool _loadingVideo = false;
  bool _catalogUnavailable = false;
  String? _storageError;
  int _exercise = 0;
  final _scrollController = ScrollController();
  late final List<List<GlobalKey>> _seriesKeys;

  @override
  void initState() {
    super.initState();
    _plan =
        widget.routine?.exercises ??
        _defaultCatalog
            .map((e) => RoutineExercise(id: e.$1, name: e.$2, sets: 4))
            .toList();
    _catalog = _plan.map((e) => (e.id, e.name)).toList();
    _series = _plan
        .map((e) => List.generate(e.sets, (_) => _Series()))
        .toList();
    _seriesKeys = _plan
        .map((e) => List.generate(e.sets, (_) => GlobalKey()))
        .toList();
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
          _exercise = (draft['exercise'] as int? ?? 0).clamp(
            0,
            _catalog.length - 1,
          );
          final saved = draft['exercises'] as Map<String, dynamic>;
          for (var e = 0; e < _catalog.length; e++) {
            final rows = saved[_catalog[e].$1] as List<dynamic>? ?? [];
            for (var s = 0; s < rows.length && s < _series[e].length; s++) {
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
    final write = (_writes ?? Future<void>.value()).then(
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
    final pending = _writes;
    pending!.then((_) {
      if (identical(_writes, pending)) _writes = null;
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
      _restUntil = DateTime.now().add(
        Duration(seconds: _plan[_exercise].restSeconds),
      );
    });
    _revealCurrentSeries();
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
    _scrollController.dispose();
    for (final row in _series.expand((rows) => rows)) {
      row.dispose();
    }
    super.dispose();
  }

  void _revealCurrentSeries() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current = _series[_exercise].indexWhere((s) => !s.completed);
      if (current < 0) return;
      final context = _seriesKeys[_exercise][current].currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 250),
          alignment: 0.15,
        );
      }
    });
  }

  Widget _seriesCard(int index, int current) {
    final row = _series[_exercise][index];
    final active = index == current;
    final previous = _previous(index);
    return Container(
      key: _seriesKeys[_exercise][index],
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: active
            ? AppColors.lime.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active ? AppColors.lime : AppColors.line,
          width: active ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (row.completed) ...[
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.lime,
                  size: 18,
                ),
                const SizedBox(width: 7),
              ],
              Expanded(
                child: Text(
                  'Serie ${index + 1}',
                  style: TextStyle(
                    color: active ? AppColors.lime : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                row.completed
                    ? 'Guardada'
                    : active
                    ? 'Serie actual'
                    : 'Pendiente',
                style: TextStyle(
                  color: active || row.completed
                      ? AppColors.lime
                      : AppColors.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  key: ValueKey('${_exercise}_${index}_kg'),
                  controller: row.weight,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                    LengthLimitingTextInputFormatter(7),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Peso (kg)',
                    hintText: 'Ingresá peso',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    hintStyle: TextStyle(color: AppColors.muted, fontSize: 12),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 15,
                    ),
                  ),
                  onChanged: (_) => _edited(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  key: ValueKey('${_exercise}_${index}_reps'),
                  controller: row.reps,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Repeticiones',
                    hintText: 'Ingresá reps',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    hintStyle: TextStyle(color: AppColors.muted, fontSize: 12),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 15,
                    ),
                  ),
                  onChanged: (_) => _edited(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            previous == '—'
                ? 'Sesión anterior: sin registros'
                : 'Sesión anterior: $previous',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _changeExercise(int offset) {
    FocusScope.of(context).unfocus();
    setState(() {
      _exercise += offset;
      _restUntil = null;
    });
    _edited();
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final current = _series[_exercise].indexWhere((s) => !s.completed);
    final remaining = _restUntil?.difference(DateTime.now()) ?? Duration.zero;
    final resting = remaining > Duration.zero;
    final blocked = _saving || _storageError != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.routine?.name ?? 'PECHO Y TRÍCEPS',
          style: const TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: _loading || blocked ? null : _finish,
            child: Text(_saving ? 'Guardando…' : 'Finalizar'),
          ),
        ],
      ),
      bottomNavigationBar: _loading
          ? null
          : SafeArea(
              top: false,
              child: AbsorbPointer(
                absorbing: blocked,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (resting) ...[
                        SurfaceCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                color: AppColors.lime,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Descanso ${_clock(remaining)}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _restUntil = null),
                                child: const Text(
                                  'Omitir descanso',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: FilledButton.icon(
                          onPressed: current < 0 || resting
                              ? null
                              : _completeSet,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.lime,
                            foregroundColor: AppColors.background,
                            disabledBackgroundColor: AppColors.surfaceRaised,
                            disabledForegroundColor: AppColors.muted,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(17),
                            ),
                          ),
                          icon: Icon(
                            current < 0
                                ? Icons.check_circle_outline
                                : resting
                                ? Icons.timer_outlined
                                : Icons.check_rounded,
                            size: 20,
                          ),
                          label: Text(
                            current < 0
                                ? 'Ejercicio completado'
                                : resting
                                ? 'Descansando…'
                                : 'Guardar serie ${current + 1}${_plan[_exercise].restSeconds == 0 ? '' : ' e iniciar descanso'}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: _exercise == 0
                                  ? null
                                  : () => _changeExercise(-1),
                              child: const Text(
                                '← Ejercicio anterior',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextButton(
                              onPressed: _exercise == _catalog.length - 1
                                  ? null
                                  : () => _changeExercise(1),
                              child: const Text(
                                'Siguiente ejercicio →',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : AbsorbPointer(
              absorbing: blocked,
              child: SafeArea(
                bottom: false,
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
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
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    Text(
                      _clock(DateTime.now().difference(_started)),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'EJERCICIO ${_exercise + 1} DE ${_catalog.length} · ${current < 0 ? '${_series[_exercise].length} SERIES GUARDADAS' : 'SERIE ${current + 1} DE ${_series[_exercise].length}'}',
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
                      'Cargá el peso y las repeticiones de la serie actual. Después guardala para iniciar el descanso.',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Si usás solo tu peso corporal, ingresá 0 kg.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Objetivo: ${_plan[_exercise].reps} repeticiones por serie · ${_plan[_exercise].restSeconds} s de descanso',
                      style: const TextStyle(
                        color: AppColors.lime,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Column(
                      children: [
                        for (
                          var index = 0;
                          index < _series[_exercise].length;
                          index++
                        )
                          _seriesCard(index, current),
                      ],
                    ),
                    const Text(
                      'Tus series se guardan en este dispositivo. Podés cerrar y retomar el entrenamiento.',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
