import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../services/graphql_client.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
import '../auth/auth_widgets.dart';
import '../../i18n/i18n.dart';

/// Edits an existing member via `POST /api/main/members/:id` (the backend
/// route's own comment says it was built specifically for this screen —
/// see [AppState.updateMember]). Username/phone-as-login doesn't apply here:
/// Members don't log in themselves (see CLAUDE.md), so phone is just a
/// contact field like any other.
class EditMemberScreen extends StatefulWidget {
  const EditMemberScreen({super.key, this.memberId = ''});

  final String memberId;

  @override
  State<EditMemberScreen> createState() => _EditMemberScreenState();
}

class _EditMemberScreenState extends State<EditMemberScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _memberNumber = TextEditingController();
  String _phone = '';
  String _gender = 'Female';
  String _status = 'Active';
  bool _loading = true;
  bool _saving = false;
  bool _deactivating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await AppState.I.fetchMembers(refresh: true);
    if (!mounted) return;
    final member = AppState.I.members.firstWhere(
      (m) => m['id'] == widget.memberId,
      orElse: () => const {},
    );
    setState(() {
      _firstName.text = member['firstName']?.toString() ?? '';
      _lastName.text = member['lastName']?.toString() ?? '';
      _memberNumber.text = member['memberNumber']?.toString() ?? '';
      _phone = member['phone']?.toString() ?? '';
      final gender = member['gender']?.toString();
      _gender = (gender == 'Male' || gender == 'Female') ? gender! : 'Female';
      final status = member['status']?.toString();
      _status = ['Active', 'Inactive', 'Suspended'].contains(status)
          ? status!
          : 'Active';
      _loading = false;
    });
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _memberNumber.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AppState.I.updateMember(
        widget.memberId,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        phone: _phone,
        gender: _gender,
        memberNumber: _memberNumber.text.trim(),
        status: _status,
      );
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.memberDetailsPath(widget.memberId),
        (r) => r.settings.name == AppRouter.membersList || r.isFirst,
      );
    } on GraphQLException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = tr('Could not save changes. Try again.'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deactivate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Deactivate member')),
        content: Text(
          tr('This member will be marked inactive. You can reactivate them later from this same screen.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('Deactivate')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _deactivating = true);
    try {
      await AppState.I.updateMember(widget.memberId, status: 'Inactive');
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.membersList,
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Could not deactivate: {0}', [e]))),
      );
    } finally {
      if (mounted) setState(() => _deactivating = false);
    }
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
                title: tr('Edit Member'),
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 28),
              if (_loading)
                const HxSkeletonList(rows: 6)
              else ...[
                AuthTextField(
                  label: tr('First name'),
                  hint: tr('First name'),
                  controller: _firstName,
                ),
                const SizedBox(height: 18),
                AuthTextField(
                  label: tr('Last name'),
                  hint: tr('Last name'),
                  requiredField: false,
                  controller: _lastName,
                ),
                const SizedBox(height: 18),
                PhoneInputField(
                  initialPhone: _phone,
                  onChanged: (v) => _phone = v,
                ),
                const SizedBox(height: 18),
                _EditDropdown(
                  label: tr('Gender'),
                  value: _gender,
                  items: const ['Male', 'Female'],
                  onChanged: (v) => setState(() => _gender = v),
                ),
                const SizedBox(height: 18),
                AuthTextField(
                  label: tr('Member number'),
                  hint: tr('Member number'),
                  requiredField: false,
                  controller: _memberNumber,
                ),
                const SizedBox(height: 18),
                _EditDropdown(
                  label: 'Status',
                  value: _status,
                  items: const ['Active', 'Inactive', 'Suspended'],
                  onChanged: (v) => setState(() => _status = v),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.danger,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                PrimaryButton(
                  text: _saving ? tr('Saving…') : tr('Save changes'),
                  onPressed: _saving ? null : _save,
                ),
                const SizedBox(height: 16),
                HxButton(
                  text: _deactivating
                      ? tr('Deactivating…')
                      : tr('Deactivate member'),
                  variant: HxButtonVariant.destructive,
                  loading: _deactivating,
                  onPressed: _deactivating ? null : _deactivate,
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

class _EditDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _EditDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

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
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(tr(e))))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink900),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.line, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.green600, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
