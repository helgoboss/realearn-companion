import 'dart:io';

import 'model.dart';

class CustomHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    var customContext = new SecurityContext(withTrustedRoots: false);
    // customContext.setTrustedCertificates("C:\\REAPER\\ReaLearn\\certs\\192.168.178.57.pem");
    var client = super.createHttpClient(customContext);
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return client;
  }
}


AppConfig configureApp() {
  HttpOverrides.global = new CustomHttpOverrides();
  // TODO Android in latest versions requires TLS, iOS maybe not?
  return AppConfig(useTls: true);
}