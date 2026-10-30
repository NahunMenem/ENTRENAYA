import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
import '../../core/widgets.dart';
import 'measurement.dart';

class MeasurementForm extends StatefulWidget {
  const MeasurementForm({super.key, this.entry});
  final MeasurementEntry? entry;

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
      for (final metric in BodyMeasure.values)
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
        const SnackBar(content: Text('Ingresá al menos una medida.')),
      );
      return;
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
        widget.entry == null ? 'Registrar medidas' : 'Editar medidas',
      ),
    ),
    body: SafeArea(
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Todas las medidas en centímetros. Podés completar solo las que quieras registrar.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _selectDate,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text('Fecha: ${measureDate(_date)}'),
            ),
            const SizedBox(height: 16),
            for (final metric in BodyMeasure.values)
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
                    suffixText: 'cm',
                    hintText: 'Ej.: 35,5',
                  ),
                  validator: (raw) {
                    if (raw == null || raw.trim().isEmpty) return null;
                    final normalized = raw.trim().replaceAll(',', '.');
                    final value = double.tryParse(normalized);
                    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(normalized) ||
                        value == null ||
                        !value.isFinite ||
                        value <= 0 ||
                        value > 400) {
                      return 'Ingresá un valor entre 0 y 400 cm, mayor que 0.';
                    }
                    return null;
                  },
                ),
              ),
            const Text(
              'Para comparar mejor, usá siempre la misma referencia y postura. En espalda, registrá el contorno del torso a la altura que elijas y mantené ese criterio.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 24),
            LimeButton(
              label: 'Guardar medidas',
              icon: Icons.check_rounded,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    ),
  );
}
