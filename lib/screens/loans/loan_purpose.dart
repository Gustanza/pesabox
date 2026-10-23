import '../../i18n/i18n.dart';

/// Loan purposes the server accepts in `purpose` (key → English label;
/// Swahili lives in sw.dart).
const Map<String, String> kLoanPurposes = {
  'business': 'Business',
  'agriculture': 'Agriculture',
  'livestock': 'Livestock',
  'education': 'Education',
  'health': 'Health',
  'household': 'Household needs',
  'housing': 'Housing',
  'emergency': 'Emergency',
  'other': 'Other',
};

/// Purposes that ask for an enterprise type ("maize farming", "retail shop").
const Set<String> kEnterprisePurposes = {'business', 'agriculture', 'livestock'};

/// The server caps `enterpriseType` at this many characters.
const int kMaxEnterpriseType = 80;

bool purposeNeedsEnterprise(String? purpose) =>
    kEnterprisePurposes.contains(purpose);

/// Translated label for a stored purpose, "Not specified" when blank. An
/// unknown key is shown as stored.
String loanPurposeLabel(Object? purpose) {
  final key = purpose?.toString().trim() ?? '';
  if (key.isEmpty || key == 'unspecified') return tr('Not specified');
  final en = kLoanPurposes[key];
  return en == null ? key : tr(en);
}
