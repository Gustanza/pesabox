enum MemberStatus { active, inactive, suspended }

enum MeetingStatus { scheduled, inProgress, completed, cancelled }

enum LoanStatus { pending, approved, active, repaid, defaulted }

enum FineStatus { pending, paid, waived }

enum TransactionType {
  contribution,
  loanDisbursement,
  loanRepayment,
  fine,
  socialFund,
  expense,
  withdrawal,
  correction,
}

enum ContributionType { shares, socialFund, savings }

enum ReportType {
  financial,
  member,
  meeting,
  loan,
  fine,
  groupStatement,
}

class Member {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String? avatarUrl;
  final String? role;
  final MemberStatus status;
  final DateTime joinedAt;
  final int shareCount;
  final double totalContributed;
  final double totalLoans;
  final double outstandingLoan;
  final double savingsBalance;
  final double socialFundBalance;

  const Member({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email = '',
    this.avatarUrl,
    this.role,
    this.status = MemberStatus.active,
    required this.joinedAt,
    this.shareCount = 0,
    this.totalContributed = 0,
    this.totalLoans = 0,
    this.outstandingLoan = 0,
    this.savingsBalance = 0,
    this.socialFundBalance = 0,
  });

  /// Builds a member from the Go backend's `/group/members` JSON shape.
  factory Member.fromApi(Map<String, dynamic> json) {
    return Member(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String?,
      status: _memberStatusFromString(json['status'] as String?),
      joinedAt: _parseMemberDate(json['joinedAt'] as String?),
      shareCount: (json['shareCount'] as num?)?.toInt() ?? 0,
      totalContributed: _numOf(json['contributed']),
      totalLoans: _numOf(json['loansTaken']),
      outstandingLoan: _numOf(json['outstanding']),
      savingsBalance: _numOf(json['savings']),
      socialFundBalance: _numOf(json['socialFund']),
    );
  }

  static MemberStatus _memberStatusFromString(String? s) {
    switch (s) {
      case 'inactive':
        return MemberStatus.inactive;
      case 'suspended':
        return MemberStatus.suspended;
      default:
        return MemberStatus.active;
    }
  }

  static DateTime _parseMemberDate(String? s) {
    if (s == null || s.isEmpty) return DateTime(2026);
    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;
    final parts = s.trim().split(' ');
    if (parts.length >= 3) {
      const months = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
        'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
      };
      final day = int.tryParse(parts[0]) ?? 1;
      final month = months[parts[1]] ?? 1;
      final year = int.tryParse(parts[2]) ?? 2026;
      return DateTime(year, month, day);
    }
    return DateTime(2026);
  }

  static double _numOf(Object? v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

  String get fullName => '$firstName $lastName';
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();

  Member copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? avatarUrl,
    String? role,
    MemberStatus? status,
    DateTime? joinedAt,
    int? shareCount,
    double? totalContributed,
    double? totalLoans,
    double? outstandingLoan,
    double? savingsBalance,
    double? socialFundBalance,
  }) {
    return Member(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      shareCount: shareCount ?? this.shareCount,
      totalContributed: totalContributed ?? this.totalContributed,
      totalLoans: totalLoans ?? this.totalLoans,
      outstandingLoan: outstandingLoan ?? this.outstandingLoan,
      savingsBalance: savingsBalance ?? this.savingsBalance,
      socialFundBalance: socialFundBalance ?? this.socialFundBalance,
    );
  }
}

class Meeting {
  final String id;
  final int number;
  final DateTime date;
  final String location;
  final MeetingStatus status;
  final int attendeesCount;
  final double totalContributions;
  final double totalLoanDisbursed;
  final double totalLoanRepaid;
  final double totalFines;
  final bool cycleClosing;

  const Meeting({
    required this.id,
    required this.number,
    required this.date,
    required this.location,
    this.status = MeetingStatus.scheduled,
    this.attendeesCount = 0,
    this.totalContributions = 0,
    this.totalLoanDisbursed = 0,
    this.totalLoanRepaid = 0,
    this.totalFines = 0,
    this.cycleClosing = false,
  });

  Meeting copyWith({
    String? id,
    int? number,
    DateTime? date,
    String? location,
    MeetingStatus? status,
    int? attendeesCount,
    double? totalContributions,
    double? totalLoanDisbursed,
    double? totalLoanRepaid,
    double? totalFines,
    bool? cycleClosing,
  }) {
    return Meeting(
      id: id ?? this.id,
      number: number ?? this.number,
      date: date ?? this.date,
      location: location ?? this.location,
      status: status ?? this.status,
      attendeesCount: attendeesCount ?? this.attendeesCount,
      totalContributions: totalContributions ?? this.totalContributions,
      totalLoanDisbursed: totalLoanDisbursed ?? this.totalLoanDisbursed,
      totalLoanRepaid: totalLoanRepaid ?? this.totalLoanRepaid,
      totalFines: totalFines ?? this.totalFines,
      cycleClosing: cycleClosing ?? this.cycleClosing,
    );
  }
}

