// Conditional import for web file picker
import 'web_file_picker_stub.dart'
    if (dart.library.html) 'web_file_picker_web.dart';

// Export the WebFilePicker class
export 'web_file_picker_stub.dart'
    if (dart.library.html) 'web_file_picker_web.dart';