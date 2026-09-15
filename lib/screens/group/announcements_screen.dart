import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  static const List<Map<String, String>> _announcements = [
    {
      'title': 'Meeting Time Change',
      'by': 'Neema Joseph',
      'date': '10 May 2026',
      'body':
          'Starting from next week, our meetings will begin at 9:00 AM instead of 10:00 AM.',
    },
    {
      'title': 'New Savings Goal',
      'by': 'John Mfinanga',
      'date': '5 May 2026',
      'body': 'We have reached 80% of our cycle savings target. Keep it up!',
    },
    {
      'title': 'Cycle 1 Progress Update',
      'by': 'Admin User',
      'date': '2 May 2026',
      'body':
          'Cycle 1 is on track. 11 meetings completed out of 52. Thank you for your commitment.',
    },
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
              Row(
                children: [
                  const ScreenBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Announcements',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink900,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Compose new announcement'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 22,
                        color: AppColors.teal900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppRadius.md,
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    _AnnouncementRow(
                      title: _announcements[0]['title']!,
                      by: _announcements[0]['by']!,
                      date: _announcements[0]['date']!,
                      body: _announcements[0]['body']!,
                      pinned: true,
                    ),
                    const Divider(height: 1, indent: 56),
                    _AnnouncementRow(
                      title: _announcements[1]['title']!,
                      by: _announcements[1]['by']!,
                      date: _announcements[1]['date']!,
                      body: _announcements[1]['body']!,
                    ),
                    const Divider(height: 1, indent: 56),
                    _AnnouncementRow(
                      title: _announcements[2]['title']!,
                      by: _announcements[2]['by']!,
                      date: _announcements[2]['date']!,
                      body: _announcements[2]['body']!,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlineButton(
                text: 'New announcement',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Compose new announcement'),
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

class _AnnouncementRow extends StatelessWidget {
  final String title;
  final String by;
  final String date;
  final String body;
  final bool pinned;

  const _AnnouncementRow({
    required this.title,
    required this.by,
    required this.date,
    required this.body,
    this.pinned = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.green100,
            ),
            child: Icon(
              pinned ? Icons.push_pin_rounded : Icons.campaign_outlined,
              size: 18,
              color: pinned ? AppColors.gold500 : AppColors.green600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$by · $date',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.ink400,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.ink600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20, color: AppColors.ink400),
        ],
      ),
    );
  }
}