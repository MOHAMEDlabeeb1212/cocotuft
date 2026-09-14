// Conditional export for platform-specific file operations.

export 'web_file_helper_stub.dart'
    if (dart.library.html) 'web_file_helper_web.dart';
