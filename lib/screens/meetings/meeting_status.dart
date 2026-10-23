import 'package:flutter/material.dart';

import '../../i18n/i18n.dart';
import '../../ui/ui.dart';

/// Where a meeting stands, as shown to the user. The backend only stores
/// `upcoming` / `in_progress` / `completed` (/ `cancelled`); "overdue" is a
/// scheduled meeting whose date has already passed without it being started.
enum MeetingPhase { upcoming, overdue, inProgress, completed, cancelled }

/// The meeting's scheduled day (`date` is `YYYY-MM-DD`), or null when it has
/// none or it can't be read.
DateTime? meetingDate(Map<String, dynamic> meeting) {
  final s = meeting['date']?.toString() ?? '';
  if (s.length < 10) return null;
  final d = DateTime.tryParse(s.substring(0, 10));
  return d == null ? null : DateTime(d.year, d.month, d.day);
}

MeetingPhase meetingPhase(Map<String, dynamic> meeting, {DateTime? now}) {
  switch (meeting['status']?.toString()) {
    case 'in_progress':
      return MeetingPhase.inProgress;
    case 'completed':
      return MeetingPhase.completed;
    case 'cancelled':
      return MeetingPhase.cancelled;
  }
  final date = meetingDate(meeting);
  if (date == null) return MeetingPhase.upcoming;
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  return date.isBefore(today) ? MeetingPhase.overdue : MeetingPhase.upcoming;
}

/// True for a meeting that can still be started or continued.
bool meetingIsOpen(Map<String, dynamic> meeting) {
  final s = meeting['status']?.toString();
  return s == 'upcoming' || s == 'in_progress';
}

/// The meeting to act on next: the one already in progress, else the
/// earliest scheduled one (overdue first), else null (→ create a meeting).
Map<String, dynamic>? pickNextMeeting(List<Map<String, dynamic>> meetings) {
  for (final m in meetings) {
    if (m['status'] == 'in_progress') return m;
  }
  final scheduled = meetings.where((m) => m['status'] == 'upcoming').toList();
  if (scheduled.isEmpty) return null;
  int number(Map<String, dynamic> m) =>
      (m['meetingNumber'] as num?)?.toInt() ?? 0;
  scheduled.sort((a, b) {
    final da = meetingDate(a), db = meetingDate(b);
    if (da != null && db != null && da != db) return da.compareTo(db);
    if (da != null && db == null) return -1;
    if (da == null && db != null) return 1;
    return number(a).compareTo(number(b));
  });
  return scheduled.first;
}

/// "Meeting #3" in the current language. A blank title, or one the server
/// generated as "Meeting #N", is shown translated.
String meetingTitle(Map<String, dynamic>? meeting, [Object? fallbackNumber]) {
  final title = meeting?['title']?.toString().trim() ?? '';
  final generated = RegExp(r'^Meeting #(\d+)$').firstMatch(title);
  if (title.isNotEmpty && generated == null) return title;
  final number =
      generated?.group(1) ?? meeting?['meetingNumber'] ?? fallbackNumber ?? '';
  return tr('Meeting #{0}', [number]);
}

String meetingPhaseLabel(MeetingPhase phase) => switch (phase) {
      MeetingPhase.upcoming => 'Upcoming',
      MeetingPhase.overdue => 'Overdue',
      MeetingPhase.inProgress => 'In progress',
      MeetingPhase.completed => 'Closed',
      MeetingPhase.cancelled => 'Cancelled',
    };

HxPillTone meetingPhaseTone(MeetingPhase phase) => switch (phase) {
      MeetingPhase.upcoming => HxPillTone.warning,
      MeetingPhase.overdue => HxPillTone.danger,
      MeetingPhase.inProgress => HxPillTone.info,
      MeetingPhase.completed => HxPillTone.neutral,
      MeetingPhase.cancelled => HxPillTone.neutral,
    };

/// Status pill for a meeting: Upcoming / Overdue / In progress / Closed.
class MeetingStatusPill extends StatelessWidget {
  const MeetingStatusPill({super.key, required this.meeting});

  final Map<String, dynamic> meeting;

  @override
  Widget build(BuildContext context) {
    final phase = meetingPhase(meeting);
    return HxPill(
      text: meetingPhaseLabel(phase), // HxPill translates
      tone: meetingPhaseTone(phase),
    );
  }
}
