export 'import_io_or_html_stub.dart'
    if (dart.library.html) 'import_io_or_html_web.dart'
    if (dart.library.io) 'import_io_or_html_io.dart';
