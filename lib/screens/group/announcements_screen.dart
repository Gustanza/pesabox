import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/app_data.dart';
import '../../services/route_observer.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
import '../auth/auth_widgets.dart';
import '../../i18n/i18n.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen>
    with AutoRefreshOnPop {
  List<Map<String, dynamic>> _announcements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void onReturnedToScreen() => _load();

  Future<void> _load() async {
    final list = await AppState.I.fetchAnnouncements(refresh: true);
    if (mounted) {
      setState(() {
        _announcements = list;
        _loading = false;
      });
    }
  }

  Future<void> _compose() async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    bool urgent = false;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(tr('New announcement')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: tr('Title')),
              ),
              TextField(
                controller: bodyController,
                maxLines: 3,
                decoration: InputDecoration(labelText: tr('Message')),
              ),
              Row(
                children: [
                  Checkbox(
                    value: urgent,
                    onChanged: (v) =>
                        setDialogState(() => urgent = v ?? false),
                  ),
                  Text(tr('Mark as urgent')),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr('Cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr('Post')),
            ),
          ],
        ),
      ),
    );
    if (result != true) return;
    final title = titleController.text.trim();
    if (title.isEmpty) return;
    try {
      await AppState.I.createAnnouncement(
        title: title,
        body: bodyController.text.trim(),
        priority: urgent ? 'urgent' : 'normal',
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Could not post announcement: {0}', [e]))),
      );
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
              Row(
                children: [
                  const ScreenBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr('Announcements'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink900,
                      ),
                    ),
                  ),
                  HxIconButton(icon: Icons.add, onPressed: _compose),
                ],
              ),
              const SizedBox(height: 16),
              if (_loading)
                const HxSkeletonList(rows: 4)
              else if (_announcements.isEmpty)
                HxEmpty(
                  icon: Icons.campaign_outlined,
                  title: tr('No announcements yet'),
                  message: tr('Announcements you post are shared with the whole group.'),
                )
              else
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.md,
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < _announcements.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 56),
                        _AnnouncementRow(announcement: _announcements[i]),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              OutlineButton(
                text: tr('New announcement'),
                onPressed: _compose,
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
  final Map<String, dynamic> announcement;

  const _AnnouncementRow({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final pinned = announcement['priority'] == 'urgent';
    final by = announcement['author']?.toString().isNotEmpty == true
        ? announcement['author'].toString()
        : tr('Admin');
    final date = AppState.I.isoDate(announcement['createdAt']);
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
                  announcement['title']?.toString() ?? '',
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
                if (announcement['body']?.toString().isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Text(
                    announcement['body'].toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.ink600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