class Transaction {
  final String id;
  final TransactionType type;
  final double amount;
  final DateTime date;
  final String memberId;
  final String memberName;
  final String? description;
  final String? meetingId;
  final int? meetingNumber;
  final bool isReversed;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.memberId,
    required this.memberName,
    this.description,
    this.meetingId,
    this.meetingNumber,
    this.isReversed = false,
  });

  Transaction copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    DateTime? date,
    String? memberId,
    String? memberName,
    String? description,
    String? meetingId,
    int? meetingNumber,
    bool? isReversed,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      description: description ?? this.description,
      meetingId: meetingId ?? this.meetingId,
      meetingNumber: meetingNumber ?? this.meetingNumber,
      isReversed: isReversed ?? this.isReversed,
    );
  }
}

class Loan {
  final String id;
  final String memberId;
  final String memberName;
  final double amount;
  final double amountRepaid;
  final double interestRate;
  final DateTime issuedDate;
  final DateTime dueDate;
  final LoanStatus status;
  final int issuedMeetingNumber;
  final double weeklyRepayment;

  const Loan({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.amount,
    this.amountRepaid = 0,
    this.interestRate = 10,
    required this.issuedDate,
    required this.dueDate,
    this.status = LoanStatus.pending,
    required this.issuedMeetingNumber,
    this.weeklyRepayment = 0,
  });

  double get outstanding => amount - amountRepaid;
  double get repaymentProgress =>
      amount > 0 ? (amountRepaid / amount).clamp(0.0, 1.0) : 0;

  Loan copyWith({
    String? id,
    String? memberId,
    String? memberName,
    double? amount,
    double? amountRepaid,
    double? interestRate,
    DateTime? issuedDate,
    DateTime? dueDate,
    LoanStatus? status,
    int? issuedMeetingNumber,
    double? weeklyRepayment,
  }) {
    return Loan(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      amount: amount ?? this.amount,
      amountRepaid: amountRepaid ?? this.amountRepaid,
      interestRate: interestRate ?? this.interestRate,
      issuedDate: issuedDate ?? this.issuedDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      issuedMeetingNumber:
          issuedMeetingNumber ?? this.issuedMeetingNumber,
      weeklyRepayment: weeklyRepayment ?? this.weeklyRepayment,
    );
  }
}

class Fine {
  final String id;
  final String memberId;
  final String memberName;
  final double amount;
  final double amountPaid;
  final String reason;
  final int meetingNumber;
  final DateTime date;
  final FineStatus status;
  final String? issuedBy;

  const Fine({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.amount,
    this.amountPaid = 0,
    required this.reason,
    required this.meetingNumber,
    required this.date,
    this.status = FineStatus.pending,
    this.issuedBy,
  });

  double get outstanding => amount - amountPaid;

  Fine copyWith({
    String? id,
    String? memberId,
    String? memberName,
    double? amount,
    double? amountPaid,
    String? reason,
    int? meetingNumber,
    DateTime? date,
    FineStatus? status,
    String? issuedBy,
  }) {
    return Fine(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      amount: amount ?? this.amount,
      amountPaid: amountPaid ?? this.amountPaid,
      reason: reason ?? this.reason,
      meetingNumber: meetingNumber ?? this.meetingNumber,
      date: date ?? this.date,
      status: status ?? this.status,
      issuedBy: issuedBy ?? this.issuedBy,
    );
  }
}

class Group {
  final String id;
  final String name;
  final String type;
  final String location;
  final String? region;
  final String? description;
  final int memberCount;
  final double totalSavings;
  final double totalLoansOutstanding;
  final DateTime createdAt;
  final String? meetingSchedule;
  final double shareValue;
  final double maxLoanMultiplier;
  final double interestRate;

  const Group({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    this.region,
    this.description,
    this.memberCount = 0,
    this.totalSavings = 0,
    this.totalLoansOutstanding = 0,
    required this.createdAt,
    this.meetingSchedule,
    this.shareValue = 10000,
    this.maxLoanMultiplier = 3,
    this.interestRate = 10,
  });

  Group copyWith({
    String? id,
    String? name,
    String? type,
    String? location,
    String? region,
    String? description,
    int? memberCount,
    double? totalSavings,
    double? totalLoansOutstanding,
    DateTime? createdAt,
    String? meetingSchedule,
    double? shareValue,
    double? maxLoanMultiplier,
    double? interestRate,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      location: location ?? this.location,
      region: region ?? this.region,
      description: description ?? this.description,
      memberCount: memberCount ?? this.memberCount,
      totalSavings: totalSavings ?? this.totalSavings,
      totalLoansOutstanding:
          totalLoansOutstanding ?? this.totalLoansOutstanding,
      createdAt: createdAt ?? this.createdAt,
      meetingSchedule: meetingSchedule ?? this.meetingSchedule,
      shareValue: shareValue ?? this.shareValue,
      maxLoanMultiplier: maxLoanMultiplier ?? this.maxLoanMultiplier,
      interestRate: interestRate ?? this.interestRate,
    );
  }
}

