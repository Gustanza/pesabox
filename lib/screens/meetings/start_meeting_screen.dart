import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
import '../auth/auth_widgets.dart';

import '../../i18n/i18n.dart';

class StartMeetingScreen extends StatefulWidget {
  const StartMeetingScreen({super.key, this.meetingId = '12'});

  final String meetingId;

  @override
  State<StartMeetingScreen> createState() => _StartMeetingScreenState();
}

class _StartMeetingScreenState extends State<StartMeetingScreen> {
  Map<String, dynamic>? _meeting;
  bool _loading = true;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final meeting = await AppState.I.meetingById(widget.meetingId);
    if (mounted) {
      setState(() {
        _meeting = meeting;
        _loading = false;
      });
    }
  }

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      await AppState.I.startMeeting(widget.meetingId);
      if (!mounted) return;
      Navigator.of(context)
          .pushNamed(AppRouter.attendancePath(widget.meetingId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(e.toString())), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    final meeting = _meeting;
    final title = meeting?['title']?.toString().isNotEmpty == true
        ? meeting!['title'].toString()
        : 'Meeting #${meeting?['meetingNumber'] ?? widget.meetingId}';
    final subtitle = meeting != null
        ? (meeting['location']?.toString().isNotEmpty == true
            ? meeting['location'].toString()
            : state.meetingSubtitle(meeting))
        : '';

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
                title: tr('Start Meeting'),
                subtitle: title,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 24),
              if (_loading)
                const HxSkeletonList(rows: 5)
              else if (meeting == null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.md,
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Text(
                    tr('Meeting not found.'),
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink600),
                  ),
                )
              else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.md,
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.green100,
                        ),
                        child: const Icon(
                          Icons.event_rounded,
                          size: 22,
                          color: AppColors.green600,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr(title),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tr(subtitle),
                              style: GoogleFonts.inter(
                                fontSize: 13,
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.md,
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Text(
                    tr('Starting this meeting will open the live meeting flow. You will record attendance, contributions, shares, and other member activities for {0}.', [title]),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.ink600,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                HxButton(
                  text: tr('Start meeting'),
                  loading: _starting,
                  onPressed: _starting ? null : _start,
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
