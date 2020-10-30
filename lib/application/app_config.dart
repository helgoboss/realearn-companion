import 'package:flutter/widgets.dart';

import '../infrastructure/platform/stub/configure_app.dart';

abstract class AppConfig {
  bool get useTls;
  SecurityPlatform get securityPlatform;

  void alert(String msg);
  void useTlsCertificate(String certContent, Uri certRedirectUrl);
  Widget qrCodeScanner();
}

enum SecurityPlatform {
  Android,
  iOS,
  Windows,
  Linux,
  macOS,
}
