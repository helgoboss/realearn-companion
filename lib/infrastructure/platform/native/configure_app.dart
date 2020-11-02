import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:camera/camera.dart';
import 'package:barcode_scan/barcode_scan.dart';

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
  NativeQrCodeScan scanQrCode(BuildContext context) {
    return NativeQrCodeScan();
  }

  @override
  Future<bool> deviceHasCamera() async {
    var cameras = await availableCameras();
    return !cameras.isEmpty;
  }

  @override
  Uri createCertObjectUrl(String content) {
    throw UnsupportedError("this shouldn't be called in a native app");
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

class NativeQrCodeScan extends QrCodeScan {
  @override
  final Future<String> result = scanQrCode();

  @override
  // https://stackoverflow.com/questions/53455358/how-to-present-an-empty-view-in-flutter
  final Widget widget = SizedBox.shrink();
}

Future<String> scanQrCode() async {
  var result = await BarcodeScanner.scan();
  return result.rawContent;
}