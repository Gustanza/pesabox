import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../services/route_observer.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
import '../dashboard/review_rules_screen.dart';

import '../../i18n/i18n.dart';

class RulesConstitutionScreen extends StatefulWidget {
  const RulesConstitutionScreen({super.key});

  @override
  State<RulesConstitutionScreen> createState() =>
      _RulesConstitutionScreenState();
}

class _RulesConstitutionScreenState extends State<RulesConstitutionScreen>
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
    await AppState.I.fetchGroup(refresh: true);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpace.x16),
            HxHeader(
              title: tr('Rules & Constitution'),
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpace.x20),
                child: _loading
                    ? const HxSkeletonList(rows: 6)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RulesSummaryCard(state: AppState.I),
                          const SizedBox(height: AppSpace.x16),
                          if (AppState.I.can('group.settings')) ...[
                            HxButton(
                              text: tr('Edit rules'),
                              icon: Icons.edit_outlined,
                              onPressed: () async {
                                await Navigator.of(context).pushNamed(AppRouter.rulesEdit);
                                if (mounted) _load();
                              },
                            ),
                            const SizedBox(height: AppSpace.x16),
                          ],
                          HxHint(
                            text: AppState.I.can('group.settings')
                                ? tr('These limits drive lending, savings and fines for every member. Changes apply to new records only.')
                                : tr('These limits drive lending, savings and fines for every member. The Mwenyekiti can change them.'),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}