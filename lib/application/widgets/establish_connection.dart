import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:realearn_companion/domain/connection.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../app.dart';
import '../app_config.dart';
import 'controller_routing.dart';

class EstablishConnectionWidget extends StatelessWidget {
  final ConnectionDataPalette connectionDataPalette;

  EstablishConnectionWidget({@required this.connectionDataPalette});

  @override
  Widget build(BuildContext context) {
    // TODO There might be some browsers (macOS Safari?) which won't connect
    //  from a secure (companion app) website to a non-secure localhost, so
    //  maybe we should use TLS even then!
    var conData = connectionDataPalette.use(tls: App.instance.config.useTls);
    // TODO-medium Chrome already complains that we shouldn't redirect a https
    //  page to http. But if we redirect to https, we have an additional warning.
    //  Maybe just include in instructions. Or on Android/Chrome, maybe we can
    //  just skip the certificate installation and just accept in the browser!
    var certRedirectUrl = getCertRedirectUrl(
        Uri.parse("http://${conData.host}:${conData.httpPort}/realearn.cer"),
        conData.httpBaseUri);
    // TODO-high As soon as we have a proper presentation (not just alerts),
    //  try to provide cert download via download link by converting args.getCertContent()
    //  to a blob. https://stackoverflow.com/questions/19327749/javascript-blob-filename-without-link
    // tryConnect(httpBaseUri, args.isGenerated(), args.getCertContent(), certificateUrl);
    tryConnect(conData.httpBaseUri, conData.isGenerated, null, certRedirectUrl);
    return ControllerRoutingWidget(
      title: 'ReaLearn',
      channel: WebSocketChannel.connect(conData.wsUri),
      wsBaseUri: conData.wsBaseUri,
      httpBaseUri: conData.httpBaseUri,
    );
  }
}

Uri getCertRedirectUrl(Uri insecureDownloadUrl, Uri rootUrl) {
  if (App.instance.config.securityPlatform == SecurityPlatform.Windows) {
    // TODO-medium As soon as we have proper presentation, open root URL in new
    //  tab so that we can easily go back!
    return rootUrl;
  }
  return insecureDownloadUrl;
}

/**
 * certContent may be null (if QR code didn't contain it or entered manually)
 */
tryConnect(
    Uri uri, bool generated, String certContent, Uri certRedirectUrl) async {
  var seconds = 5;
  try {
    // TODO-low Use one client for all requests
    // TODO-low Use head (it always brings a timeout in my case)
    await http.get(uri).timeout(Duration(seconds: seconds));
  } on TimeoutException catch (_) {
    var lines = [
      "Couldn't connect to ReaLearn at ${uri} within ${seconds} seconds.",
      "",
      "Please try the following things:",
      if (!generated) "- Make sure the connection data you entered is correct.",
      "- Open ports in your firewall (step 4 in ReaLearn's projection setup).",
      "- Make sure the computer running REAPER and this device are in the same network."
    ];

    App.instance.config.alert(lines.join("\n"));
  } on http.ClientException catch (_) {
    var lines = getCertificateInstructions();
    App.instance.config.alert(lines.join("\n"));
    App.instance.config.useTlsCertificate(certContent, certRedirectUrl);
  }
}

List<String> getCertificateInstructions() {
  var header =
      "Connection is possible, congratulations! We are not there yet. You still need to promise ${App.instance.config.securityPlatform} that connecting to your personal ReaLearn installation is secure.";
  var footer =
      "When you are done, come back to this page and reload it or scan the QR code again.\n"
      "\n"
      "This sounds more serious than it is, it's just that browsers nowadays have a lot of security requirements (which is a good thing in general).\n"
      "Even though ReaLearn Companion will not ask you for a password or anything like that and therefore security is secondary, it uses browser technology and therefore is bound to conform to its security rules.";
  switch (App.instance.config.securityPlatform) {
    case SecurityPlatform.Android:
      return [
        header,
        "",
        "Proceed as follows:",
        "1. When you press continue, a certificate file will be downloaded. Tap the downloaded file and the android Certificate Installer will open.",
        "   - In case it doesn't open: Go to Android settings → Security → (More settings) → Encryption and credentials → Install from storage → Select the previously downloaded certificate file in the \"Downloads\" folder.",
        "3. Give the certificate the name \"ReaLearn\", select \"VPN and apps\" as credential use and press OK",
        "",
        footer
      ];
    case SecurityPlatform.iOS:
      return [
        header,
        "",
        "Proceed as follows:",
        "1. When you press continue, you will be provided with the profile \"ReaLearn\" that contains the certificate for a secure connection. iOS is going to instruct you how to install it.",
        "2. Install the profile!",
        "3. In your iOS settings, go to General → About → Certificate Trust Settings and enable full trust for the root certificate \"ReaLearn\"",
        "",
        footer
      ];
    case SecurityPlatform.Windows:
      return [
        header,
        "",
        "Proceed as follows:",
        "1. When you press continue, you will be forwarded to the ReaLearn server page.",
        "2. Accept that the certificate is untrusted.",
        "",
        footer
      ];
    case SecurityPlatform.Linux:
      return ["TODO Linux certificate instructions"];
    case SecurityPlatform.macOS:
      return ["TODO macOS certificate instructions"];
  }
}
