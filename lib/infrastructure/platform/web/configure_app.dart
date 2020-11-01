import 'dart:html';

import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:platform_detect/platform_detect.dart';
import 'qr_code_scanner.dart';

import '../../../application/app_config.dart';

AppConfig configureApp() {
  setUrlStrategy(PathUrlStrategy());
  return _WebAppConfig(
      // TODO-low Revise this
      // iPad Safari can ONLY connect to non-TLS websocket f the companion app URL
      // is also non-TLS - which in practice is not advisable because the companion
      // app is a web app in the internet and we should by all means protect it
      // via TLS. Also, without https there's no way to get the camera stream for
      // scanning QR code.
      // Damn it! But the problem is: iPad Safari won't let us connect to the
      // websocket even if we imported the certificate as profile. Error code 1006.
      // Maybe it's an option to start in https for scanning the QR code and
      // redirect to the http app version (on Safari only) ... but this is not very
      // future-proof. Chrome already rejects http, so Safari might, too. It's also
      // not very secure.
      useTls: !(browser.isSafari && Uri.base.isScheme("http")),
      securityPlatform: _getSecurityPlatform());
}

class _WebAppConfig implements AppConfig {
  final bool useTls;
  final SecurityPlatform securityPlatform;

  _WebAppConfig({this.useTls, this.securityPlatform});

  @override
  void alert(String msg) {
    window.alert(msg);
  }

  @override
  WebQrCodeScan scanQrCode(BuildContext context) {
    return new WebQrCodeScan();
  }

  @override
  void useTlsCertificate(String certContent, Uri certRedirectUrl) {
    window.location.href = getCertHref(certContent, certRedirectUrl);
  }

  @override
  Future<bool> deviceHasCamera() {
    // TODO: implement hasCamera
    throw UnimplementedError();
  }
}

String getCertHref(String certContent, Uri certRedirectUrl) {
  if (certContent == null) {
    return certRedirectUrl.toString();
  } else {
    var blob = Blob([certContent], "application/pkix-cert");
    return Url.createObjectUrlFromBlob(blob);
  }
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
