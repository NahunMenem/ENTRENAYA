import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/models.dart';
import '../../core/widgets.dart';
import '../training/workout_screen.dart';
import '../measurements/measurements_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.profile, required this.onSignOut});

  final AthleteProfile profile;
  final Future<void> Function() onSignOut;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(profile: widget.profile, onSelectTab: _selectTab),
      _TrainingTab(profile: widget.profile),
      const _ProgressTab(),
      const _NutritionTab(),
      _ProfileTab(profile: widget.profile, onSignOut: widget.onSignOut),
    ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 4, 14, 8),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.line.withValues(alpha: 0.55)),
          ),
          child: Row(
            children: [
              _NavItem(icon: Icons.home_outlined, label: 'Inicio', selected: _selectedIndex == 0, onTap: () => _selectTab(0)),
              _NavItem(icon: Icons.fitness_center_rounded, label: 'Entrenar', selected: _selectedIndex == 1, onTap: () => _selectTab(1)),
              _NavItem(icon: Icons.bar_chart_rounded, label: 'Progreso', selected: _selectedIndex == 2, onTap: () => _selectTab(2)),
              _NavItem(icon: Icons.restaurant_rounded, label: 'Nutrición', selected: _selectedIndex == 3, onTap: () => _selectTab(3)),
              _NavItem(icon: Icons.person_outline_rounded, label: 'Perfil', selected: _selectedIndex == 4, onTap: () => _selectTab(4)),
            ],
          ),
        ),
      ),
    );
  }

  void _selectTab(int index) => setState(() => _selectedIndex = index);
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: selected ? AppColors.lime : AppColors.muted),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: selected ? AppColors.lime : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.profile, required this.onSelectTab});
  final AthleteProfile profile;
  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    final firstName = profile.name.trim().split(' ').first;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 13, 20, 22),
      children: [
        Row(
          children: [
            _Avatar(initial: firstName.isEmpty ? 'E' : firstName[0].toUpperCase(), size: 46),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('¡Buen día, $firstName! 👋', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  const Text('Hoy es un gran día para superarte', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ),
            IconButton.filled(
              onPressed: () => _showSoon(context, 'Notificaciones'),
              style: IconButton.styleFrom(backgroundColor: AppColors.surface, foregroundColor: Colors.white),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ],
        ),
        const SizedBox(height: 19),
        _WeeklySummary(days: profile.daysPerWeek),
        const SizedBox(height: 12),
        _TodayWorkout(onTap: () => _openWorkout(context)),
        const SizedBox(height: 12),
        SurfaceCard(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              const _Avatar(initial: 'L', size: 48, color: Color(0xFF345052)),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MI ENTRENADOR', style: TextStyle(color: AppColors.lime, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    SizedBox(height: 3),
                    Text('Lucas Ferraro', style: TextStyle(fontWeight: FontWeight.w800)),
                    Text('Fuerza y musculación', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(onPressed: () => _showSoon(context, 'Entrenadores'), icon: const Icon(Icons.chevron_right_rounded)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(child: Text('Entrená acompañado', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
            const Text('Profesionales para vos', style: TextStyle(color: AppColors.muted, fontSize: 9)),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(child: _ProfessionalShortcut(icon: Icons.fitness_center_rounded, title: 'Buscar entrenador', subtitle: 'Rutinas y seguimiento', onTap: () => _showSoon(context, 'Entrenadores'))),
            const SizedBox(width: 9),
            Expanded(child: _ProfessionalShortcut(icon: Icons.spa_rounded, title: 'Buscar nutricionista', subtitle: 'Planes alimentarios', onTap: () => onSelectTab(3))),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _QuickLink(icon: Icons.bar_chart_rounded, label: 'Progreso', onTap: () => onSelectTab(2)),
            const SizedBox(width: 8),
            _QuickLink(icon: Icons.menu_book_rounded, label: 'Rutinas', onTap: () => onSelectTab(1)),
            const SizedBox(width: 8),
            _QuickLink(icon: Icons.monitor_weight_outlined, label: 'Peso', onTap: () => onSelectTab(2)),
            const SizedBox(width: 8),
            _QuickLink(icon: Icons.restaurant_rounded, label: 'Nutrición', onTap: () => onSelectTab(3)),
          ],
        ),
        const SizedBox(height: 13),
        InkWell(
          onTap: () => _showSoon(context, 'EntrenaYa Premium'),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(color: AppColors.purple, borderRadius: BorderRadius.circular(18)),
            child: const Row(
              children: [
                Icon(Icons.workspace_premium_rounded, color: AppColors.orange),
                SizedBox(width: 11),
                Expanded(child: Text('EntrenaYa Premium · Probá rutinas con IA', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                Icon(Icons.chevron_right_rounded, size: 19),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WeeklySummary extends StatelessWidget {
  const _WeeklySummary({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    final completed = math.min(3, days);
    return SurfaceCard(
      child: Row(
        children: [
          SizedBox(
            width: 74,
            height: 74,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: completed / days,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  backgroundColor: AppColors.surfaceRaised,
                  color: AppColors.lime,
                ),
                Text('$completed/$days', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Resumen semanal', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Text('$completed de $days entrenamientos', style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                const Text('145 min  ·  🔥  7 días de racha', style: TextStyle(color: AppColors.muted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayWorkout extends StatelessWidget {
  const _TodayWorkout({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF384321), Color(0xFF1B2424), Color(0xFF15191F)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -7,
            top: 15,
            child: Icon(Icons.fitness_center_rounded, size: 142, color: Colors.white.withValues(alpha: 0.07)),
          ),
          Positioned(
            right: 21,
            bottom: 25,
            child: Icon(Icons.bolt_rounded, size: 100, color: AppColors.lime.withValues(alpha: 0.10)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(19, 17, 18, 17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('ENTRENAMIENTO DE HOY', style: TextStyle(color: AppColors.lime, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.lime.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20)),
                      child: const Text('PLAN ACTIVO', style: TextStyle(color: AppColors.lime, fontSize: 8, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const Spacer(),
                const Text('Pecho y tríceps', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('6 ejercicios  ·  50 min', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 15),
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.lime,
                      foregroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Comenzar entrenamiento'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfessionalShortcut extends StatelessWidget {
  const _ProfessionalShortcut({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 74,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Icon(icon, color: AppColors.lime, size: 19),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10)),
                  const SizedBox(height: 3),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 9)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.lime, size: 16),
          ],
        ),
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 76,
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.lime, size: 20),
              const SizedBox(height: 7),
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainingTab extends StatefulWidget {
  const _TrainingTab({required this.profile});
  final AthleteProfile profile;

  @override
  State<_TrainingTab> createState() => _TrainingTabState();
}

class _TrainingTabState extends State<_TrainingTab> {
  int _selectedDay = 2;
  final _days = const [('Lun', '21'), ('Mar', '22'), ('Mié', '23'), ('Jue', '24'), ('Vie', '25'), ('Sáb', '26'), ('Dom', '27')];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      children: [
        const SectionHeading(title: 'Mis entrenamientos', subtitle: 'Plan activo: Hipertrofia 4 días'),
        const SizedBox(height: 17),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(17)),
          child: Row(
            children: [
              _RoutineTab(label: 'Mi rutina', selected: true, onTap: () {}),
              _RoutineTab(label: 'Explorar', onTap: () => _showSoon(context, 'Explorar rutinas')),
              _RoutineTab(label: 'Historial', onTap: () => _showSoon(context, 'Historial')),
            ],
          ),
        ),
        const SizedBox(height: 13),
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = _days[index];
              final selected = _selectedDay == index;
              return InkWell(
                onTap: () => setState(() => _selectedDay = index),
                borderRadius: BorderRadius.circular(17),
                child: Container(
                  width: 61,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.lime : AppColors.surface,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.$1, style: TextStyle(color: selected ? AppColors.background : AppColors.muted, fontSize: 10, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 5),
                      Text(item.$2, style: TextStyle(color: selected ? AppColors.background : Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _RoutineCard(
          title: 'Pecho y tríceps',
          subtitle: 'Fuerza · ${widget.profile.level} · 6 ejercicios',
          duration: '50 minutos',
          onStart: () => _openWorkout(context),
        ),
        const SizedBox(height: 11),
        SurfaceCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: AppColors.surfaceRaised, borderRadius: BorderRadius.circular(14)),
                child: const Center(child: Text('JUE\n24', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800))),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Espalda y bíceps', style: TextStyle(fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text('5 ejercicios · 45 min', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              const Text('Por Lucas', style: TextStyle(color: AppColors.lime, fontSize: 10, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: LimeButton(label: 'Crear mi rutina', icon: Icons.add_rounded, height: 54, onPressed: () => _showSoon(context, 'Crear rutina'))),
            const SizedBox(width: 9),
            Expanded(
              child: SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: () => _showSoon(context, 'Rutinas con IA'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.purple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
                  icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFD0A5FF), size: 18),
                  label: const Text('Crear con IA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 19),
        Row(
          children: [
            _TrainingLink(icon: Icons.calendar_month_rounded, label: 'Mis planes', value: '1 activo', onTap: () => _showSoon(context, 'Planes')),
            const SizedBox(width: 9),
            _TrainingLink(icon: Icons.bookmark_border_rounded, label: 'Mis rutinas', value: '4 guardadas', onTap: () => _showSoon(context, 'Rutinas guardadas')),
            const SizedBox(width: 9),
            _TrainingLink(icon: Icons.menu_book_rounded, label: 'Biblioteca', value: 'Ejercicios', onTap: () => _showSoon(context, 'Biblioteca')),
          ],
        ),
      ],
    );
  }
}

class _RoutineTab extends StatelessWidget {
  const _RoutineTab({required this.label, required this.onTap, this.selected = false});
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: selected ? const Color(0xFF283421) : Colors.transparent, borderRadius: BorderRadius.circular(13)),
          child: Text(label, style: TextStyle(color: selected ? AppColors.lime : AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({required this.title, required this.subtitle, required this.duration, required this.onStart});
  final String title;
  final String subtitle;
  final String duration;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF47532A), Color(0xFF202827), Color(0xFF161A20)]),
      ),
      child: Stack(
        children: [
          Positioned(right: -20, top: 18, child: Icon(Icons.fitness_center_rounded, size: 170, color: Colors.white.withValues(alpha: 0.07))),
          Padding(
            padding: const EdgeInsets.all(19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: const [
                    _Tag(text: 'PENDIENTE', color: AppColors.orange),
                    _Tag(text: 'CREADA POR VOS', color: AppColors.lime),
                  ],
                ),
                const Spacer(),
                Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                Row(children: [const Icon(Icons.timer_outlined, color: AppColors.lime, size: 16), const SizedBox(width: 5), Text(duration, style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.w800, fontSize: 12))]),
                const SizedBox(height: 12),
                SizedBox(width: 158, child: LimeButton(label: 'Ver rutina', height: 48, onPressed: onStart)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      );
}

class _TrainingLink extends StatelessWidget {
  const _TrainingLink({required this.icon, required this.label, required this.value, required this.onTap});
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            height: 88,
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(17)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.lime, size: 21),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: AppColors.muted, fontSize: 9)),
              ],
            ),
          ),
        ),
      );
}

class _ProgressTab extends StatelessWidget {
  const _ProgressTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 25),
      children: [
        const SectionHeading(title: 'Mi progreso', subtitle: 'Tu evolución, en datos que motivan.'),
        const SizedBox(height: 17),
        const Row(
          children: [
            Expanded(child: _MetricCard(value: '82,4 kg', label: 'Peso actual', change: '−1,8 kg')),
            SizedBox(width: 10),
            Expanded(child: _MetricCard(value: '14', label: 'Entrenos/mes', change: '+3')),
          ],
        ),
        const SizedBox(height: 10),
        const Row(
          children: [
            Expanded(child: _MetricCard(value: '8 días', label: 'Racha actual', change: 'récord', changeColor: AppColors.orange)),
            SizedBox(width: 10),
            Expanded(child: _MetricCard(value: '12%', label: 'Volumen', change: 'este mes')),
          ],
        ),
        const SizedBox(height: 12),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [const Expanded(child: Text('Evolución del peso corporal', style: TextStyle(fontWeight: FontWeight.w800))), const Text('−1,8 kg', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w800))]),
              const SizedBox(height: 12),
              const Row(
                children: [
                  _PeriodChip('7 días'),
                  _PeriodChip('30 días', selected: true),
                  _PeriodChip('3 meses'),
                  _PeriodChip('6 meses'),
                  _PeriodChip('1 año'),
                ],
              ),
              const SizedBox(height: 13),
              const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Inicial 84,2 kg', style: TextStyle(color: AppColors.muted, fontSize: 9)), Text('Actual 82,4 kg', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800)), Text('Objetivo 80 kg', style: TextStyle(color: AppColors.lime, fontSize: 9))]),
              const SizedBox(height: 9),
              const SizedBox(height: 135, child: _WeightChart()),
              const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('18 sep', style: TextStyle(color: AppColors.muted, fontSize: 9)), Text('27 sep', style: TextStyle(color: AppColors.muted, fontSize: 9)), Text('6 oct', style: TextStyle(color: AppColors.muted, fontSize: 9)), Text('15 oct', style: TextStyle(color: AppColors.muted, fontSize: 9))]),
            ],
          ),
        ),
        const SizedBox(height: 11),
        Row(
          children: [
            Expanded(child: _ProgressTile(icon: Icons.straighten_rounded, title: 'Medidas', detail: 'Historial y evolución', onTap: () => _openMeasurements(context))),
            const SizedBox(width: 10),
            const Expanded(child: _ProgressTile(icon: Icons.photo_library_outlined, title: 'Fotos', detail: 'Antes / Después')),
          ],
        ),
        const SizedBox(height: 14),
        LimeButton(label: 'Registrar medidas', icon: Icons.add_rounded, onPressed: () => _openMeasurements(context)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.value, required this.label, required this.change, this.changeColor = AppColors.lime});
  final String value;
  final String label;
  final String change;
  final Color changeColor;
  @override
  Widget build(BuildContext context) => SurfaceCard(
        padding: const EdgeInsets.all(15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Row(children: [Expanded(child: Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10))), Text(change, style: TextStyle(color: changeColor, fontSize: 10, fontWeight: FontWeight.w800))])]),
      );
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip(this.label, {this.selected = false});
  final String label;
  final bool selected;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(color: selected ? const Color(0xFF283421) : AppColors.surfaceRaised, borderRadius: BorderRadius.circular(9)),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: selected ? AppColors.lime : AppColors.muted, fontSize: 8, fontWeight: FontWeight.w700)),
        ),
      );
}

