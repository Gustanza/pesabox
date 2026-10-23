import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pesa_box_app/i18n/i18n.dart';
import 'package:pesa_box_app/screens/meetings/meeting_status.dart';
import 'package:pesa_box_app/services/app_data.dart';

void main() {
  setUp(() => I18n.locale.value = 'sw');
  tearDown(() => I18n.locale.value = 'sw');

  final now = DateTime(2026, 10, 23, 9, 30);

  Map<String, dynamic> m(int n, String status, String date) =>
      {'id': 'm$n', 'meetingNumber': n, 'status': status, 'date': date, 'title': 'Meeting #$n'};

  test('a scheduled meeting dated before today is overdue', () {
    expect(meetingPhase(m(1, 'upcoming', '2026-09-28'), now: now), MeetingPhase.overdue);
    expect(meetingPhase(m(1, 'upcoming', '2026-10-22'), now: now), MeetingPhase.overdue);
  });

  test('a scheduled meeting today or later, or without a date, is upcoming', () {
    expect(meetingPhase(m(1, 'upcoming', '2026-10-23'), now: now), MeetingPhase.upcoming);
    expect(meetingPhase(m(1, 'upcoming', '2026-11-01'), now: now), MeetingPhase.upcoming);
    expect(meetingPhase(m(1, 'upcoming', ''), now: now), MeetingPhase.upcoming);
  });

  test('started and closed meetings are never overdue', () {
    expect(meetingPhase(m(1, 'in_progress', '2026-09-01'), now: now), MeetingPhase.inProgress);
    expect(meetingPhase(m(1, 'completed', '2026-09-01'), now: now), MeetingPhase.completed);
  });

  test('next meeting: in progress first, then the earliest scheduled, never a closed one', () {
    // The API lists meetings newest first.
    final list = [
      m(3, 'upcoming', '2026-11-05'),
      m(2, 'upcoming', '2026-09-28'),
      m(1, 'completed', '2026-09-17'),
    ];
    expect(pickNextMeeting(list)?['id'], 'm2');
    expect(pickNextMeeting([m(4, 'in_progress', '2026-10-23'), ...list])?['id'], 'm4');
    expect(pickNextMeeting([m(1, 'completed', '2026-09-17')]), isNull);
    expect(pickNextMeeting(const []), isNull);
  });

  test('AppState.nextMeeting skips a completed meeting (quick action → create meeting)', () {
    AppState.I.meetings = [m(1, 'completed', '2026-09-17')];
    addTearDown(() => AppState.I.meetings = []);
    expect(AppState.I.nextMeeting, isNull);
  });

  test('generated titles are translated, custom titles kept', () {
    expect(meetingTitle(m(1, 'upcoming', '')), 'Mkutano #1');
    expect(meetingTitle({'title': 'AGM', 'meetingNumber': 4}), 'AGM');
    expect(meetingTitle({'meetingNumber': 5}), 'Mkutano #5');
    I18n.locale.value = 'en';
    expect(meetingTitle(m(2, 'upcoming', '')), 'Meeting #2');
  });

  testWidgets('the pill says Overdue (Imechelewa) for a past scheduled meeting', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [
          MeetingStatusPill(meeting: m(1, 'upcoming', '2020-01-01')),
          MeetingStatusPill(meeting: m(2, 'upcoming', '2999-01-01')),
          MeetingStatusPill(meeting: m(3, 'in_progress', '2020-01-01')),
          MeetingStatusPill(meeting: m(4, 'completed', '2020-01-01')),
        ]),
      ),
    ));
    expect(find.text('Imechelewa'), findsOneWidget);
    expect(find.text('Unakuja'), findsOneWidget);
    expect(find.text('Inaendelea'), findsOneWidget);
    expect(find.text('Imefungwa'), findsOneWidget);
  });
}
