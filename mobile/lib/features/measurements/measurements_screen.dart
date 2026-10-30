import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/widgets.dart';
import 'measurement.dart';
import 'measurement_form.dart';

class MeasurementsScreen extends StatefulWidget {
  const MeasurementsScreen({super.key, this.weightOnly = false});
  final bool weightOnly;

  @override
  State<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends State<MeasurementsScreen> {
  final _repository = MeasurementRepository();
  List<MeasurementEntry> _entries = [];
  late BodyMeasure _metric;
  List<BodyMeasure> get _metrics => trackedMetrics(widget.weightOnly);
  List<MeasurementEntry> get _visibleEntries =>
      _entries.where((e) => _metrics.any(e.values.containsKey)).toList();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _metric = widget.weightOnly ? BodyMeasure.weight : BodyMeasure.waist;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await _repository.load();
      if (mounted) setState(() => _entries = entries);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'No pudimos leer tus registros. Reintentá para continuar.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(List<MeasurementEntry> entries) async {
    setState(() => _saving = true);
    try {
      await _repository.save(entries);
      if (!mounted) return;
      setState(() => _entries = orderedMeasurements(entries));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.weightOnly ? 'Peso guardado.' : 'Medidas guardadas.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No pudimos guardar los cambios. Reintentá.'),
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: () => _save(entries),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _edit([MeasurementEntry? existing]) async {
    final entry = await Navigator.push<MeasurementEntry>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MeasurementForm(entry: existing, weightOnly: widget.weightOnly),
      ),
    );
    if (!mounted || entry == null) return;
    await _save([..._entries.where((e) => e.id != entry.id), entry]);
  }

  Future<void> _delete(MeasurementEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar registro?'),
        content: Text(
          'Se eliminará este registro del ${measureDate(entry.date)}.',
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
      final preserved = Map<BodyMeasure, double>.from(entry.values)
        ..removeWhere((metric, _) => _metrics.contains(metric));
      await _save([
        ..._entries.where((e) => e.id != entry.id),
        if (preserved.isNotEmpty)
          MeasurementEntry(id: entry.id, date: entry.date, values: preserved),
      ]);
    }
  }

  String _delta(double value) =>
      '${value > 0 ? '+' : ''}${measureNumber(value)} ${_metric.unit}';

  @override
  Widget build(BuildContext context) {
    final points = measurementsFor(_entries, _metric);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.weightOnly ? 'Mi peso' : 'Mis medidas'),
      ),
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
                    TextButton(
                      onPressed: _load,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : AbsorbPointer(
              absorbing: _saving,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  SectionHeading(
                    title: 'Tu evolución',
                    subtitle: widget.weightOnly
                        ? 'Registrá tu peso y compará los cambios con el tiempo.'
                        : 'Registrá tus medidas y compará los cambios con el tiempo.',
                  ),
                  const SizedBox(height: 18),
                  LimeButton(
                    label: _saving
                        ? 'Guardando…'
                        : widget.weightOnly
                        ? 'Registrar peso'
                        : 'Registrar medidas',
                    loading: _saving,
                    icon: Icons.add_rounded,
                    onPressed: _edit,
                  ),
                  const SizedBox(height: 20),
                  if (_visibleEntries.isEmpty)
                    const SurfaceCard(
                      child: Column(
                        children: [
                          Icon(
                            Icons.straighten_rounded,
                            color: AppColors.lime,
                            size: 36,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Tu primer registro es el punto de partida.',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Agregá un registro. Con el próximo vas a poder comparar los cambios.',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        for (final metric in _metrics)
                          ChoiceChip(
                            label: Text(metric.label),
                            selected: _metric == metric,
                            onSelected: (_) => setState(() => _metric = metric),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _metric.label,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (points.isEmpty)
                            const Text(
                              'Todavía no registraste esta medida.',
                              style: TextStyle(color: AppColors.muted),
                            )
                          else ...[
                            Text(
                              '${measureNumber(points.last.values[_metric]!)} ${_metric.unit}',
                              key: const ValueKey('latest_measurement'),
                              style: const TextStyle(
                                color: AppColors.lime,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Último registro: ${measureDate(points.last.date)}',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                            if (points.length > 1) ...[
                              const SizedBox(height: 12),
                              Text(
                                '${_delta(points.last.values[_metric]! - points.first.values[_metric]!)} desde el primer registro',
                                key: const ValueKey('total_measurement_change'),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${_delta(points.last.values[_metric]! - points[points.length - 2].values[_metric]!)} respecto al anterior',
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Rango: ${measureNumber(points.map((e) => e.values[_metric]!).reduce(math.min))}–${measureNumber(points.map((e) => e.values[_metric]!).reduce(math.max))} ${_metric.unit}',
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Semantics(
                                label:
                                    'Evolución de ${_metric.label}. ${points.map((e) => '${measureDate(e.date)}: ${measureNumber(e.values[_metric]!)} ${_metric.unit}').join('; ')}',
                                child: SizedBox(
                                  height: 150,
                                  width: double.infinity,
                                  child: CustomPaint(
                                    painter: MeasurementTrendChart(
                                      points,
                                      _metric,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    measureDate(points.first.date),
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    measureDate(points.last.date),
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              const SizedBox(height: 10),
                              const Text(
                                'Agregá otro registro de esta medida para ver la evolución.',
                                style: TextStyle(color: AppColors.muted),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.weightOnly
                          ? 'Historial de peso'
                          : 'Historial de medidas',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final entry in _visibleEntries.reversed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      measureDate(entry.date),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Editar registro',
                                    onPressed: () => _edit(entry),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Eliminar registro',
                                    onPressed: () => _delete(entry),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                              for (final metric in _metrics)
                                if (entry.values[metric] != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            metric.label,
                                            style: const TextStyle(
                                              color: AppColors.muted,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${measureNumber(entry.values[metric]!)} ${metric.unit}',
                                        ),
                                      ],
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    'Guardado en este teléfono. La sincronización con tu cuenta estará disponible más adelante.',
                    style: TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
    );
  }
}

class MeasurementTrendChart extends CustomPainter {
  const MeasurementTrendChart(this.points, this.metric);
  final List<MeasurementEntry> points;
  final BodyMeasure metric;

  @override
  void paint(Canvas canvas, Size size) {
    final values = points.map((e) => e.values[metric]!).toList();
    final minimum = values.reduce(math.min);
    final maximum = values.reduce(math.max);
    final span = math.max(maximum - minimum, 1.0);
    final start = points.first.date.millisecondsSinceEpoch;
    final end = points.last.date.millisecondsSinceEpoch;
    final line = Paint()
      ..color = AppColors.lime
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final grid = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = 10 + (size.height - 20) * i / 3;
      canvas.drawLine(Offset(8, y), Offset(size.width - 8, y), grid);
    }
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final fraction = end == start
          ? i / (points.length - 1)
          : (points[i].date.millisecondsSinceEpoch - start) / (end - start);
      final x = 8 + fraction * (size.width - 16);
      final y = maximum == minimum
          ? size.height / 2
          : 10 + (maximum - values[i]) / span * (size.height - 20);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = AppColors.lime);
    }
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant MeasurementTrendChart oldDelegate) =>
      oldDelegate.points != points || oldDelegate.metric != metric;
}