class Cycle {
  final String id;
  final int number;
  final DateTime startDate;
  final DateTime endDate;
  final int meetingsHeld;
  final int totalMeetings;
  final double totalContributions;
  final double totalLoans;
  final double totalFines;
  final bool isActive;

  const Cycle({
    required this.id,
    required this.number,
    required this.startDate,
    required this.endDate,
    this.meetingsHeld = 0,
    this.totalMeetings = 52,
    this.totalContributions = 0,
    this.totalLoans = 0,
    this.totalFines = 0,
    this.isActive = true,
  });

  double get progress =>
      totalMeetings > 0 ? meetingsHeld / totalMeetings : 0;

  Cycle copyWith({
    String? id,
    int? number,
    DateTime? startDate,
    DateTime? endDate,
    int? meetingsHeld,
    int? totalMeetings,
    double? totalContributions,
    double? totalLoans,
    double? totalFines,
    bool? isActive,
  }) {
    return Cycle(
      id: id ?? this.id,
      number: number ?? this.number,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      meetingsHeld: meetingsHeld ?? this.meetingsHeld,
      totalMeetings: totalMeetings ?? this.totalMeetings,
      totalContributions: totalContributions ?? this.totalContributions,
      totalLoans: totalLoans ?? this.totalLoans,
      totalFines: totalFines ?? this.totalFines,
      isActive: isActive ?? this.isActive,
    );
  }
}

class SmsMessage {
  final String id;
  final String recipient;
  final String recipientPhone;
  final String message;
  final DateTime sentAt;
  final bool delivered;
  final String? sentBy;
  final String? type;

  const SmsMessage({
    required this.id,
    required this.recipient,
    required this.recipientPhone,
    required this.message,
    required this.sentAt,
    this.delivered = true,
    this.sentBy,
    this.type,
  });

  SmsMessage copyWith({
    String? id,
    String? recipient,
    String? recipientPhone,
    String? message,
    DateTime? sentAt,
    bool? delivered,
    String? sentBy,
    String? type,
  }) {
    return SmsMessage(
      id: id ?? this.id,
      recipient: recipient ?? this.recipient,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      message: message ?? this.message,
      sentAt: sentAt ?? this.sentAt,
      delivered: delivered ?? this.delivered,
      sentBy: sentBy ?? this.sentBy,
      type: type ?? this.type,
    );
  }
}

class Announcement {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String createdBy;
  final bool isPinned;
  final String? attachmentUrl;

  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.createdBy,
    this.isPinned = false,
    this.attachmentUrl,
  });

  Announcement copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? createdAt,
    String? createdBy,
    bool? isPinned,
    String? attachmentUrl,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isPinned: isPinned ?? this.isPinned,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
    );
  }
}

class FinancialSummary {
  final double totalSavings;
  final double totalShares;
  final double totalSocialFund;
  final double totalLoansDisbursed;
  final double totalLoansOutstanding;
  final double totalFines;
  final double totalFinesCollected;
  final double totalExpenses;

  const FinancialSummary({
    this.totalSavings = 0,
    this.totalShares = 0,
    this.totalSocialFund = 0,
    this.totalLoansDisbursed = 0,
    this.totalLoansOutstanding = 0,
    this.totalFines = 0,
    this.totalFinesCollected = 0,
    this.totalExpenses = 0,
  });

  double get totalFunds =>
      totalSavings + totalShares + totalSocialFund;
}

class MeetingActivity {
  final String meetingId;
  final List<String> attendeeIds;
  final double contributionsCollected;
  final double sharesRecorded;
  final double socialFundCollected;
  final double loansDisbursed;
  final double loansRepaid;
  final double finesIssued;
  final double finesCollected;
  final double expenses;

  const MeetingActivity({
    required this.meetingId,
    this.attendeeIds = const [],
    this.contributionsCollected = 0,
    this.sharesRecorded = 0,
    this.socialFundCollected = 0,
    this.loansDisbursed = 0,
    this.loansRepaid = 0,
    this.finesIssued = 0,
    this.finesCollected = 0,
    this.expenses = 0,
  });
}

class GroupExpense {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String approvedBy;
  final String meetingId;

  const GroupExpense({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.approvedBy,
    required this.meetingId,
  });
}

class MemberStatement {
  final String memberId;
  final String memberName;
  final List<Transaction> transactions;
  final double totalContributions;
  final double totalLoans;
  final double totalRepaid;
  final double totalFines;
  final double totalSocialFund;
  final double netPosition;

  const MemberStatement({
    required this.memberId,
    required this.memberName,
    this.transactions = const [],
    this.totalContributions = 0,
    this.totalLoans = 0,
    this.totalRepaid = 0,
    this.totalFines = 0,
    this.totalSocialFund = 0,
    this.netPosition = 0,
  });
}

class GroupStatement {
  final String groupId;
  final String groupName;
  final Cycle cycle;
  final FinancialSummary summary;
  final List<Transaction> transactions;

  const GroupStatement({
    required this.groupId,
    required this.groupName,
    required this.cycle,
    required this.summary,
    this.transactions = const [],
  });
}
