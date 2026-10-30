class AthleteProfile {
  const AthleteProfile({
    required this.name,
    required this.goal,
    required this.level,
    required this.trainingPlace,
    required this.daysPerWeek,
    required this.sessionMinutes,
    this.age,
    this.heightCm,
    this.weightKg,
  });

  final String name;
  final String goal;
  final String level;
  final String trainingPlace;
  final int daysPerWeek;
  final int sessionMinutes;
  final int? age;
  final double? heightCm;
  final double? weightKg;
}
