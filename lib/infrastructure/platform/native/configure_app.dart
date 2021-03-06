import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:camera/camera.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../application/app_config.dart';

AppConfig configureApp(List<String> arguments) {
  HttpOverrides.global = new _CustomHttpOverrides();
  return _NativeAppConfig(
    securityPlatform: getNativeSecurityPlatform(),
    initialRoute: arguments.isEmpty ? null : arguments[0],
  );
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
  throw UnsupportedError("unknown native security platform");
}

class _NativeAppConfig implements AppConfig {
  final SecurityPlatform securityPlatform;
  final String? initialRoute;

  _NativeAppConfig({required this.securityPlatform, this.initialRoute});

  TlsPolicy get tlsPolicy {
    switch (securityPlatform) {
      case SecurityPlatform.Android:
        return TlsPolicy.remoteOnly;
      case SecurityPlatform.iOS:
        return TlsPolicy.remoteOnly;
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
  Uri? createCertObjectUrl(String content) {
    // This shouldn't be necessary anyway in a native app because we can choose
    // to be fine with a self-signed certificate (at least on Android).
    return null;
  }

  @override
  Widget svgImage(
    String assetPath, {
    required Color color,
    required BoxFit fit,
    required double width,
    required double height,
  }) {
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
  HttpClient createHttpClient(SecurityContext? context) {
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
