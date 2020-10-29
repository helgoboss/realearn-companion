import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:realearn_companion/model.dart';
import 'package:platform_detect/platform_detect.dart';

AppConfig configureApp() {
  setUrlStrategy(PathUrlStrategy());
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
  var useTls = !(browser.isSafari && Uri.base.isScheme("http"));
  return AppConfig(useTls: useTls);
}