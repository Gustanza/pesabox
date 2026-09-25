import 'package:flutter/material.dart';

import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/auth/complete_profile_screen.dart';
import '../screens/dashboard/awaiting_assignment_screen.dart';
import '../screens/dashboard/group_assigned_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/dashboard/financial_features_screen.dart';
import '../screens/dashboard/rules_config_screen.dart';
import '../screens/dashboard/review_rules_screen.dart';
import '../screens/dashboard/group_ready_screen.dart';
import '../screens/group/rules_edit_screen.dart';
import '../screens/members/members_list_screen.dart';
import '../screens/members/add_member_screen.dart';
import '../screens/members/member_details_screen.dart';
import '../screens/members/edit_member_screen.dart';
import '../screens/members/member_financial_position_screen.dart';
import '../screens/members/member_statement_screen.dart';
import '../screens/meetings/meetings_list_screen.dart';
import '../screens/meetings/close_cycle_screen.dart';
import '../screens/meetings/create_meeting_screen.dart';
import '../screens/meetings/meeting_details_screen.dart';
import '../screens/meetings/start_meeting_screen.dart';
import '../screens/meetings/attendance_screen.dart';
import '../screens/meetings/meeting_activity_screen.dart';
import '../screens/meetings/record_contribution_screen.dart';
import '../screens/meetings/record_shares_screen.dart';
import '../screens/meetings/record_social_fund_screen.dart';
import '../screens/meetings/meeting_review_screen.dart';
import '../screens/loans/loans_list_screen.dart';
import '../screens/loans/loan_details_screen.dart';
import '../screens/loans/record_loan_screen.dart';
import '../screens/loans/record_loan_repayment_screen.dart';
import '../screens/fines/fines_list_screen.dart';
import '../screens/fines/record_fine_screen.dart';
import '../screens/expenses/group_expense_screen.dart';
import '../screens/transactions/transactions_list_screen.dart';
import '../screens/transactions/transaction_details_screen.dart';
import '../screens/transactions/correction_reversal_screen.dart';
import '../screens/funds/funds_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/reports/group_statement_screen.dart';
import '../screens/reports/export_report_screen.dart';
import '../screens/sms/sms_activity_screen.dart';
import '../screens/group/group_info_screen.dart';
import '../screens/group/edit_group_screen.dart';
import '../screens/group/rules_constitution_screen.dart';
import '../screens/group/announcements_screen.dart';
import '../screens/group/officers_screen.dart';
import '../screens/loans/gov_loans_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/settings_screen.dart';

