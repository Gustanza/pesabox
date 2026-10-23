// Cash-box arithmetic for the social fund payout and the end-of-cycle
// share-out. Mirrors server/payouts.go (groupCash / memberPool) so the app's
// suggestions are what the server will accept; the server still has the
// final word.

double _amt(Map<String, dynamic> t, [String key = 'amount']) {
  final v = t[key];
  if (v is num) return v.toDouble();
  return double.tryParse('${v ?? ''}') ?? 0;
}

bool _counted(Map<String, dynamic> t) => t['reversed'] != true;

const _inTypes = {
  'contribution',
  'share',
  'social_fund',
  'loan_repayment',
  'fine',
};

/// The group's cash box (everything in less everything out, from
/// non-reversed transactions) and the social fund balance kept inside it.
///
/// [govLoans] are the group's government loans as `/api/main/gov-loans`
/// returns them: once the group has repaid more than it received (interest)
/// the excess also left the box — server: cash −= max(0, Σ repayments −
/// Σ loans received).
({double cash, double socialFund}) groupCash(
  List<Map<String, dynamic>> txns, {
  List<Map<String, dynamic>> govLoans = const [],
}) {
  var cash = 0.0, fund = 0.0;
  for (final t in txns) {
    if (!_counted(t)) continue;
    final a = _amt(t);
    final type = t['type']?.toString() ?? '';
    cash += _inTypes.contains(type) ? a : -a;
    if (type == 'social_fund') fund += a;
    if (type == 'social_fund_payout') fund -= a;
  }
  var govReceived = 0.0, govRepaid = 0.0;
  for (final g in govLoans) {
    govReceived += _amt(g);
    final reps = g['repayments'];
    if (reps is List) {
      for (final r in reps) {
        if (r is Map) govRepaid += _amt(Map<String, dynamic>.from(r));
      }
    } else {
      govRepaid += _amt(g, 'amountRepaid');
    }
  }
  final govNetOut = govRepaid - govReceived;
  if (govNetOut > 0) cash -= govNetOut;
  return (cash: cash, socialFund: fund);
}

/// What a member has put in and not yet had back: savings (contributions −
/// withdrawals − savings returned at share-outs) and shares (bought − shares
/// returned), never negative.
({double savings, double shares}) memberPool(
    List<Map<String, dynamic>> txns, String memberId) {
  var savings = 0.0, shares = 0.0;
  for (final t in txns) {
    if (!_counted(t) || t['memberId']?.toString() != memberId) continue;
    final a = _amt(t);
    switch (t['type']?.toString()) {
      case 'contribution':
        savings += a;
      case 'withdrawal':
        savings -= a;
      case 'share':
        shares += a;
      case 'share_out':
        savings -= _amt(t, 'savingsReturned');
        shares -= _amt(t, 'sharesReturned');
    }
  }
  return (savings: savings < 0 ? 0 : savings, shares: shares < 0 ? 0 : shares);
}

class ShareOutLine {
  ShareOutLine({
    required this.memberId,
    required this.name,
    required this.savings,
    required this.shares,
    required this.suggested,
    this.entitlement = 0,
  });

  final String memberId;
  final String name;
  final double savings;
  final double shares;
  final double suggested;

  /// The most the server pays this member: pool + their pro-rata part of
  /// the group profit (server planShareOut; it allows 1 TZS over).
  final double entitlement;

  /// True when [amount] is more than the server will accept for them.
  bool exceeds(double amount) => amount > entitlement + 1;

  double get pool => savings + shares;
}

class ShareOutPlan {
  ShareOutPlan({
    required this.cash,
    required this.socialFund,
    required this.lines,
  });

  final double cash;
  final double socialFund;
  final List<ShareOutLine> lines;

  /// Cash that may be shared out: the social fund stays in the box.
  double get available {
    final a = cash - (socialFund > 0 ? socialFund : 0);
    return a < 0 ? 0 : a;
  }

  double get poolTotal => lines.fold(0, (s, l) => s + l.pool);

  /// Earnings on top of what members put in (interest, fines, ...); 0 when
  /// the box holds less than the members' own money (e.g. loans still out).
  double get profit {
    final p = available - poolTotal;
    return p > 0 ? p : 0;
  }

  double get suggestedTotal => lines.fold(0, (s, l) => s + l.suggested);
}

/// Suggests each member's payout: their own savings + shares plus a
/// pro-rata share of the profit (by what they put in). When the box holds
/// less than the members' money, everyone gets the same fraction of theirs.
/// Amounts are whole shillings rounded down, so the total never exceeds
/// what is available.
ShareOutPlan planShareOut({
  required List<Map<String, dynamic>> transactions,
  required List<Map<String, dynamic>> members,
  List<Map<String, dynamic>> govLoans = const [],
}) {
  final box = groupCash(transactions, govLoans: govLoans);
  final raw = <({String id, String name, double sv, double sh})>[];
  for (final m in members) {
    final id = m['id']?.toString() ?? '';
    if (id.isEmpty) continue;
    final p = memberPool(transactions, id);
    final name = (m['fullName']?.toString().trim().isNotEmpty == true)
        ? m['fullName'].toString().trim()
        : '${m['firstName'] ?? ''} ${m['lastName'] ?? ''}'.trim();
    raw.add((id: id, name: name, sv: p.savings, sh: p.shares));
  }
  final draft = ShareOutPlan(
    cash: box.cash,
    socialFund: box.socialFund,
    lines: [
      for (final r in raw)
        ShareOutLine(
          memberId: r.id,
          name: r.name,
          savings: r.sv,
          shares: r.sh,
          suggested: 0,
        ),
    ],
  );
  final pool = draft.poolTotal;
  final available = draft.available;
  final profit = draft.profit; // max(0, available − Σ pools)
  final lines = <ShareOutLine>[];
  for (final l in draft.lines) {
    // Entitlement = pool + profit × pool ÷ Σ pools. Suggest it, or the same
    // fraction of everyone's pool when the box holds less than the pools.
    final entitled = pool > 0 ? l.pool + profit * l.pool / pool : l.pool;
    double s = 0;
    if (pool > 0) {
      s = (available >= pool ? entitled : l.pool / pool * available)
          .floorToDouble();
    }
    lines.add(ShareOutLine(
      memberId: l.memberId,
      name: l.name,
      savings: l.savings,
      shares: l.shares,
      suggested: s,
      entitlement: entitled,
    ));
  }
  return ShareOutPlan(cash: box.cash, socialFund: box.socialFund, lines: lines);
}
