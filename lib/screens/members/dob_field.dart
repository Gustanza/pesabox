import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../i18n/i18n.dart';
import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';

/// `YYYY-MM-DD` — the format the member routes take `dateOfBirth` in.
String isoDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Parses a stored `dateOfBirth` (`YYYY-MM-DD`, or a full timestamp).
DateTime? parseDob(Object? value) {
  final s = value?.toString().trim() ?? '';
  if (s.length < 10) return null;
  final d = DateTime.tryParse(s.substring(0, 10));
  return d == null ? null : DateTime(d.year, d.month, d.day);
}

/// Age in whole years on [now] (today by default), or null without a valid
/// date of birth.
int? ageFromDob(Object? dob, {DateTime? now}) {
  final d = parseDob(dob);
  if (d == null) return null;
  final n = now ?? DateTime.now();
  var age = n.year - d.year;
  if (n.month < d.month || (n.month == d.month && n.day < d.day)) age--;
  return age < 0 ? null : age;
}

/// "12 Mar 1990 · 36 years" for member details; null without a date.
String? dobWithAge(Object? dob, {DateTime? now}) {
  final d = parseDob(dob);
  if (d == null) return null;
  final age = ageFromDob(dob, now: now);
  final date = AppState.I.shortDate(isoDay(d));
  return age == null ? date : '$date · ${tr('{0} years', [age])}';
}

/// Optional date-of-birth picker for the member forms. [value] and
/// [onChanged] use `YYYY-MM-DD`; clearing it gives null.
class DateOfBirthField extends StatelessWidget {
  const DateOfBirthField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = parseDob(value);
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(today.year - 30, today.month, 1),
      firstDate: DateTime(1900),
      lastDate: today,
      initialEntryMode: DatePickerEntryMode.calendar,
      initialDatePickerMode: DatePickerMode.year,
      helpText: tr('Date of birth'),
    );
    if (picked != null) onChanged(isoDay(picked));
  }

  @override
  Widget build(BuildContext context) {
    final d = parseDob(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HxFieldLabel(text: 'Date of birth', required: false),
        const SizedBox(height: 6),
        HxSurface(
          key: const ValueKey('dob-field'),
          onTap: () => _pick(context),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.x16,
            vertical: AppSpace.x12,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.cake_outlined,
                size: 18,
                color: AppColors.ink400,
              ),
              const SizedBox(width: AppSpace.x12),
              Expanded(
                child: Text(
                  d == null
                      ? tr('Select date (optional)')
                      : AppState.I.shortDate(isoDay(d)),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: d == null ? AppColors.ink400 : AppColors.ink900,
                  ),
                ),
              ),
              if (d != null)
                IconButton(
                  tooltip: tr('Clear'),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => onChanged(null),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