class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String completeProfile = '/complete-profile';
  static const String awaitingAssignment = '/awaiting-assignment';
  static const String groupAssigned = '/group-assigned';

  static const String dashboard = '/dashboard';
  static const String financialFeatures = '/financial-features';

  static const String rulesConfig = '/rules-config';
  static const String reviewRules = '/review-rules';
  static const String groupReady = '/group-ready';

  static const String membersList = '/members';
  static const String addMember = '/members/add';
  static const String memberDetails = '/members/:id';
  static const String editMember = '/members/:id/edit';
  static const String memberFinancialPosition = '/members/:id/financial-position';
  static const String memberStatement = '/members/:id/statement';

  static const String meetingsList = '/meetings';
  static const String closeCycle = '/meetings/close-cycle';
  static const String createMeeting = '/meetings/create';
  static const String meetingDetails = '/meetings/:id';
  static const String startMeeting = '/meetings/:id/start';
  static const String attendance = '/meetings/:id/attendance';
  static const String meetingActivity = '/meetings/:id/activity';
  static const String recordContribution = '/meetings/:id/record-contribution';
  static const String recordShares = '/meetings/:id/record-shares';
  static const String recordSocialFund = '/meetings/:id/record-social-fund';
  static const String meetingReview = '/meetings/:id/review';

  static const String loansList = '/loans';
  static const String loanDetails = '/loans/:id';
  static const String recordLoan = '/loans/record';
  static const String recordLoanRepayment = '/loans/:id/repayment';

  static const String finesList = '/fines';
  static const String recordFine = '/fines/record';
  static const String groupExpense = '/fines/expense';

  static const String transactionsList = '/transactions';
  static const String transactionDetails = '/transactions/:id';
  static const String correctionReversal = '/transactions/:id/correction';

  static const String funds = '/funds';

  static const String reports = '/reports';
  static const String groupStatement = '/reports/group-statement';
  static const String exportReport = '/reports/export';

  static const String smsActivity = '/sms';
  static const String groupInfo = '/group/info';
  static const String editGroup = '/group/edit';
  static const String rulesConstitution = '/group/rules';
  static const String rulesEdit = '/group/rules/edit';
  static const String announcements = '/announcements';
  static const String officers = '/group/officers';
  static const String govLoans = '/group/gov-loans';

  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '');

    final pathSegments = uri.pathSegments;

    if (pathSegments.isEmpty) {
      return _buildRoute(settings, const SplashScreen());
    }

    switch (uri.path) {
      case login:
        return _buildRoute(settings, const LoginScreen());
      case otp:
        return _buildRoute(settings, const OtpScreen());
      case completeProfile:
        return _buildRoute(settings, const CompleteProfileScreen());
      case awaitingAssignment:
        return _buildRoute(settings, const AwaitingAssignmentScreen());
      case groupAssigned:
        return _buildRoute(settings, const GroupAssignedScreen());

      case dashboard:
        return _buildRoute(settings, const DashboardScreen());
      case financialFeatures:
        return _buildRoute(settings, const FinancialFeaturesScreen());

      case rulesConfig:
        return _buildRoute(settings, const RulesConfigScreen());
      case reviewRules:
        return _buildRoute(settings, const ReviewRulesScreen());
      case groupReady:
        return _buildRoute(settings, const GroupReadyScreen());

      case membersList:
        return _buildRoute(settings, const MembersListScreen());
      case addMember:
        return _buildRoute(settings, const AddMemberScreen());

      case meetingsList:
        return _buildRoute(settings, const MeetingsListScreen());
      case closeCycle:
        return _buildRoute(settings, const CloseCycleScreen());
      case createMeeting:
        return _buildRoute(settings, const CreateMeetingScreen());

      case loansList:
        return _buildRoute(settings, const LoansListScreen());
      case recordLoan:
        return _buildRoute(settings, const RecordLoanScreen());

      case finesList:
        return _buildRoute(settings, const FinesListScreen());
      case recordFine:
        return _buildRoute(settings, const RecordFineScreen());
      case groupExpense:
        return _buildRoute(settings, const GroupExpenseScreen());

      case transactionsList:
        return _buildRoute(settings, const TransactionsListScreen());

      case funds:
        return _buildRoute(settings, const FundsScreen());

      case reports:
        return _buildRoute(settings, const ReportsScreen());
      case groupStatement:
        return _buildRoute(settings, const GroupStatementScreen());
      case exportReport:
        return _buildRoute(settings, const ExportReportScreen());

      case smsActivity:
        return _buildRoute(settings, const SmsActivityScreen());
      case groupInfo:
        return _buildRoute(settings, const GroupInfoScreen());
      case editGroup:
        return _buildRoute(settings, const EditGroupScreen());
      case rulesConstitution:
        return _buildRoute(settings, const RulesConstitutionScreen());
      case rulesEdit:
        return _buildRoute(settings, const RulesEditScreen());
      case announcements:
        return _buildRoute(settings, const AnnouncementsScreen());
      case officers:
        return _buildRoute(settings, const OfficersScreen());
      case govLoans:
        return _buildRoute(settings, const GovLoansScreen());

      case profile:
        return _buildRoute(settings, const ProfileScreen());
      case editProfile:
        return _buildRoute(settings, const EditProfileScreen());
      case AppRouter.settings:
        return _buildRoute(settings, const SettingsScreen());

      default:
        if (pathSegments.length == 2) {
          final section = pathSegments[0];
          final id = pathSegments[1];

          if (section == 'members') {
            return _buildRoute(settings, MemberDetailsScreen(memberId: id));
          }
          if (section == 'meetings') {
            return _buildRoute(settings, MeetingDetailsScreen(meetingId: id));
          }
          if (section == 'loans') {
            return _buildRoute(settings, LoanDetailsScreen(loanId: id));
          }
          if (section == 'transactions') {
            return _buildRoute(
              settings,
              TransactionDetailsScreen(transactionId: id),
            );
          }
        }

        if (pathSegments.length == 3) {
          final section = pathSegments[0];
          final id = pathSegments[1];
          final action = pathSegments[2];

          if (section == 'members') {
            if (action == 'edit') {
              return _buildRoute(settings, EditMemberScreen(memberId: id));
            }
            if (action == 'financial-position') {
              return _buildRoute(settings, MemberFinancialPositionScreen(memberId: id));
            }
            if (action == 'statement') {
              return _buildRoute(settings, MemberStatementScreen(memberId: id));
            }
          }
          if (section == 'meetings') {
            if (action == 'start') {
              return _buildRoute(settings, StartMeetingScreen(meetingId: id));
            }
            if (action == 'attendance') {
              return _buildRoute(settings, AttendanceScreen(meetingId: id));
            }
            if (action == 'activity') {
              return _buildRoute(settings, MeetingActivityScreen(meetingId: id));
            }
            if (action == 'record-contribution') {
              return _buildRoute(
                settings,
                RecordContributionScreen(meetingId: id),
              );
            }
            if (action == 'record-shares') {
              return _buildRoute(settings, RecordSharesScreen(meetingId: id));
            }
            if (action == 'record-social-fund') {
              return _buildRoute(
                settings,
                RecordSocialFundScreen(meetingId: id),
              );
            }
            if (action == 'review') {
              return _buildRoute(settings, MeetingReviewScreen(meetingId: id));
            }
          }
          if (section == 'loans') {
            if (action == 'repayment') {
              return _buildRoute(
                settings,
                RecordLoanRepaymentScreen(loanId: id),
              );
            }
          }
          if (section == 'transactions') {
            if (action == 'correction') {
              return _buildRoute(
                settings,
                CorrectionReversalScreen(transactionId: id),
              );
            }
          }
        }

        return _buildRoute(settings, const _PlaceholderScreen(title: 'Not Found'));
    }
  }

  static MaterialPageRoute _buildRoute(
    RouteSettings settings,
    Widget child,
  ) {
    return MaterialPageRoute(
      builder: (_) => child,
      settings: settings,
    );
  }

  static String memberDetailsPath(String id) => '/members/$id';
  static String editMemberPath(String id) => '/members/$id/edit';
  static String memberFinancialPositionPath(String id) =>
      '/members/$id/financial-position';
  static String memberStatementPath(String id) => '/members/$id/statement';

  static String meetingDetailsPath(String id) => '/meetings/$id';
  static String startMeetingPath(String id) => '/meetings/$id/start';
  static String attendancePath(String id) => '/meetings/$id/attendance';
  static String meetingActivityPath(String id) => '/meetings/$id/activity';
  static String recordContributionPath(String id) =>
      '/meetings/$id/record-contribution';
  static String recordSharesPath(String id) => '/meetings/$id/record-shares';
  static String recordSocialFundPath(String id) =>
      '/meetings/$id/record-social-fund';
  static String meetingReviewPath(String id) => '/meetings/$id/review';

  static String loanDetailsPath(String id) => '/loans/$id';
  static String loanRepaymentPath(String id) => '/loans/$id/repayment';

  static String transactionDetailsPath(String id) => '/transactions/$id';
  static String correctionReversalPath(String id) =>
      '/transactions/$id/correction';
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
