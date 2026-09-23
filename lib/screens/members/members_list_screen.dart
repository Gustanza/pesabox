import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/models.dart';
import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../services/route_observer.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

import '../../i18n/i18n.dart';

class MembersListScreen extends StatefulWidget {
  const MembersListScreen({super.key});

  static const List<Color> _avatarColors = [
    Color(0xFF1FBF82),
    Color(0xFFD9A441),
    Color(0xFF3E7BFA),
    Color(0xFFE15454),
    Color(0xFF9B59B6),
    Color(0xFF136B54),
  ];

  @override
  State<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends State<MembersListScreen>
    with AutoRefreshOnPop {
  List<Member> _members = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void onReturnedToScreen() => _load();

  Future<void> _load() async {
    final raw = await AppState.I.fetchMembers(refresh: true);
    if (!mounted) return;
    setState(() {
      _members = raw.map((m) => Member.fromApi(m)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              AuthHeader(
                title: tr('Members'),
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 20),
              _StatsCard(count: _members.length),
              const SizedBox(height: 16),
              TextField(
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.ink900,
                ),
                decoration: InputDecoration(
                  hintText: tr('Search members...'),
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.ink400,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.ink400,
                    size: 20,
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                  filled: true,
                  fillColor: AppColors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.line, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.line, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppColors.teal900, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line, width: 1),
                  ),
                  child: _members.isEmpty
                      ? Center(
                          child: Text(
                            tr('No members yet.'),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.ink400,
                            ),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            // Rows are a fixed ~64px (12+12 padding around a
                            // 40px avatar) plus a 1px divider between them —
                            // only allow scrolling once the list actually
                            // overflows the box, so a couple of members
                            // don't leave a draggable empty tail that looks
                            // like there's more to scroll to.
                            const rowHeight = 64.0;
                            const dividerHeight = 1.0;
                            final contentHeight = _members.length * rowHeight +
                                (_members.length - 1) * dividerHeight;
                            final fits = contentHeight <= constraints.maxHeight;

                            return ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              physics: fits
                                  ? const NeverScrollableScrollPhysics()
                                  : const AlwaysScrollableScrollPhysics(),
                              itemCount: _members.length,
                              separatorBuilder: (_, _) => const Divider(
                                height: dividerHeight,
                                color: AppColors.line,
                                indent: 68,
                                endIndent: 0,
                              ),
                              itemBuilder: (context, index) {
                                final member = _members[index];
                                final color = MembersListScreen
                                    ._avatarColors[index %
                                        MembersListScreen
                                            ._avatarColors.length];
                                return _MemberRow(
                                  member: member,
                                  avatarColor: color,
                                  onTap: () {
                                    Navigator.of(context).pushNamed(
                                      AppRouter.memberDetailsPath(member.id),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRouter.addMember);
        },
        backgroundColor: AppColors.green600,
        foregroundColor: AppColors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final int count;
  const _StatsCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.teal900,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('TOTAL MEMBERS'),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.white.withValues(alpha: 0.7),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final Member member;
  final Color avatarColor;
  final VoidCallback onTap;

  const _MemberRow({
    required this.member,
    required this.avatarColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                tr(member.initials),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(member.fullName),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr(member.phone),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.ink400,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.green100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                tr('Active'),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.teal800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
