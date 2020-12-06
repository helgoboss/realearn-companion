import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:camera/camera.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../application/app_config.dart';

AppConfig configureApp() {
  HttpOverrides.global = new _CustomHttpOverrides();

  return _NativeAppConfig(securityPlatform: getNativeSecurityPlatform());
}

SecurityPlatform getNativeSecurityPlatform() {
  if (Platform.isAndroid) {
    return SecurityPlatform.Android;
  }
  if (Platform.isLinux) {
    return SecurityPlatform.Linux;
  }
  if (Platform.isWindows) {
    return SecurityPlatform.Windows;
  }
  if (Platform.isIOS) {
    return SecurityPlatform.iOS;
  }
  if (Platform.isMacOS) {
    return SecurityPlatform.macOS;
  }
}

class _NativeAppConfig implements AppConfig {
  final SecurityPlatform securityPlatform;

  _NativeAppConfig({this.securityPlatform});

  TlsPolicy get tlsPolicy {
    switch (securityPlatform) {
      case SecurityPlatform.Android:
        return TlsPolicy.remoteOnly;
      case SecurityPlatform.iOS:
        // TODO not tested yet
        return TlsPolicy.never;
      case SecurityPlatform.Windows:
      // TODO not tested yet
        return TlsPolicy.never;
      case SecurityPlatform.Linux:
      // TODO not tested yet
        return TlsPolicy.never;
      case SecurityPlatform.macOS:
      // TODO not tested yet
        return TlsPolicy.never;
    }
  }

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
    // This shouldn't be necessary anyway in a native app because we can choose
    // to be fine with a self-signed certificate (at least on Android).
    return null;
  }

  @override
  Widget svgImage(String assetPath,
      {Color color, BoxFit fit, double width, double height}) {
    return SvgPicture.asset(
      assetPath,
      color: color,
      fit: fit,
      width: width,
      height: height,
    );
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
