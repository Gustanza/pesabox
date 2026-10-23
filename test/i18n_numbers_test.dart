import 'package:flutter_test/flutter_test.dart';
import 'package:pesa_box_app/i18n/i18n.dart';

void main() {
  setUp(() => I18n.locale.value = 'sw');

  test('server errors with numbers are translated', () {
    expect(tr('Maximum shares per meeting is 5'), 'Hisa za juu kwa mkutano ni 5');
    expect(tr('repayment exceeds the remaining balance (TZS 1,000,000)'),
        'Rejesho linazidi salio lililobaki (TZS 1,000,000)');
    expect(tr('the social fund only holds TZS 3,000'), 'Mfuko wa jamii una TZS 3,000 tu');
  });

  test('unknown text with numbers stays as it is', () {
    expect(tr('Something odd happened 42 times'), 'Something odd happened 42 times');
  });

  test('English mode is untouched', () {
    I18n.locale.value = 'en';
    expect(tr('Maximum shares per meeting is 5'), 'Maximum shares per meeting is 5');
  });
}
