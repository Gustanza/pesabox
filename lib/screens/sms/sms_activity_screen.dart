import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/app_data.dart';
import '../../services/route_observer.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';
import '../../i18n/i18n.dart';
import '../../brand.dart';

class SmsActivityScreen extends StatefulWidget {
  const SmsActivityScreen({super.key});

  @override
  State<SmsActivityScreen> createState() => _SmsActivityScreenState();
}

class _SmsActivityScreenState extends State<SmsActivityScreen>
    with AutoRefreshOnPop {
  static const List<Color> _avatarColors = [
    AppColors.green600,
    AppColors.blue,
    AppColors.gold500,
    AppColors.teal800,
  ];

  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void onReturnedToScreen() => _load();

  Future<void> _load() async {
    final list = await AppState.I.fetchSmsActivity(refresh: true);
    if (mounted) {
      setState(() {
        _messages = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sent = _messages.where((m) => m['status'] == 'sent').length;
    final failed = _messages.where((m) => m['status'] == 'failed').length;

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
                title: tr('SMS Activity'),
                subtitle: tr('Messages sent to members by SMS'),
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        label: 'Delivered',
                        value: '$sent',
                        color: AppColors.green600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatBox(
                        label: 'Failed',
                        value: '$failed',
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  tr('Recent messages'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 12),
                if (_messages.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: AppRadius.md,
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Text(
                      tr('No messages sent yet.'),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.ink400,
                      ),
                    ),
                  )
                else
                  ..._messages.indexed.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SmsCard(
                        sms: entry.$2,
                        color: _avatarColors[entry.$1 % _avatarColors.length],
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(label),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.ink400,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tr(value),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmsCard extends StatelessWidget {
  final Map<String, dynamic> sms;
  final Color color;

  const _SmsCard({required this.sms, required this.color});

  bool get _delivered => sms['status'] == 'sent';

  @override
  Widget build(BuildContext context) {
    final recipient = (sms['memberName'] as String?)?.isNotEmpty == true
        ? sms['memberName'] as String
        : (sms['phone']?.toString() ?? 'Unknown');
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
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.green500, AppColors.gold500],
                  ),
                  borderRadius: AppRadius.sm,
                ),
                alignment: Alignment.center,
                child: Text(
                  kBrandName[0],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.teal900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$recipient · $_typeLabel',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppState.I.isoDateTime(sms['sentAt']),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.ink400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _delivered ? AppColors.green100 : AppColors.danger100,
                  borderRadius: AppRadius.sm,
                ),
                child: Text(
                  _delivered ? tr('Delivered') : tr('Failed'),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _delivered ? AppColors.teal800 : AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.green100,
              borderRadius: AppRadius.md,
            ),
            child: Text(
              sms['message']?.toString() ?? '',
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.4,
                color: AppColors.ink900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _typeLabel {
    switch (sms['messageType']) {
      case 'login_otp':
        return tr('Login OTP');
      case 'member_otp':
        return tr('Member OTP');
      case 'member_joined':
        return tr('Member Joined');
      case 'fine':
        return tr('Fine Notice');
      case 'fine_payment':
        return tr('Fine Payment');
      case 'contribution':
        return tr('Contribution');
      case 'share':
        return tr('Share Purchase');
      case 'social_fund':
        return tr('Social Fund');
      case 'loan_disbursement':
        return tr('Loan Disbursement');
      case 'loan_repayment':
        return tr('Loan Repayment');
      default:
        return tr('Notice');
    }
  }
}
