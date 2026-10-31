import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LibraryExercise {
  const LibraryExercise(
    this.id,
    this.name,
    this.group, {
    this.coverUrl,
    this.videoUrl,
    this.instructions = '',
    this.equipment = '',
  });
  final String id;
  final String name;
  final String group;
  final String? coverUrl;
  final String? videoUrl;
  final String instructions;
  final String equipment;
}

const exerciseLibrary = [
  LibraryExercise('press-banca', 'Press de banca', 'Pecho'),
  LibraryExercise('aperturas-mancuernas', 'Aperturas con mancuernas', 'Pecho'),
  LibraryExercise('press-inclinado', 'Press inclinado', 'Pecho'),
  LibraryExercise('flexiones', 'Flexiones', 'Pecho'),
  LibraryExercise('remo-mancuerna', 'Remo con mancuerna', 'Espalda'),
  LibraryExercise('jalon-pecho', 'Jalón al pecho', 'Espalda'),
  LibraryExercise('remo-polea', 'Remo en polea', 'Espalda'),
  LibraryExercise('dominadas', 'Dominadas', 'Espalda'),
  LibraryExercise('sentadilla', 'Sentadilla', 'Piernas'),
  LibraryExercise('prensa', 'Prensa de piernas', 'Piernas'),
  LibraryExercise('zancadas', 'Zancadas', 'Piernas'),
  LibraryExercise('peso-muerto-rumano', 'Peso muerto rumano', 'Piernas'),
  LibraryExercise('hip-thrust', 'Hip thrust', 'Piernas'),
  LibraryExercise('elevacion-gemelos', 'Elevación de gemelos', 'Piernas'),
  LibraryExercise('press-militar', 'Press militar', 'Hombros'),
  LibraryExercise('elevaciones-laterales', 'Elevaciones laterales', 'Hombros'),
  LibraryExercise('curl-biceps', 'Curl de bíceps', 'Brazos'),
  LibraryExercise('curl-martillo', 'Curl martillo', 'Brazos'),
  LibraryExercise('fondos-banco', 'Fondos en banco', 'Brazos'),
  LibraryExercise('extension-triceps', 'Extensión de tríceps', 'Brazos'),
  LibraryExercise('plancha', 'Plancha con toque de hombros', 'Abdominales'),
  LibraryExercise('crunch', 'Crunch abdominal', 'Abdominales'),
];

Future<List<LibraryExercise>> loadExerciseLibrary() async {
  final items = {for (final exercise in exerciseLibrary) exercise.id: exercise};
  const api = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://entrenaya-production.up.railway.app',
  );
  try {
    final response = await http
        .get(Uri.parse('$api/api/v1/exercises'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      // The server is authoritative: unpublished exercises must disappear online.
      final published = <String, LibraryExercise>{};
      for (final row
          in (jsonDecode(response.body) as List).cast<Map<String, dynamic>>()) {
        final id = row['id'] as String;
        published[id] = LibraryExercise(
          id,
          row['name'] as String,
          row['muscle_group'] as String? ?? items[id]?.group ?? 'Otros',
          coverUrl: row['cover_url'] == null
              ? null
              : Uri.parse(api).resolve(row['cover_url'] as String).toString(),
          videoUrl: row['video_url'] as String?,
          instructions: row['instructions'] as String? ?? '',
          equipment: row['equipment'] as String? ?? '',
        );
      }
      return published.values.toList();
    }
  } catch (_) {
    // The bundled library remains available offline.
  }
  return items.values.toList();
}

class RoutineExercise {
  const RoutineExercise({
    required this.id,
    required this.name,
    this.sets = 3,
    this.reps = 12,
    this.restSeconds = 90,
  });
  final String id;
  final String name;
  final int sets;
  final int reps;
  final int restSeconds;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sets': sets,
    'reps': reps,
    'rest_seconds': restSeconds,
  };
  factory RoutineExercise.fromJson(Map<String, dynamic> row) => RoutineExercise(
    id: row['id'] as String,
    name: row['name'] as String,
    sets: row['sets'] as int,
    reps: row['reps'] as int,
    restSeconds: row['rest_seconds'] as int,
  );
}

class TrainingRoutine {
  const TrainingRoutine({
    required this.id,
    required this.name,
    required this.days,
    required this.exercises,
    this.source,
    this.assignedBy,
  });
  final String id;
  final String name;
  final List<int> days;
  final List<RoutineExercise> exercises;
  final String? source;
  final String? assignedBy;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'days': days,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'source': source,
    'assigned_by': assignedBy,
  };
  factory TrainingRoutine.fromJson(Map<String, dynamic> row) => TrainingRoutine(
    id: row['id'] as String,
    name: row['name'] as String,
    days: (row['days'] as List).cast<int>(),
    source: row['source'] as String?,
    assignedBy: row['assigned_by'] as String?,
    exercises: (row['exercises'] as List)
        .map((e) => RoutineExercise.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

const weekDays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

class RoutineRepository {
  static const storageKey = 'entrenaya.routines.v1';
  late final _preferences = SharedPreferencesAsync();
  Future<List<TrainingRoutine>> load() async {
    final raw = await _preferences.getString(storageKey);
    return raw == null
        ? []
        : (jsonDecode(raw) as List)
              .map((e) => TrainingRoutine.fromJson(e as Map<String, dynamic>))
              .toList();
  }

  Future<void> save(List<TrainingRoutine> routines) => _preferences.setString(
    storageKey,
    jsonEncode(routines.map((e) => e.toJson()).toList()),
  );
}
