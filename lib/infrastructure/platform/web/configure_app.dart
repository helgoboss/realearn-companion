import 'dart:html';

import 'package:flutter/src/painting/box_fit.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:platform_detect/platform_detect.dart';
import 'qr_code_scanner.dart';

import '../../../application/app_config.dart';

AppConfig configureApp(List<String> arguments) {
  setUrlStrategy(PathUrlStrategy());
  return _WebAppConfig(
      tlsPolicy: determineTlsPolicy(),
      securityPlatform: _getSecurityPlatform());
}

TlsPolicy determineTlsPolicy() {
  bool appIsServedViaTls = Uri.base.isScheme("https");
  if (browser.isSafari) {
    // iPad Safari can ONLY connect to non-TLS websocket f the companion app URL
    // is also non-TLS - which in practice is not advisable because the companion
    // app is a web app in the internet and we should by all means protect it
    // via TLS. Also, without https there's no way to get the camera stream for
    // scanning QR code.
    return appIsServedViaTls ? TlsPolicy.evenForLocalhost : TlsPolicy.never;
  } else {
    // Just tested for Chrome
    // TODO-low Test if this is the same for Firefox, IE, Edge and Opera
    return appIsServedViaTls ? TlsPolicy.remoteOnly : TlsPolicy.remoteOnly;
  }
}

class _WebAppConfig implements AppConfig {
  final TlsPolicy tlsPolicy;
  final SecurityPlatform securityPlatform;

  _WebAppConfig({this.tlsPolicy, this.securityPlatform});

  @override
  WebQrCodeScan scanQrCode(BuildContext context) {
    return new WebQrCodeScan();
  }

  @override
  Future<bool> deviceHasCamera() async {
    if (window.navigator.mediaDevices == null) {
      return false;
    }
    var devices = await window.navigator.mediaDevices.enumerateDevices();
    return devices.any((dev) => dev.kind == 'videoinput');
  }

  @override
  Uri createCertObjectUrl(String certContent) {
    const mimeType = "application/pkix-cert";
    if (browser.isSafari) {
      // Unfortunately, Safari doesn't see a profile when downloading a blob
      // object URL. Also tried it with data URI, same effect: 'Do you want to
      // download "Unknown"?'
      return null;
    }
    var blob = Blob([certContent], mimeType);
    return Uri.parse(Url.createObjectUrlFromBlob(blob));
  }

  @override
  Widget svgImage(String assetPath,
      {Color color, BoxFit fit, double width, double height}) {
    return Image.network(
      assetPath,
      color: color,
      fit: fit,
      width: width,
      height: height,
    );
  }

  @override
  String get initialRoute => null;
}

SecurityPlatform _getSecurityPlatform() {
  if (isAndroid()) {
    return SecurityPlatform.Android;
  } else if (operatingSystem.isWindows) {
    return SecurityPlatform.Windows;
  } else if (operatingSystem.isLinux) {
    return SecurityPlatform.Linux;
  } else if (operatingSystem.isMac) {
    if (isIOs()) {
      return SecurityPlatform.iOS;
    } else {
      return SecurityPlatform.macOS;
    }
  }
}

final List<String> _iOsNeedles = [
  'iPad Simulator',
  'iPhone Simulator',
  'iPod Simulator',
  'iPad',
  'iPhone',
  'iPod'
];

bool isIOs() {
  var foundNeedle = _iOsNeedles.any((name) =>
      window.navigator.platform.contains(name) ||
      window.navigator.userAgent.contains(name));
  return foundNeedle || window.navigator.maxTouchPoints > 0;
}

bool isAndroid() =>
    window.navigator.platform == 'Android' ||
    window.navigator.userAgent.contains('Android');