class _WeightChart extends StatelessWidget {
  const _WeightChart();
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _WeightChartPainter(), child: const SizedBox.expand());
}

class _WeightChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const values = [0.18, 0.34, 0.48, 0.57, 0.76, 0.91];
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      points.add(Offset(12 + (size.width - 24) * i / (values.length - 1), size.height * values[i]));
    }
    final linePaint = Paint()..color = AppColors.blue..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final control = Offset((previous.dx + current.dx) / 2, (previous.dy + current.dy) / 2);
      path.quadraticBezierTo(previous.dx, previous.dy, control.dx, control.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(path, linePaint);
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      canvas.drawCircle(point, i == points.length - 1 ? 6 : 5, Paint()..color = i == points.length - 1 ? AppColors.blue : AppColors.surface);
      canvas.drawCircle(point, i == points.length - 1 ? 6 : 5, Paint()..color = AppColors.blue..style = PaintingStyle.stroke..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProgressTile extends StatelessWidget {
  const _ProgressTile({required this.icon, required this.title, required this.detail, this.onTap});
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SurfaceCard(
        padding: const EdgeInsets.all(15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: AppColors.lime, size: 20), const SizedBox(height: 12), Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(detail, style: const TextStyle(color: AppColors.muted, fontSize: 11))]),
      ));
}

