import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:qrscan/qrscan.dart' as scanner;

import '../../../application/app_config.dart';

AppConfig configureApp() {
  HttpOverrides.global = new _CustomHttpOverrides();
  // TODO-medium Set security platform correctly
  return _NativeAppConfig(securityPlatform: SecurityPlatform.Android);
}

class _NativeAppConfig implements AppConfig {
  final SecurityPlatform securityPlatform;

  _NativeAppConfig({this.securityPlatform});

  // TODO-medium Android in latest versions requires TLS, iOS maybe not?
  bool get useTls => true;

  @override
  void alert(String msg) {
    log(msg);
  }

  @override
  Widget qrCodeScanner() {
    return NativeQrCodeScanner();
  }

  @override
  void useTlsCertificate(String certContent, Uri certRedirectUrl) {
    // TODO-medium Necessary?
  }
}

class _CustomHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    var customContext = new SecurityContext(withTrustedRoots: false);
    // customContext.setTrustedCertificates("realearn.cer");
    var client = super.createHttpClient(customContext);
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return client;
  }
}

class NativeQrCodeScanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    scanner.scan();
    return Text("Scanning ...");
  }
}
