import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sw.dart';

/// App language. Swahili is the default; the choice is remembered on the device.
///
/// Screens call [tr] with the English text, e.g. `Text(tr('Save'))`. Swahili
/// comes from the dictionary in `sw.dart`; a missing entry falls back to the
/// English text, so an untranslated string never shows a blank or a raw key.
class I18n {
  I18n._();

  static const supported = ['sw', 'en'];
  static const _prefsKey = 'pb_lang';

  /// Current language code. `main.dart` rebuilds the app when this changes.
  static final ValueNotifier<String> locale = ValueNotifier<String>('sw');

  /// Reads the saved language. Call once in `main()` before `runApp`.
  static Future<void> load() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(_prefsKey);
      if (saved != null && supported.contains(saved)) locale.value = saved;
    } catch (_) {
      // Storage unavailable — keep the Swahili default for this session.
    }
  }

  static Future<void> set(String code) async {
    if (!supported.contains(code) || code == locale.value) return;
    locale.value = code;
    try {
      await (await SharedPreferences.getInstance()).setString(_prefsKey, code);
    } catch (_) {
      // Not persisted; still applies for this session.
    }
  }

  static bool get isSwahili => locale.value == 'sw';
}

/// Translates [en] into the current language.
///
/// Placeholders are written `{0}`, `{1}`, … and filled from [args] in order:
/// `tr('Hello, {0}', [name])`.
String tr(String en, [List<Object?> args = const []]) {
  var text = I18n.isSwahili ? (kSw[en] ?? _numbered(en) ?? en) : (kEn[en] ?? en);
  for (var i = 0; i < args.length; i++) {
    text = text.replaceAll('{$i}', '${args[i]}');
  }
  return text;
}

final _number = RegExp(r'\d[\d,]*(?:\.\d+)?');

/// Text with numbers in it, e.g. a server error like "Maximum shares per
/// meeting is 5": looks the text up with its numbers as `{0}`, `{1}`, …
/// ("Maximum shares per meeting is {0}") and puts them back. Null when there
/// is no such entry.
String? _numbered(String en) {
  final numbers = _number.allMatches(en).map((m) => m[0]!).toList();
  if (numbers.isEmpty) return null;
  var i = 0;
  final template = en.replaceAllMapped(_number, (_) => '{${i++}}');
  var text = kSw[template];
  if (text == null) return null;
  for (var j = 0; j < numbers.length; j++) {
    text = text!.replaceAll('{$j}', numbers[j]);
  }
  return text;
}
