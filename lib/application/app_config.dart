import 'package:flutter/widgets.dart';

import '../infrastructure/platform/stub/configure_app.dart';

abstract class AppConfig {
  bool get useTls;
  SecurityPlatform get securityPlatform;

  void alert(String msg);
  /// certContent may be null if QR code not scanned or didn't contain cert content
  void useTlsCertificate(String certContent, Uri certRedirectUrl);
  Future<bool> deviceHasCamera();
  QrCodeScan scanQrCode(BuildContext context);
}

abstract class QrCodeScan {
  Widget get widget;
  Future<String> get result;
}

enum SecurityPlatform {
  Android,
  iOS,
  Windows,
  Linux,
  macOS,
}
