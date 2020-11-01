import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:realearn_companion/domain/connection.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../app.dart';
import '../app_config.dart';
import 'space.dart';

/**
 * We need it to be stateful because we need to replace the WebSocketChannel
 * whenever we initiate a reconnect.
 */
class ConnectionBuilder extends StatefulWidget {
  final ConnectionData connectionData;
  final List<String> topics;
  final Widget Function(BuildContext context, Stream<dynamic> messages) builder;

  // TODO There might be some browsers (macOS Safari?) which won't connect
  //  from a secure (companion app) website to a non-secure localhost, so
  //  maybe we should use TLS even then!
  ConnectionBuilder(
      {@required ConnectionDataPalette connectionDataPalette,
      this.topics,
      this.builder})
      : connectionData =
            connectionDataPalette.use(tls: App.instance.config.useTls);

  @override
  State<StatefulWidget> createState() {
    return ConnectionBuilderState();
  }
}

enum ConnectionStatus { Connecting, Timeout, TrustIssue, Connected }

const connectTimeoutInSeconds = 5;

class ConnectionBuilderState extends State<ConnectionBuilder> {
  int successfulConnectsCount = 0;
  ConnectionStatus connectionStatus = ConnectionStatus.Connecting;
  WebSocketChannel webSocketChannel = null;

  void notifyTimeout() {
    setState(() {
      connectionStatus = ConnectionStatus.Timeout;
    });
    var lines = [
      "Couldn't connect to ReaLearn within ${connectTimeoutInSeconds} seconds.",
      "",
      "Please try the following things:",
      if (!widget.connectionData.isGenerated)
        "- Make sure the connection data you entered is correct.",
      "- Open ports in your firewall (step 4 in ReaLearn's projection setup).",
      "- Make sure the computer running REAPER and this device are in the same network."
    ];
    var dialog = AlertDialog(
      title: Text("Connection failed"),
      content: MarkdownBody(data: lines.join("\n")),
      actions: [
        FlatButton(
          child: Text("Cancel"),
          onPressed: () {
            App.instance.router.pop(context);
            App.instance.router.pop(context);
          },
        ),
        FlatButton(
          child: Text("Retry"),
          onPressed: () {
            App.instance.router.pop(context);
            connect();
          },
        ),
      ],
    );
    showDialog(context: context, builder: (BuildContext context) => dialog);
  }

  void notifyTrustIssue() {
    setState(() {
      connectionStatus = ConnectionStatus.TrustIssue;
    });
    var lines = getCertificateInstructions();
    var dialog = AlertDialog(
      title: Text("Almost there"),
      content: MarkdownBody(data: lines.join("\n")),
      actions: [
        FlatButton(
          child: Text("Download certificate"),
          onPressed: () {
            App.instance.router.pop(context);
          },
        ),
      ],
    );
    showDialog(context: context, builder: (BuildContext context) => dialog);
    // // TODO-medium Chrome already complains that we shouldn't redirect a https
    // //  page to http. But if we redirect to https, we have an additional warning.
    // //  Maybe just include in instructions. Or on Android/Chrome, maybe we can
    // //  just skip the certificate installation and just accept in the browser!
    // var certRedirectUrl = getCertRedirectUrl(
    //     Uri.parse("http://${conData.host}:${conData.httpPort}/realearn.cer"),
    //     conData.httpBaseUri);
    // // TODO-high As soon as we have a proper presentation (not just alerts),
    // //  try to provide cert download via download link by converting args.getCertContent()
    // //  to a blob. https://stackoverflow.com/questions/19327749/javascript-blob-filename-without-link
    // // tryConnect(httpBaseUri, args.isGenerated(), args.getCertContent(), certificateUrl);
    // App.instance.config.useTlsCertificate(
    //     widget.connectionDataPalette.certContent, certRedirectUrl);
  }

  void notifyConnectionPossible() {
    var wsUrl = widget.connectionData.buildWebSocketUrl(widget.topics);
    webSocketChannel = WebSocketChannel.connect(wsUrl);
    setState(() {
      connectionStatus = ConnectionStatus.Connected;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (connectionStatus) {
      case ConnectionStatus.Connecting:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Connecting to ReaLearn...",
              style: Theme.of(context).textTheme.headline5,
            ),
            Space(),
            LinearProgressIndicator(
              minHeight: 10,
            ),
          ],
        );
      case ConnectionStatus.Timeout:
        return SizedBox.shrink();
      case ConnectionStatus.TrustIssue:
        return SizedBox.shrink();
      case ConnectionStatus.Connected:
        return widget.builder(context, webSocketChannel.stream);
    }
  }

  @override
  void initState() {
    super.initState();
    connect();
  }

  void connect() async {
    setState(() {
      connectionStatus = ConnectionStatus.Connecting;
    });
    try {
      // TODO-low Use one client for all requests
      // TODO-low Use head (it always brings a timeout in my case)
      await http
          .get(widget.connectionData.httpBaseUri)
          .timeout(Duration(seconds: connectTimeoutInSeconds));
      notifyConnectionPossible();
    } on TimeoutException catch (_) {
      notifyTimeout();
    } on http.ClientException catch (_) {
      notifyTrustIssue();
    }
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
