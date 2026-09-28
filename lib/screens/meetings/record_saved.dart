import 'package:flutter/material.dart';

import '../../i18n/i18n.dart';
import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../ui/ui.dart';

/// Shows the success popup for a meeting money record ([created] is what
/// `recordTransaction` returned) and acts on the user's choice: stay and
/// record another ([onAgain]), leave the screen, or open the transaction.
Future<void> showRecordSaved(
  BuildContext context, {
  required Map<String, dynamic> created,
  required String title,
  required String memberName,
  required String meetingTitle,
  List<(String, String)> extra = const [],
  required VoidCallback onAgain,
}) async {
  final state = AppState.I;
  final id = created['id']?.toString() ?? '';
  final type = created['type']?.toString() ?? '';
  final savingsType = created['savingsType']?.toString() ?? '';
  final method = created['method']?.toString() ?? 'Cash';
  final amount = created['amount'] is num ? created['amount'] as num : 0;

  final action = await showHxSuccess(
    context,
    title: title,
    amount: state.money(amount),
    showDetails: id.isNotEmpty,
    details: [
      ('Member', memberName),
      (
        'Type',
        switch (savingsType) {
          'mandatory' => tr('Mandatory savings'),
          'voluntary' => tr('Voluntary savings'),
          _ => state.txnTypeLabel(type),
        },
      ),
      ...extra,
      ('Payment method', tr(method)),
      ('Meeting', meetingTitle),
      (
        'Time',
        state.isoDateTime(
          created['createdAt'] ?? DateTime.now().toIso8601String(),
        ),
      ),
      if (id.isNotEmpty)
        (
          'Reference',
          id.length > 8
              ? id.substring(id.length - 8).toUpperCase()
              : id.toUpperCase(),
        ),
    ],
  );
  if (!context.mounted) return;
  switch (action) {
    case HxSuccessAction.again:
      onAgain();
    case HxSuccessAction.done:
      Navigator.of(context).pop();
    case HxSuccessAction.details:
      Navigator.of(context)
          .pushReplacementNamed(AppRouter.transactionDetailsPath(id));
  }
}
