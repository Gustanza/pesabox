import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Writes [bytes] to the device and tries to open the file. Returns its path.
/// Downloads folder on desktop; the app's documents folder on phones.
Future<String> saveReportFile(String filename, List<int> bytes) async {
  Directory? dir;
  try {
    dir = await getDownloadsDirectory();
  } catch (_) {}
  dir ??= await getApplicationDocumentsDirectory();

  final file = File('${dir.path}${Platform.pathSeparator}$filename');
  await file.writeAsBytes(bytes, flush: true);
  try {
    await OpenFilex.open(file.path);
  } catch (_) {
    // Saved, but no app to open it — the caller still shows the path.
  }
  return file.path;
}
