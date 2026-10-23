import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/app_data.dart';
import '../../services/graphql_client.dart';
import '../../services/share_out.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
import '../auth/auth_widgets.dart';

import '../../i18n/i18n.dart';

/// Pays money out of the social fund — to a member in need or to a group
/// cause (POST /api/main/social-fund/payout). Needs finance.write; a mistake
/// is undone by reversing the transaction.
class SocialFundPayoutScreen extends StatefulWidget {
  const SocialFundPayoutScreen({super.key});

  @override
  State<SocialFundPayoutScreen> createState() => _SocialFundPayoutScreenState();
}

class _SocialFundPayoutScreenState extends State<SocialFundPayoutScreen> {
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  List<Map<String, dynamic>> _members = [];
  String? _memberId; // null = a group cause
  String _method = 'Cash';
  double _fund = 0;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = AppState.I;
    final results = await Future.wait([
      state.fetchMembers(refresh: true),
      state.fetchTransactions(refresh: true),
    ]);
    if (!mounted) return;
    setState(() {
      _members = results[0]
          .where((m) => '${m['status'] ?? 'Active'}'.toLowerCase() == 'active')
          .toList();
      _fund = groupCash(results[1]).socialFund;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  String _name(Map<String, dynamic> m) =>
      '${m['firstName'] ?? ''} ${m['lastName'] ?? ''}'.trim();

  Future<void> _submit() async {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '').trim()) ?? 0;
    final reason = _reasonController.text.trim();
    String? error;
    if (amount <= 0) {
      error = tr('Enter a valid amount');
    } else if (reason.isEmpty) {
      error = tr('Enter the reason for this payout');
    } else if (amount > _fund + 0.005) {
      error = tr('The social fund only holds {0}', [AppState.I.money(_fund)]);
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await AppState.I.socialFundPayout(
        amount: amount,
        reason: reason,
        memberId: _memberId,
        method: _method,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr('Social fund payout recorded')),
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.of(context).pop(true);
    } on GraphQLException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = tr('Could not save. Try again.'));
    } finally {
      if (mounted) setState(() => _submitting = false);
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
                title: tr('Social fund payout'),
                subtitle: tr('Help a member in need or pay a group cause.'),
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 20),
              if (_loading)
                const HxSkeletonList(rows: 5)
              else ...[
                HxStat(
                  label: tr('Social fund balance'),
                  value: state.money(_fund),
                  valueColor: AppColors.gold500,
                ),
                const SizedBox(height: 16),
                HxSurface(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const HxFieldLabel(text: 'Paid to', required: false),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String?>(
                        key: const ValueKey('payout-member'),
                        initialValue: _memberId,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(tr('Group cause (no member)'),
                                overflow: TextOverflow.ellipsis),
                          ),
                          for (final m in _members)
                            DropdownMenuItem<String?>(
                              value: m['id']?.toString(),
                              child: Text(_name(m),
                                  overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: (v) => setState(() => _memberId = v),
                      ),
                      const SizedBox(height: 16),
                      HxField(
                        key: const ValueKey('payout-amount'),
                        label: 'Amount (TZS)',
                        hint: tr('e.g. 20,000'),
                        keyboardType: TextInputType.number,
                        controller: _amountController,
                      ),
                      const SizedBox(height: 16),
                      HxField(
                        key: const ValueKey('payout-reason'),
                        label: 'Reason',
                        hint: tr('e.g. hospital bill, funeral support'),
                        controller: _reasonController,
                      ),
                      const SizedBox(height: 16),
                      const HxFieldLabel(text: 'Payment method', required: false),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _method,
                        items: const ['Cash', 'Mobile Money', 'Bank Transfer']
                            .map((m) =>
                                DropdownMenuItem(value: m, child: Text(tr(m))))
                            .toList(),
                        onChanged: (v) => setState(() => _method = v ?? 'Cash'),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    key: const ValueKey('payout-error'),
                    style: GoogleFonts.inter(
                        fontSize: 12.5, color: AppColors.danger),
                  ),
                ],
                const SizedBox(height: 24),
                HxButton(
                  text: tr('Record payout'),
                  loading: _submitting,
                  onPressed: _submitting ? null : _submit,
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