void _openMeasurements(BuildContext context) {
  Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const MeasurementsScreen()));
}

class _NutritionTab extends StatefulWidget {
  const _NutritionTab();
  @override
  State<_NutritionTab> createState() => _NutritionTabState();
}

class _NutritionTabState extends State<_NutritionTab> {
  int _waterMl = 1800;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 25),
      children: [
        const SectionHeading(title: 'Nutrición', subtitle: 'Comé bien, sentite mejor.'),
        const SizedBox(height: 17),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [const Expanded(child: Text('Miércoles, 23 de septiembre', style: TextStyle(color: AppColors.muted, fontSize: 12))), RichText(text: const TextSpan(style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800), children: [TextSpan(text: '1.720'), TextSpan(text: ' / 2.200 kcal', style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w500))]))]),
              const SizedBox(height: 9),
              const ProgressBar(value: 0.78, color: AppColors.lime, height: 10),
              const SizedBox(height: 7),
              const Text('480 kcal restantes · 78% del objetivo diario', style: TextStyle(color: AppColors.muted, fontSize: 10)),
              const SizedBox(height: 19),
              const _MacroRow(label: 'Proteína', amount: '128 / 160 g', value: 0.8, color: AppColors.lime),
              const SizedBox(height: 12),
              const _MacroRow(label: 'Carbos', amount: '186 / 240 g', value: 0.77, color: AppColors.blue),
              const SizedBox(height: 12),
              const _MacroRow(label: 'Grasas', amount: '54 / 70 g', value: 0.77, color: AppColors.orange),
            ],
          ),
        ),
        const SizedBox(height: 11),
        SurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFF1E3440), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.water_drop_rounded, color: AppColors.blue)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Agua', style: TextStyle(fontWeight: FontWeight.w800)), Text('${(_waterMl / 1000).toStringAsFixed(1)} / 2,5 L', style: const TextStyle(color: AppColors.muted, fontSize: 12))])),
              IconButton.filledTonal(onPressed: () => setState(() => _waterMl = (_waterMl + 250).clamp(0, 5000)), icon: const Icon(Icons.add_rounded), style: IconButton.styleFrom(foregroundColor: AppColors.blue, backgroundColor: const Color(0xFF1E3440))),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(children: [const Expanded(child: Text('Comidas de hoy', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17))), TextButton.icon(onPressed: () => _showSoon(context, 'Agregar comida'), icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Agregar'))]),
        const SizedBox(height: 6),
        const _MealTile(icon: Icons.wb_sunny_outlined, title: 'Desayuno', detail: 'Avena, yogur y fruta', calories: '420 kcal'),
        const _MealTile(icon: Icons.lunch_dining_outlined, title: 'Almuerzo', detail: 'Pollo, arroz y ensalada', calories: '680 kcal'),
        const _MealTile(icon: Icons.coffee_outlined, title: 'Merienda', detail: 'Yogur griego y banana', calories: '220 kcal'),
        const _MealTile(icon: Icons.dinner_dining_outlined, title: 'Cena', detail: 'Pendiente', calories: '—', pending: true),
        const SizedBox(height: 12),
        const SurfaceCard(
          child: Row(children: [Icon(Icons.tips_and_updates_outlined, color: AppColors.lime), SizedBox(width: 11), Expanded(child: Text('Priorizá alimentos frescos y un plan que puedas sostener.', style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4)))]),
        ),
      ],
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({required this.label, required this.amount, required this.value, required this.color});
  final String label;
  final String amount;
  final double value;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(children: [Row(children: [Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))), Text(amount, style: const TextStyle(color: AppColors.muted, fontSize: 10))]), const SizedBox(height: 6), ProgressBar(value: value, color: color, height: 6)]);
}

