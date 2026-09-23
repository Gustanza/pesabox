import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../i18n/i18n.dart';
import '../../services/app_data.dart';
import '../../services/graphql_client.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

/// Group officers (Katibu, Mweka Hazina, committee members). The Mwenyekiti
/// (Group Admin) adds them by phone — they then sign in with an OTP and run
/// day-to-day work (members, meetings, money) but can't change core group
/// settings or appoint officers (server/access.go). Officers see the list
/// read-only.
class OfficersScreen extends StatefulWidget {
  const OfficersScreen({super.key});

  @override
  State<OfficersScreen> createState() => _OfficersScreenState();
}

const _positions = ['katibu', 'mweka_hazina', 'committee'];

String positionName(String p) {
  switch (p) {
    case 'mwenyekiti':
      return tr('Chairperson');
    case 'katibu':
      return tr('Secretary');
    case 'mweka_hazina':
      return tr('Treasurer');
    case 'committee':
      return tr('Committee member');
  }
  return p;
}

class _OfficersScreenState extends State<OfficersScreen> {
  List<Map<String, dynamic>> _officers = [];
  bool _loading = true;
  String? _error;

  bool get _canManage => AppState.I.can('group.officers');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await AppState.I.fetchOfficers();
      if (!mounted) return;
      setState(() {
        _officers = list;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _remove(Map<String, dynamic> o) async {
    final name = _name(o);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Remove officer')),
        content: Text(
          tr('{0} will no longer be able to run the group from the app.', [
            name,
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('Remove')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AppState.I.removeOfficer('${o['id']}');
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _add() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddOfficerSheet(),
    );
    if (added == true) _load();
  }

  String _name(Map<String, dynamic> o) {
    final n = '${o['firstName'] ?? ''} ${o['lastName'] ?? ''}'.trim();
    return n.isEmpty ? '${o['phone'] ?? ''}' : n;
  }

  @override
  Widget build(BuildContext context) {
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
                title: tr('Group officers'),
                subtitle: tr('Katibu, Mweka Hazina and committee members'),
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 16),
              Text(
                _canManage
                    ? tr(
                        'Officers run meetings, members and money from their own phone. Only you (the Mwenyekiti) can change group settings or officers.',
                      )
                    : tr('Only the Mwenyekiti can add or remove officers.'),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.ink600,
                ),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Text(
                  _error!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.danger,
                  ),
                )
              else if (_officers.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.md,
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Text(
                    tr('No officers yet.'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.ink400,
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.md,
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < _officers.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 64),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.teal900,
                            child: Text(
                              AppState.I.initials(_name(_officers[i])),
                              style: GoogleFonts.inter(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          title: Text(
                            _name(_officers[i]),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink900,
                            ),
                          ),
                          subtitle: Text(
                            '${positionName('${_officers[i]['position']}')} · ${_officers[i]['phone'] ?? ''}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.ink400,
                            ),
                          ),
                          trailing: _canManage
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.person_remove_outlined,
                                    color: AppColors.danger,
                                  ),
                                  tooltip: tr('Remove'),
                                  onPressed: () => _remove(_officers[i]),
                                )
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              if (_canManage)
                PrimaryButton(text: tr('Add officer'), onPressed: _add),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddOfficerSheet extends StatefulWidget {
  const _AddOfficerSheet();

  @override
  State<_AddOfficerSheet> createState() => _AddOfficerSheetState();
}

class _AddOfficerSheetState extends State<_AddOfficerSheet> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  String _phone = '';
  String _position = 'katibu';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_phone.replaceAll(RegExp(r'\D'), '').length < 9) {
      setState(() => _error = tr('Enter a valid phone number'));
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AppState.I.addOfficer(
        phone: _phone,
        position: _position,
        firstName: _first.text.trim(),
        lastName: _last.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on GraphQLException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = tr('Could not add the officer. Try again.'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('Add officer'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 16),
            PhoneInputField(
              label: tr('Phone number'),
              onChanged: (v) => _phone = v,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              label: tr('First name'),
              hint: tr('First name'),
              requiredField: false,
              controller: _first,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              label: tr('Last name'),
              hint: tr('Last name'),
              requiredField: false,
              controller: _last,
            ),
            const SizedBox(height: 14),
            Text(
              tr('Position'),
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink700,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final p in _positions)
                  ChoiceChip(
                    label: Text(positionName(p)),
                    selected: _position == p,
                    onSelected: (_) => setState(() => _position = p),
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.danger,
                ),
              ),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              text: _saving ? tr('Saving…') : tr('Add officer'),
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
