// Saving an exported report: a real file on phones/desktop, a browser download
// on the web. The right implementation is picked at compile time.
export 'file_saver_io.dart' if (dart.library.js_interop) 'file_saver_web.dart';
