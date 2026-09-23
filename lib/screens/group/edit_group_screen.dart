import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/app_data.dart';
import '../../services/route_observer.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';
import '../../i18n/i18n.dart';

/// Read-only: these fields are set by the Super Admin on the web dashboard
/// when the group is created (see server/database.json's Groups model —
/// there's no `/api/main/group` update route for the mobile app to call),
/// so this screen only ever displays [AppState.group], never edits it.
class EditGroupScreen extends StatefulWidget {
  const EditGroupScreen({super.key});

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen>
    with AutoRefreshOnPop {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void onReturnedToScreen() => _load();

  Future<void> _load() async {
    await AppState.I.checkGroupAssignment(refresh: true);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final group = AppState.I.group;
    final frequency = group?['meetingFrequency']?.toString() ?? '';
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
                title: tr('Group Information'),
                subtitle: tr('Set by your Super Admin'),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.gold100,
                  borderRadius: AppRadius.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 20,
                      color: AppColors.gold500,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tr('Your group details are managed by your Super Admin. If anything needs updating, request a change below.'),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.teal900,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.md,
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    children: [
                      _ReadOnlyField(
                        label: 'Group name',
                        value: group?['name']?.toString() ?? '—',
                      ),
                      const SizedBox(height: 16),
                      _ReadOnlyField(
                        label: 'Region',
                        value: group?['region']?.toString() ?? '—',
                      ),
                      const SizedBox(height: 16),
                      _ReadOnlyField(
                        label: 'District',
                        value: group?['district']?.toString() ?? '—',
                      ),
                      const SizedBox(height: 16),
                      _ReadOnlyField(
                        label: 'Ward',
                        value: group?['ward']?.toString() ?? '—',
                      ),
                      const SizedBox(height: 16),
                      _ReadOnlyField(
                        label: 'Village',
                        value: group?['village']?.toString() ?? '—',
                      ),
                      const SizedBox(height: 16),
                      _ReadOnlyField(
                        label: 'Meeting frequency',
                        value: frequency.isEmpty ? '—' : frequency,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              OutlineButton(
                text: tr('Request a change'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        tr('Contact your Super Admin to request a change.'),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(label),
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.ink700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  tr(value),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.ink600,
                  ),
                ),
              ),
              const Icon(
                Icons.lock_outline,
                size: 16,
                color: AppColors.ink400,
              ),
            ],
          ),
        ),
      ],
    );
  }
}