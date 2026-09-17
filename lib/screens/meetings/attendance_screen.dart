import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key, this.meetingId = '12'});

  final String meetingId;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Map<String, dynamic>> _members = [];
  Map<String, dynamic>? _meeting;
  final Map<String, String> _status = {};
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = AppState.I;
    final results = await Future.wait([
      state.fetchMembers(),
      state.meetingById(widget.meetingId),
      state.fetchMeetingAttendance(widget.meetingId),
    ]);
    final members = results[0] as List<Map<String, dynamic>>;
    final meeting = results[1] as Map<String, dynamic>?;
    final existing = results[2] as List<Map<String, dynamic>>;
    if (!mounted) return;
    setState(() {
      _members = members;
      _meeting = meeting;
      for (final row in existing) {
        final memberId = row['memberId']?.toString();
        final status = row['status']?.toString();
        if (memberId != null && status != null) _status[memberId] = status;
      }
      _loading = false;
    });
  }

  int _count(String status) =>
      _status.values.where((s) => s == status).length;

  Future<void> _continue() async {
    setState(() => _submitting = true);
    try {
      await AppState.I.submitAttendance(widget.meetingId, _status);
      if (!mounted) return;
      Navigator.of(context)
          .pushNamed(AppRouter.meetingActivityPath(widget.meetingId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meeting = _meeting;
    final title = meeting?['title']?.toString().isNotEmpty == true
        ? meeting!['title'].toString()
        : 'Meeting #${meeting?['meetingNumber'] ?? widget.meetingId}';

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const ScreenBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendance',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink900,
                          ),
                        ),
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.ink400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _MiniStat(label: 'Present', value: '${_count('present')}', color: AppColors.green600),
                  const SizedBox(width: 8),
                  _MiniStat(label: 'Late', value: '${_count('late')}', color: AppColors.gold500),
                  const SizedBox(width: 8),
                  _MiniStat(label: 'Absent', value: '${_count('absent')}', color: AppColors.danger),
                  const SizedBox(width: 8),
                  _MiniStat(label: 'Excused', value: '${_count('excused')}', color: AppColors.blue),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: AppRadius.md,
                              border: Border.all(color: AppColors.line),
                            ),
                            child: _members.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Text(
                                      'No members in this group yet.',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppColors.ink400,
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: [
                                      for (var i = 0; i < _members.length; i++) ...[
                                        _MemberRow(
                                          name: [
                                            _members[i]['firstName'],
                                            _members[i]['lastName'],
                                          ].where((s) => (s ?? '').toString().isNotEmpty).join(' '),
                                          status: _status[_members[i]['id']?.toString()],
                                          onSelect: (status) {
                                            final id = _members[i]['id']?.toString();
                                            if (id == null) return;
                                            setState(() => _status[id] = status);
                                          },
                                        ),
                                        if (i < _members.length - 1)
                                          const Divider(height: 1, indent: 60),
                                      ],
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: (_loading || _submitting) ? null : _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green600,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.md,
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Text(
                          'Continue to activities',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.ink400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final String name;
  final String? status;
  final ValueChanged<String> onSelect;

  const _MemberRow({
    required this.name,
    required this.status,
    required this.onSelect,
  });

  String get _initials {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return ('$first$last').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.green600,
            ),
            alignment: Alignment.center,
            child: Text(
              _initials,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name.isEmpty ? 'Unnamed member' : name,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink900,
              ),
            ),
          ),
          _StatusButton(letter: 'P', selected: status == 'present', onTap: () => onSelect('present')),
          const SizedBox(width: 6),
          _StatusButton(letter: 'L', selected: status == 'late', onTap: () => onSelect('late')),
          const SizedBox(width: 6),
          _StatusButton(letter: 'A', selected: status == 'absent', onTap: () => onSelect('absent')),
          const SizedBox(width: 6),
          _StatusButton(letter: 'E', selected: status == 'excused', onTap: () => onSelect('excused')),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String letter;
  final bool selected;
  final VoidCallback onTap;

  const _StatusButton({
    required this.letter,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AppColors.green600 : AppColors.line,
          border: Border.all(
            color: selected ? AppColors.green600 : AppColors.line,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          letter,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.white : AppColors.ink600,
          ),
        ),
      ),
    );
  }
}
