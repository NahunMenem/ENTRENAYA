class AthleteProfile {
  const AthleteProfile({
    required this.name,
    required this.goal,
    required this.level,
    required this.trainingPlace,
    required this.daysPerWeek,
    required this.sessionMinutes,
    this.birthDate,
    this.heightCm,
    this.weightKg,
  });

  final String name;
  final String goal;
  final String level;
  final String trainingPlace;
  final int daysPerWeek;
  final int sessionMinutes;
  final DateTime? birthDate;

  int? get age {
    final birth = birthDate;
    if (birth == null) return null;
    final today = DateTime.now();
    final beforeBirthday = today.month < birth.month ||
        (today.month == birth.month && today.day < birth.day);
    return today.year - birth.year - (beforeBirthday ? 1 : 0);
  }
  final double? heightCm;
  final double? weightKg;
}
