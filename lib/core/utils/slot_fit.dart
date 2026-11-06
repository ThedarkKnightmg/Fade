/// Which start times in [slots] can't hold a cut of [minutes].
///
/// [taken] holds the half-hours already occupied (bookings, walk-ins,
/// breaks). A start is only bookable if EVERY half-hour the cut spans is
/// free and the cut ends by [closesAt]. Checking the start alone let a
/// 55-minute cut at 10:00 sit on top of a 10:30 booking, and offered a
/// 60-minute cut at 19:30 in a shop that closes at 20:00.
///
/// Shared by both booking pickers (the booking flow and the shop page) so
/// they can't drift apart again.
Set<DateTime> unfitStarts({
  required Iterable<DateTime> slots,
  required Set<DateTime> taken,
  required int minutes,
  required DateTime closesAt,
}) {
  final length = Duration(minutes: minutes <= 0 ? 30 : minutes);
  const step = Duration(minutes: 30);
  final out = <DateTime>{};
  for (final start in slots) {
    final end = start.add(length);
    if (end.isAfter(closesAt)) {
      out.add(start);
      continue;
    }
    for (var s = start; s.isBefore(end); s = s.add(step)) {
      if (taken.contains(s)) {
        out.add(start);
        break;
      }
    }
  }
  return out;
}
