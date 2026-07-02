/// A block of time the barber marks as unavailable — a lunch or a short break.
/// Either recurs every day ([daily]) or applies to one specific [date].
class BarberBreak {
  const BarberBreak({
    required this.id,
    required this.label,
    required this.startMinutes,
    required this.durationMinutes,
    required this.daily,
    this.date,
  });

  final String id;

  /// What the barber calls it — "Lunch", "Break", or a custom label.
  final String label;

  /// Start, in minutes from midnight (e.g. 13:00 → 780).
  final int startMinutes;
  final int durationMinutes;

  /// True = repeats every day; false = only on [date].
  final bool daily;
  final DateTime? date;

  int get endMinutes => startMinutes + durationMinutes;

  int get startHour => startMinutes ~/ 60;
  int get startMin => startMinutes % 60;

  /// Does this break apply on the given calendar day?
  bool appliesOn(DateTime day) {
    if (daily) return true;
    final d = date;
    return d != null &&
        d.year == day.year &&
        d.month == day.month &&
        d.day == day.day;
  }

  /// The concrete start [DateTime] on a given day.
  DateTime startOn(DateTime day) =>
      DateTime(day.year, day.month, day.day, startHour, startMin);
}
