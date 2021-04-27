// @dart=2.9

// Currently we run without sound null safety for 2 reasons:
//
// 1. barcode_scan discontinued (commit 7bc1103 shows how we can migrate to
//    flutter_barcode_scanner instead, but I didn't have time to test it
//    enough.
// 2. Windows target still seems to require that.
//
// TODO-low Check at some point if we can run it with sound null safety.

import 'application/app.dart';
import 'infrastructure/platform/stub/configure_app.dart'
    if (dart.library.html) 'infrastructure/platform/web/configure_app.dart'
    if (dart.library.io) 'infrastructure/platform/native/configure_app.dart';

void main([List<String> arguments]) {
  App.run(config: configureApp(arguments));
}
