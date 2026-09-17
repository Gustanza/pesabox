import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

class MeetingReviewScreen extends StatefulWidget {
  const MeetingReviewScreen({super.key, this.meetingId = '12'});

  final String meetingId;

  @override
  State<MeetingReviewScreen> createState() => _MeetingReviewScreenState();
}

class _MeetingReviewScreenState extends State<MeetingReviewScreen> {
  Map<String, dynamic>? _meeting;
  List<Map<String, dynamic>> _attendance = [];
  List<Map<String, dynamic>> _txns = [];
  bool _loading = true;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = AppState.I;
    final results = await Future.wait([
      state.meetingById(widget.meetingId),
      state.fetchMeetingAttendance(widget.meetingId),
      state.fetchTransactions(refresh: true),
    ]);
    if (!mounted) return;
    setState(() {
      _meeting = results[0] as Map<String, dynamic>?;
      _attendance = results[1] as List<Map<String, dynamic>>;
      _txns = (results[2] as List<Map<String, dynamic>>)
          .where((t) => t['meetingId'] == widget.meetingId)
          .toList();
      _loading = false;
    });
  }

  int _attendanceCount(String status) =>
      _attendance.where((a) => a['status'] == status).length;

  double _sumType(List<String> types) => _txns
      .where((t) => types.contains(t['type']))
      .fold<double>(0, (sum, t) => sum + (t['amount'] as num? ?? 0));

  String get _meetingTitle {
    final m = _meeting;
    if (m?['title']?.toString().isNotEmpty == true) return m!['title'].toString();
    return 'Meeting #${m?['meetingNumber'] ?? widget.meetingId}';
  }

  Future<void> _close() async {
    setState(() => _closing = true);
    try {
      await AppState.I.closeMeeting(widget.meetingId);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.meetingsList,
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _closing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              AuthHeader(
                title: 'Review & Close',
                subtitle: _meetingTitle,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                _SectionCard(
                  title: 'Attendance',
                  children: [
                    _KVRow(label: 'Present', value: '${_attendanceCount('present')}'),
                    _KVRow(label: 'Late', value: '${_attendanceCount('late')}'),
                    _KVRow(label: 'Absent', value: '${_attendanceCount('absent')}'),
                    _KVRow(label: 'Excused', value: '${_attendanceCount('excused')}'),
                  ],
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Money received',
                  children: [
                    _KVRow(label: 'Savings', value: state.money(_sumType(['contribution']))),
                    _KVRow(label: 'Shares', value: state.money(_sumType(['share']))),
                    _KVRow(label: 'Social Fund', value: state.money(_sumType(['social_fund']))),
                    _KVRow(label: 'Fines', value: state.money(_sumType(['fine']))),
                  ],
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Loans',
                  children: [
                    _KVRow(label: 'Disbursed', value: state.money(_sumType(['loan_disbursement']))),
                    _KVRow(label: 'Repaid', value: state.money(_sumType(['loan_repayment']))),
                  ],
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Expenses',
                  children: [
                    _KVRow(
                      label: 'Total expenses',
                      value: state.money(_sumType(['expense'])),
                      valueColor: AppColors.danger,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _closing ? null : _close,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green600,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
                    ),
                    child: _closing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                          )
                        : Text(
                            'Confirm & close meeting',
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.white),
                          ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink900),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _KVRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _KVRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink600)),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.ink900),
          ),
        ],
      ),
    );
  }
}
