import 'package:flutter/widgets.dart';

import 'app_text.dart';

/// Locale-aware formatting helpers — called from the UI (they have a context).

/// Relative time: "now / N minutes/hours/days ago" or its Arabic equivalent.
String timeAgo(BuildContext context, DateTime? t) {
  final s = AppText.of(context);
  if (t == null) return s.commonNone;
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return s.agoNow;
  if (d.inMinutes < 60) return s.agoMinutes(d.inMinutes);
  if (d.inHours < 24) return s.agoHours(d.inHours);
  return s.agoDays(d.inDays);
}

/// Short date YYYY/MM/DD (digits independent of the locale).
String shortDate(BuildContext context, DateTime? t) => t == null
    ? AppText.of(context).commonNone
    : '${t.year}/${t.month.toString().padLeft(2, '0')}/${t.day.toString().padLeft(2, '0')}';
