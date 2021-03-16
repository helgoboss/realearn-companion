import 'package:flutter/widgets.dart';

import '../infrastructure/platform/stub/configure_app.dart';

abstract class AppConfig {
  TlsPolicy get tlsPolicy;

  String? get initialRoute;

  SecurityPlatform get securityPlatform;

  Future<bool> deviceHasCamera();

  QrCodeScan scanQrCode(BuildContext context);

  /**
   * Returns null if not supported.
   */
  Uri? createCertObjectUrl(String content);

  Widget svgImage(
    String assetPath, {
    required Color color,
    required BoxFit fit,
    required double width,
    required double height,
  });
}

enum TlsPolicy { never, remoteOnly, evenForLocalhost }

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
