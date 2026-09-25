import 'package:flutter/foundation.dart';

/// The live VPS deployment — used by release builds.
const String kLiveApiBaseUrl = 'http://161.97.99.40:8090';

/// Where the app talks to the HelaBox Go backend.
///
/// 1. `--dart-define=API_BASE_URL=...` always wins (a `localhost` URL is
///    rewritten to `10.0.2.2` on Android, since on the emulator "localhost"
///    is the phone itself, not your PC).
/// 2. Debug/profile builds use the **local** dev server (port 8090):
///    `10.0.2.2` on the Android emulator, `localhost` everywhere else —
///    so a plain `flutter run` or VS Code "Run" reads your local database,
///    the same one the web dashboard uses.
/// 3. Release builds use the live server ([kLiveApiBaseUrl]).
String apiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return _forEmulator(fromEnv);
  if (kReleaseMode) return kLiveApiBaseUrl;
  return _forEmulator('http://localhost:8090');
}

bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

String _forEmulator(String url) {
  if (!_isAndroid) return url;
  return url
      .replaceFirst('://localhost', '://10.0.2.2')
      .replaceFirst('://127.0.0.1', '://10.0.2.2');
}
