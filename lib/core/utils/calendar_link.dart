import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/booking.dart';
import '../i18n/strings.dart';

/// "Add to calendar" for a booking — one tap opens Google Calendar with the
/// appointment pre-filled: service + shop as the title, the barber in the
/// notes, the shop address as the location, start/end from the slot and the
/// service duration.
///
/// Uses the public calendar *template URL*, not the Calendar API — so it works
/// with zero OAuth scopes, no Google security review, and no per-user consent.
/// On Android the Google Calendar app intercepts the link natively; anywhere
/// else it opens the web composer. The user always sees and confirms the event
/// before it saves, which is exactly the trust posture a booking app wants.
Uri googleCalendarUrlFor(Booking b) {
  // Times are sent as UTC (the trailing Z) so the calendar renders them
  // correctly in whatever timezone the phone is in.
  String z(DateTime d) => DateFormat("yyyyMMdd'T'HHmmss").format(d.toUtc());
  final end = b.dateTime.add(Duration(minutes: b.service.durationMinutes));
  return Uri.parse(
    'https://calendar.google.com/calendar/render'
    '?action=TEMPLATE'
    '&text=${Uri.encodeComponent('${L.tr(b.service.name)} · ${b.barbershop.name}')}'
    '&dates=${z(b.dateTime)}Z/${z(end)}Z'
    '&details=${Uri.encodeComponent(L.bkCalDetails(b.barber.name))}'
    '&location=${Uri.encodeComponent(b.barbershop.address)}',
  );
}

/// Launches the calendar composer for [b]; if no browser/calendar app will
/// take the link, falls back to copying a human-readable appointment line so
/// the tap never ends in nothing.
Future<void> addBookingToCalendar(BuildContext context, Booking b) async {
  var ok = false;
  try {
    ok = await launchUrl(
      googleCalendarUrlFor(b),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {}
  if (ok || !context.mounted) return;
  final when = DateFormat('EEE d MMM, HH:mm').format(b.dateTime);
  await Clipboard.setData(ClipboardData(
    text: L.bkCalClipboard(
        b.service.name, b.barber.name, b.barbershop.name, when),
  ));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(L.apptCopied)));
}
