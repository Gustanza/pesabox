import 'package:flutter/foundation.dart';

/// The live VPS deployment.
const String kLiveApiBaseUrl = 'http://157.245.46.244:8090';

/// Server switch: `true` = live server ([kLiveApiBaseUrl]),
/// `false` = local dev server (localhost:8090 / 10.0.2.2 on the emulator).
/// Applies to every build mode (debug and release).
const bool kUseLiveServer = true;

/// Where the app talks to the HelaBox Go backend.
///
/// 1. `--dart-define=API_BASE_URL=...` always wins (a `localhost` URL is
///    rewritten to `10.0.2.2` on Android, since on the emulator "localhost"
///    is the phone itself, not your PC).
/// 2. Otherwise [kUseLiveServer] decides: the live server, or the local dev
///    server (port 8090 — `10.0.2.2` on the Android emulator, `localhost`
///    everywhere else).
String apiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return _forEmulator(fromEnv);
  if (kUseLiveServer) return kLiveApiBaseUrl;
  return _forEmulator('http://localhost:8090');
}

bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

String _forEmulator(String url) {
  if (!_isAndroid) return url;
  return url
      .replaceFirst('://localhost', '://10.0.2.2')
      .replaceFirst('://127.0.0.1', '://10.0.2.2');
}
