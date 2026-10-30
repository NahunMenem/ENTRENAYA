import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
import '../../core/models.dart';
import '../../core/widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.initialName, required this.onComplete});

  final String? initialName;
  final ValueChanged<AthleteProfile> onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  int _step = 0;
  String _goal = 'Ganar fuerza';
  String _level = 'Principiante';
  String _trainingPlace = 'Gimnasio';
  int _days = 4;
  int _minutes = 60;

  static const _goals = [
    'Bajar de peso',
    'Ganar masa muscular',
    'Tonificar',
    'Mejorar resistencia',
    'Ganar fuerza',
    'Mantenerme en forma',
  ];
  static const _levels = [
    ('Principiante', 'Estoy empezando o vuelvo después de un tiempo', Icons.rocket_launch_rounded),
    ('Intermedio', 'Entreno con constancia hace más de 6 meses', Icons.trending_up_rounded),
    ('Avanzado', 'Tengo experiencia y objetivos específicos', Icons.bolt_rounded),
  ];
  static const _places = [
    ('Gimnasio', Icons.fitness_center_rounded),
    ('Casa', Icons.home_rounded),
    ('Ambos', Icons.swap_horiz_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _continue() {
    if (_step == 0 && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribí tu nombre para personalizar el plan.')),
      );
      return;
    }
    if (_step < 4) {
      setState(() => _step += 1);
      return;
    }
    widget.onComplete(
      AthleteProfile(
        name: _nameController.text.trim(),
        goal: _goal,
        level: _level,
        trainingPlace: _trainingPlace,
        daysPerWeek: _days,
        sessionMinutes: _minutes,
        age: int.tryParse(_ageController.text),
        heightCm: double.tryParse(_heightController.text.replaceAll(',', '.')),
        weightKg: double.tryParse(_weightController.text.replaceAll(',', '.')),
      ),
    );
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step -= 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Contanos sobre vos',
      '¿Cuál es tu objetivo?',
      '¿Cuál es tu nivel?',
      '¿Dónde entrenás?',
      'Armemos tu semana',
    ];
    final descriptions = [
      'Usamos estos datos para ajustar tu plan desde el primer día.',
      'Elegí lo que mejor represente lo que querés lograr.',
      'Así recomendamos cargas, ritmos y descansos adecuados.',
      'Podés cambiarlo más adelante y adaptar cada rutina.',
      'Elegí una frecuencia realista. La constancia gana.',
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: _back,
                        icon: const Icon(Icons.arrow_back_rounded),
                        style: IconButton.styleFrom(backgroundColor: AppColors.surface),
                      ),
                      const Spacer(),
                      Text(
                        'PASO ${_step + 1} DE 5',
                        style: const TextStyle(
                          color: AppColors.lime,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: (_step + 1) / 5,
                      minHeight: 5,
                      backgroundColor: AppColors.surfaceRaised,
                      color: AppColors.lime,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: SingleChildScrollView(
                  key: ValueKey(_step),
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titles[_step], style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 7),
                      Text(descriptions[_step], style: const TextStyle(color: AppColors.muted, height: 1.45)),
                      const SizedBox(height: 25),
                      _buildCurrentStep(),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
              child: LimeButton(
                label: _step == 4 ? 'Crear mi plan' : 'Continuar',
                icon: _step == 4 ? Icons.auto_awesome_rounded : Icons.arrow_forward_rounded,
                onPressed: _continue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    return switch (_step) {
      0 => _aboutYouStep(),
      1 => _goalStep(),
      2 => _levelStep(),
      3 => _placeStep(),
      _ => _weekStep(),
    };
  }

  Widget _aboutYouStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('NOMBRE Y APELLIDO'),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(hintText: 'Tu nombre'),
        ),
        const SizedBox(height: 19),
        Row(
          children: [
            Expanded(child: _numberField('EDAD', _ageController, '29', suffix: 'años')),
            const SizedBox(width: 12),
            Expanded(child: _numberField('ALTURA', _heightController, '170', suffix: 'cm')),
          ],
        ),
        const SizedBox(height: 19),
        _numberField('PESO ACTUAL', _weightController, '70', suffix: 'kg', decimal: true),
        const SizedBox(height: 20),
        const _HintCard(
          icon: Icons.lock_outline_rounded,
          text: 'Tus datos se usan para personalizar la experiencia. Podés editarlos después.',
        ),
      ],
    );
  }

  Widget _numberField(
    String label,
    TextEditingController controller,
    String hint, {
    required String suffix,
    bool decimal = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(decimal ? r'[0-9.,]' : r'[0-9]')),
          ],
          decoration: InputDecoration(hintText: hint, suffixText: suffix),
        ),
      ],
    );
  }

  Widget _goalStep() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _goals
          .map(
            (goal) => _ChoiceChip(
              title: goal,
              selected: _goal == goal,
              onTap: () => setState(() => _goal = goal),
            ),
          )
          .toList(),
    );
  }

  Widget _levelStep() {
    return Column(
      children: _levels
          .map(
            (level) => Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: _OptionTile(
                title: level.$1,
                subtitle: level.$2,
                icon: level.$3,
                selected: _level == level.$1,
                onTap: () => setState(() => _level = level.$1),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _placeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: _places
              .map(
                (place) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 9),
                    child: _PlaceTile(
                      title: place.$1,
                      icon: place.$2,
                      selected: _trainingPlace == place.$1,
                      onTap: () => setState(() => _trainingPlace = place.$1),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 25),
        const _FieldLabel('EQUIPAMIENTO QUE TENÉS'),
        const SizedBox(height: 5),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: const ['Mancuernas', 'Banco', 'Bandas', 'Barra', 'Máquinas', 'Peso corporal']
              .map((item) => _ChoiceChip(title: item, selected: item == 'Mancuernas', onTap: _noop))
              .toList(),
        ),
      ],
    );
  }

  Widget _weekStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('¿CUÁNTOS DÍAS POR SEMANA?'),
        const SizedBox(height: 8),
        Row(
          children: [2, 3, 4, 5, 6]
              .map(
                (day) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _CountTile(
                      value: day,
                      selected: _days == day,
                      onTap: () => setState(() => _days = day),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 25),
        const _FieldLabel('DURACIÓN POR SESIÓN'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [20, 30, 45, 60, 90]
              .map(
                (minute) => _ChoiceChip(
                  title: '$minute min',
                  selected: _minutes == minute,
                  onTap: () => setState(() => _minutes = minute),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        const _HintCard(
          icon: Icons.auto_awesome_rounded,
          text: 'Con tus respuestas armaremos una semana que puedas sostener.',
        ),
      ],
    );
  }

  static void _noop() {}
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      );
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.lime, size: 19),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4))),
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({required this.title, required this.selected, required this.onTap});
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(title),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.lime,
      side: BorderSide(color: selected ? AppColors.lime : AppColors.line),
      labelStyle: TextStyle(
        color: selected ? AppColors.background : Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.lime.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? AppColors.lime : AppColors.line),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.lime : AppColors.muted, size: 22),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? AppColors.lime : AppColors.muted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({required this.title, required this.icon, required this.selected, required this.onTap});
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 94,
        decoration: BoxDecoration(
          color: selected ? AppColors.lime : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? AppColors.lime : AppColors.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? AppColors.background : AppColors.muted),
            const SizedBox(height: 7),
            Text(title, style: TextStyle(color: selected ? AppColors.background : Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({required this.value, required this.selected, required this.onTap});
  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.lime : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.lime : AppColors.line),
        ),
        child: Text(
          '$value',
          style: TextStyle(
            color: selected ? AppColors.background : Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
      ),
    );
  }
}
