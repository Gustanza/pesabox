import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/models.dart';
import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../services/route_observer.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';

import '../../i18n/i18n.dart';

class MembersListScreen extends StatefulWidget {
  const MembersListScreen({super.key});

  @override
  State<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends State<MembersListScreen>
    with AutoRefreshOnPop {
  List<Member> _members = [];
  bool _loading = true;
  String _query = '';

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
      _loading = false;
    });
  }

  List<Member> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _members;
    return _members
        .where((m) =>
            m.fullName.toLowerCase().contains(q) ||
            m.phone.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _filtered;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpace.x16),
              HxHeader(
                title: 'Members',
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: AppSpace.x20),
              HxHero(
                padding: const EdgeInsets.all(AppSpace.x20),
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
                  const SizedBox(height: AppSpace.x4),
                  Text(
                    '${_members.length}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.x16),
              TextField(
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.ink900,
                ),
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: tr('Search members...'),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.ink400,
                    size: 20,
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ),
              const SizedBox(height: AppSpace.x16),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _buildBody(visible),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FilledButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRouter.addMember);
        },
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.green600,
          foregroundColor: AppColors.white,
          elevation: 4,
          padding: const EdgeInsets.all(AppSpace.x16),
          shape: const CircleBorder(),
        ),
        child: const Icon(Icons.add_rounded, size: 26),
      ),
    );
  }

  Widget _buildBody(List<Member> visible) {
    if (_loading) {
      return const HxSkeletonList(rows: 6);
    }

    if (_members.isEmpty) {
      return HxEmpty(
        icon: Icons.people_outline_rounded,
        title: 'No members yet',
        message: 'Add your first member to start tracking contributions.',
        actionLabel: 'Add member',
        onAction: () => Navigator.of(context).pushNamed(AppRouter.addMember),
      );
    }

    if (visible.isEmpty) {
      return HxEmpty(
        icon: Icons.search_off_rounded,
        title: 'No matches',
        message: 'No members match “$_query”. Try a different name.',
      );
    }

    return HxSurface(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.x4),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: visible.length,
        separatorBuilder: (_, _) => const Divider(
          height: 1,
          color: AppColors.line,
          indent: 68,
        ),
        itemBuilder: (context, index) {
          final member = visible[index];
          return HxRow(
            onTap: () {
              Navigator.of(context).pushNamed(
                AppRouter.memberDetailsPath(member.id),
              );
            },
            leading: HxAvatar(initials: tr(member.initials)),
            title: tr(member.fullName),
            subtitle: tr(member.phone),
            titleTrailing: _statusPill(member),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: AppColors.ink400,
            ),
          );
        },
      ),
    );
  }

  Widget _statusPill(Member member) {
    final (String label, HxPillTone tone) = switch (member.status) {
      MemberStatus.active => ('Active', HxPillTone.success),
      MemberStatus.suspended => ('Suspended', HxPillTone.warning),
      MemberStatus.inactive => ('Inactive', HxPillTone.neutral),
    };
    return HxPill(text: tr(label), tone: tone);
  }
}