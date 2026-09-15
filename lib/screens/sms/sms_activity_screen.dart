import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

class SmsActivityScreen extends StatelessWidget {
  const SmsActivityScreen({super.key});

  static const List<Color> _avatarColors = [
    AppColors.green600,
    AppColors.blue,
    AppColors.gold500,
    AppColors.teal800,
  ];

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
              const AuthHeader(
                title: 'SMS Activity',
                subtitle: 'Sender ID: PESABOX',
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      label: 'Delivered',
                      value: '312',
                      color: AppColors.green600,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _StatBox(
                      label: 'Pending/Failed',
                      value: '3',
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Recent messages',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 12),
              ...smsActivity.indexed.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SmsCard(
                    sms: entry.$2,
                    color: _avatarColors[entry.$1 % _avatarColors.length],
                    delivered: entry.$1 != 2,
                  ),
                ),
              ),
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
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.ink400,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
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
  final dynamic sms;
  final Color color;
  final bool delivered;

  const _SmsCard({
    required this.sms,
    required this.color,
    required this.delivered,
  });

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
                  'P',
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
                      'PESABOX · $_typeLabel',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _timeLabel,
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
                  color: delivered ? AppColors.green100 : AppColors.danger100,
                  borderRadius: AppRadius.sm,
                ),
                child: Text(
                  delivered ? 'Delivered' : 'Pending',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: delivered ? AppColors.teal800 : AppColors.danger,
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
              sms.message,
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
    switch (sms.type) {
      case 'payment_reminder':
        return 'Payment Reminder';
      case 'fine_notice':
        return 'Fine Notice';
      case 'announcement':
        return 'Announcement';
      default:
        return 'Meeting Reminder';
    }
  }

  String get _timeLabel {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final d = sms.sentAt as DateTime;
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}