import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
import '../../core/widgets.dart';
import 'measurement.dart';

class MeasurementForm extends StatefulWidget {
  const MeasurementForm({super.key, this.entry, this.weightOnly = false});
  final MeasurementEntry? entry;
  final bool weightOnly;

  @override
  State<MeasurementForm> createState() => _MeasurementFormState();
}

class _MeasurementFormState extends State<MeasurementForm> {
  final _form = GlobalKey<FormState>();
  late DateTime _date;
  late final Map<BodyMeasure, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = widget.entry?.date ?? DateTime(now.year, now.month, now.day);
    _controllers = {
      for (final metric in trackedMetrics(widget.weightOnly))
        metric: TextEditingController(
          text: widget.entry?.values[metric] == null
              ? ''
              : measureNumber(widget.entry!.values[metric]!),
        ),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'Fecha de la medición',
    );
    if (mounted && selected != null) setState(() => _date = selected);
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final values = <BodyMeasure, double>{};
    for (final item in _controllers.entries) {
      final raw = item.value.text.trim();
      if (raw.isNotEmpty) {
        values[item.key] = double.parse(raw.replaceAll(',', '.'));
      }
    }
    if (values.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.weightOnly
                ? 'Ingresá tu peso.'
                : 'Ingresá al menos una medida.',
          ),
        ),
      );
      return;
    }
    // Preserve any other measurements attached to the same record.
    for (final item
        in widget.entry?.values.entries ?? <MapEntry<BodyMeasure, double>>[]) {
      if (!_controllers.containsKey(item.key)) values[item.key] = item.value;
    }
    Navigator.pop(
      context,
      MeasurementEntry(
        id:
            widget.entry?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        date: _date,
        values: values,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.entry == null
            ? (widget.weightOnly ? 'Registrar peso' : 'Registrar medidas')
            : (widget.weightOnly ? 'Editar peso' : 'Editar medidas'),
      ),
    ),
    body: SafeArea(
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.weightOnly
                  ? 'Registrá tu peso en kilogramos y la fecha para seguir tu evolución.'
                  : 'Todas las medidas en centímetros. Podés completar solo las que quieras registrar.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _selectDate,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text('Fecha: ${measureDate(_date)}'),
            ),
            const SizedBox(height: 16),
            for (final metric in trackedMetrics(widget.weightOnly))
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: TextFormField(
                  key: ValueKey('measure_${metric.name}'),
                  controller: _controllers[metric],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: InputDecoration(
                    labelText: metric.label,
                    suffixText: metric.unit,
                    hintText: widget.weightOnly ? 'Ej.: 82,4' : 'Ej.: 35,5',
                  ),
                  validator: (raw) {
                    if (raw == null || raw.trim().isEmpty) return null;
                    final normalized = raw.trim().replaceAll(',', '.');
                    final value = double.tryParse(normalized);
                    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(normalized) ||
                        value == null ||
                        !value.isFinite ||
                        value <= 0 ||
                        value > (widget.weightOnly ? 1000 : 400)) {
                      return widget.weightOnly
                          ? 'Ingresá un peso mayor que 0 y de hasta 1000 kg.'
                          : 'Ingresá un valor entre 0 y 400 cm, mayor que 0.';
                    }
                    return null;
                  },
                ),
              ),
            Text(
              widget.weightOnly
                  ? 'Para comparar tus registros, pesate en condiciones similares y con la misma balanza.'
                  : 'Para comparar mejor, usá siempre la misma referencia y postura. En espalda, registrá el contorno del torso a la altura que elijas y mantené ese criterio.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 24),
            LimeButton(
              label: widget.weightOnly ? 'Guardar peso' : 'Guardar medidas',
              icon: Icons.check_rounded,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    ),
  );
}
