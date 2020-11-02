import 'package:flutter/widgets.dart';

import '../infrastructure/platform/stub/configure_app.dart';

abstract class AppConfig {
  bool get useTls;
  SecurityPlatform get securityPlatform;

  Future<bool> deviceHasCamera();
  QrCodeScan scanQrCode(BuildContext context);
  Uri createCertObjectUrl(String content);
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

String getSecurityPlatformLabel(SecurityPlatform value) {
  return value.toString().split('.').last;
}