import 'package:flutter_test/flutter_test.dart';
import 'package:pesa_box_app/i18n/i18n.dart';
import 'package:pesa_box_app/i18n/sw.dart';

final _placeholder = RegExp(r'\{\d+\}');

List<String> _placeholders(String s) =>
    (_placeholder.allMatches(s).map((m) => m.group(0)!).toList()..sort());

void main() {
  tearDown(() => I18n.locale.value = 'sw');

  test('Swahili is the default language', () {
    expect(I18n.locale.value, 'sw');
    expect(tr('Save & Continue'), 'Hifadhi na Endelea');
  });

  test('English shows the original text', () {
    I18n.locale.value = 'en';
    expect(tr('Save & Continue'), 'Save & Continue');
  });

  test('a missing translation falls back to the English text', () {
    expect(tr('A sentence nobody has translated'), 'A sentence nobody has translated');
  });

  test('placeholders are filled in order', () {
    expect(tr('Member {0}', [3]), 'Mwanachama 3');
    expect(tr('Hello, {0}', ['Asha']), 'Habari, Asha');
    I18n.locale.value = 'en';
    expect(tr('Hello, {0}', ['Asha']), 'Hello, Asha');
  });

  test('strings that are Swahili in the code read correctly in English', () {
    I18n.locale.value = 'en';
    expect(tr('Salama'), 'Secure');
    I18n.locale.value = 'sw';
    expect(tr('Salama'), 'Salama');
  });

  test('every Swahili entry keeps the same placeholders as its English key', () {
    final broken = <String>[];
    kSw.forEach((en, sw) {
      if (_placeholders(en).join() != _placeholders(sw).join()) broken.add(en);
    });
    expect(broken, isEmpty, reason: 'placeholder mismatch in: $broken');
  });

  test('no Swahili entry is empty', () {
    expect(kSw.entries.where((e) => e.value.trim().isEmpty), isEmpty);
  });
}