class _MealTile extends StatelessWidget {
  const _MealTile({required this.icon, required this.title, required this.detail, required this.calories, this.pending = false});
  final IconData icon;
  final String title;
  final String detail;
  final String calories;
  final bool pending;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [Container(width: 39, height: 39, decoration: BoxDecoration(color: AppColors.surfaceRaised, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: pending ? AppColors.muted : AppColors.lime, size: 19)), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)), const SizedBox(height: 3), Text(detail, style: const TextStyle(color: AppColors.muted, fontSize: 10))])), Text(calories, style: TextStyle(color: pending ? AppColors.muted : Colors.white, fontSize: 11, fontWeight: FontWeight.w700))]),
        ),
      );
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.profile, required this.onSignOut});
  final AthleteProfile profile;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final weight = profile.weightKg == null ? '— kg' : '${profile.weightKg!.toStringAsFixed(1).replaceAll('.', ',')} kg';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        const SectionHeading(title: 'Mi perfil', subtitle: 'Tu espacio, a tu manera.'),
        const SizedBox(height: 18),
        SurfaceCard(
          child: Row(
            children: [
              _Avatar(initial: profile.name.isEmpty ? 'E' : profile.name[0].toUpperCase(), size: 62, color: const Color(0xFF334328)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(profile.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text('${profile.age == null ? 'Atleta' : '${profile.age} años'} · $weight', style: const TextStyle(color: AppColors.muted, fontSize: 12)), const SizedBox(height: 7), Text('Objetivo: ${profile.goal.toLowerCase()}', style: const TextStyle(color: AppColors.lime, fontSize: 11, fontWeight: FontWeight.w700))])),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _ProfileRow(icon: Icons.workspace_premium_outlined, title: 'Plan gratuito', subtitle: 'Ver opciones Premium', accent: AppColors.orange),
        const SizedBox(height: 9),
        const _ProfileRow(icon: Icons.fitness_center_rounded, title: 'Mi entrenador', subtitle: 'Lucas Ferraro'),
        const SizedBox(height: 9),
        const _ProfileRow(icon: Icons.restaurant_rounded, title: 'Mi nutricionista', subtitle: 'Valentina Rossi'),
        const SizedBox(height: 18),
        const Text('CUENTA', style: TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
        const SizedBox(height: 8),
        const _ProfileRow(icon: Icons.notifications_none_rounded, title: 'Notificaciones', subtitle: 'Rutinas, mensajes y recordatorios'),
        const SizedBox(height: 8),
        const _ProfileRow(icon: Icons.lock_outline_rounded, title: 'Privacidad', subtitle: 'Datos, permisos y seguridad'),
        const SizedBox(height: 8),
        const _ProfileRow(icon: Icons.settings_outlined, title: 'Configuración', subtitle: 'Unidades, idioma y preferencias'),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => _confirmSignOut(context, onSignOut),
          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFF9098), side: const BorderSide(color: Color(0xFF54343A)), minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context, Future<void> Function() onSignOut) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('¿Cerrar sesión?'),
        content: const Text('Vas a volver a la pantalla de inicio.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cerrar sesión'))],
      ),
    );
    if (confirm == true) await onSignOut();
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.icon, required this.title, required this.subtitle, this.accent = AppColors.lime});
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  @override
  Widget build(BuildContext context) => SurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(children: [Icon(icon, color: accent, size: 20), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 10))])), const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20)]),
      );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial, required this.size, this.color = const Color(0xFF2D3942)});
  final String initial;
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
        child: Text(initial, style: TextStyle(color: AppColors.lime, fontSize: size * 0.38, fontWeight: FontWeight.w800)),
      );
}

void _openWorkout(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const WorkoutScreen()));
}

void _showSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$feature: estamos preparando esta función.')));
}
