import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum BodyMeasure {
  leftArm('Brazo izquierdo'),
  rightArm('Brazo derecho'),
  leftLeg('Pierna izquierda'),
  rightLeg('Pierna derecha'),
  waist('Cintura'),
  back('Espalda');

  const BodyMeasure(this.label);
  final String label;
}

class MeasurementEntry {
  const MeasurementEntry({
    required this.id,
    required this.date,
    required this.values,
  });
  final String id;
  final DateTime date;
  final Map<BodyMeasure, double> values;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'values': {for (final item in values.entries) item.key.name: item.value},
  };

  factory MeasurementEntry.fromJson(Map<String, dynamic> data) {
    final values = data['values'] as Map<String, dynamic>;
    return MeasurementEntry(
      id: data['id'] as String,
      date: DateTime.parse(data['date'] as String),
      values: {
        for (final metric in BodyMeasure.values)
          if (values[metric.name] != null)
            metric: (values[metric.name] as num).toDouble(),
      },
    );
  }
}

List<MeasurementEntry> orderedMeasurements(
  Iterable<MeasurementEntry> entries,
) => entries.toList()
  ..sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    return byDate == 0 ? a.id.compareTo(b.id) : byDate;
  });

List<MeasurementEntry> measurementsFor(
  Iterable<MeasurementEntry> entries,
  BodyMeasure metric,
) => orderedMeasurements(
  entries.where((entry) => entry.values.containsKey(metric)),
);

String measureNumber(double value) =>
    (value == value.roundToDouble()
            ? value.toStringAsFixed(0)
            : value.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), ''))
        .replaceAll('.', ',');

String measureDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

class MeasurementRepository {
  static const storageKey = 'entrenaya.measurements.v1';
  late final _preferences = SharedPreferencesAsync();

  Future<List<MeasurementEntry>> load() async {
    final raw = await _preferences.getString(storageKey);
    if (raw == null) return [];
    final data = jsonDecode(raw) as List<dynamic>;
    return orderedMeasurements(
      data.map(
        (item) => MeasurementEntry.fromJson(item as Map<String, dynamic>),
      ),
    );
  }

  Future<void> save(List<MeasurementEntry> entries) => _preferences.setString(
    storageKey,
    jsonEncode(orderedMeasurements(entries).map((e) => e.toJson()).toList()),
  );
}
