import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:realearn_companion/domain/connection.dart';
import 'package:realearn_companion/domain/preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../app_config.dart';
import 'space.dart';

/// We need it to be stateful because we need to replace the WebSocketChannel
/// whenever we initiate a reconnect.
class ConnectionBuilder extends StatefulWidget {
  final ConnectionData connectionData;
  final List<String> topics;
  final Widget Function(BuildContext context, Stream<dynamic> messages) builder;

  ConnectionBuilder({
    required this.connectionData,
    required this.topics,
    required this.builder,
  });

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
  Stream<dynamic> webSocketStream = Stream.empty();

  void notifyTimeout() {
    setState(() {
      connectionStatus = ConnectionStatus.Timeout;
    });
    var lines = [
      "Couldn't connect to ReaLearn within ${connectTimeoutInSeconds} seconds.",
      "",
      "Please consider the following advice:",
      "- Make sure this device has Wi-Fi enabled.",
      "- Make sure the computer running REAPER and this device are in the same Wi-Fi network.",
      "- Make sure REAPER and ReaLearn are running.",
      if (!widget.connectionData.isGenerated) "- Make sure the connection data you entered is correct.",
      "- Make sure your firewall is configured correctly (step 4 in ReaLearn's projection setup).",
    ];
    var dialog = AlertDialog(
      title: Text("Connection failed"),
      content: SingleChildScrollView(child: MarkdownBody(data: lines.join("\n"))),
      actions: [
        TextButton(
          child: Text("Cancel"),
          onPressed: () {
            App.instance.router.pop(context);
            App.instance.router.pop(context);
          },
        ),
        TextButton(
          child: Text("Retry"),
          onPressed: () {
            App.instance.router.pop(context);
            connect();
          },
        ),
      ],
    );
    showDialogCustom(dialog);
  }

  void showDialogCustom(AlertDialog dialog) {
    showDialog(
      context: context,
      builder: (BuildContext context) => dialog,
    );
  }

  void notifyTrustIssue() {
    setState(() {
      connectionStatus = ConnectionStatus.TrustIssue;
    });
    var instructions = getTrustInstructions();
    var action = instructions.action;
    var dialog = AlertDialog(
      title: Text("Almost there!"),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          height: 400,
          child: MarkdownBody(data: instructions.lines.join("\n")),
        ),
      ),
      actions: [
        if (action != null)
          TextButton(
            child: Text(action.name),
            onPressed: () {
              launchUrl(action.url);
            },
          ),
        TextButton(
          child: Text("Retry"),
          onPressed: () {
            App.instance.router.pop(context);
            connect();
          },
        ),
      ],
    );
    showDialogCustom(dialog);
  }

  /**
   * Browser trust issue measure 1 (preferred if possible because very easy).
   *
   * URL that needs to be opened in browser to accept that the certificate is
   * insecure (alternative to trusting the certificate, available in some
   * browser/OS combinations).
   */
  Uri get trustExceptionUrl => widget.connectionData.httpBaseUri;

  /**
   * Browser trust issue measure 2 (nice and clean but slightly more effort
   * than measure 1).
   *
   * URL which points to a text file containing the certificate content that's
   * part of the QR code. Falls back to the insecure certificate download URL
   * that exposes the server certificate via HTTP without TLS.
   */
  Uri get certificateDownloadUrl {
    final data = widget.connectionData;
    final certContent = data.certContent;
    if (certContent == null) {
      // QR code didn't contain certificate content or connection data was
      // entered manually. Fall back to insecure server-facing certificate
      // download URL.
      return insecureCertificateDownloadUrl;
    }
    return App.instance.config.createCertObjectUrl(certContent) ?? insecureCertificateDownloadUrl;
  }

  Uri get insecureCertificateDownloadUrl {
    var data = widget.connectionData;
    // TODO-medium Chrome already complains that we shouldn't redirect a https
    //  page to http. But if we redirect to https, we have an additional warning.
    //  Maybe just include in instructions.
    return Uri.parse("http://${data.host}:${data.httpPort}/realearn.cer");
  }

  TrustInstructions getTrustInstructions() {
    var securityPlatform = App.instance.config.securityPlatform;
    var header =
        "Congratulations, connection is possible. There's just one step left to make it work. You need to tell your browser that connecting to your personal ReaLearn installation is secure.";
    // This sounds more serious than it is, it's just that browsers nowadays have a lot of security requirements (which is a good thing in general).
    // Even though ReaLearn Companion will not ask you for a password or anything like that and therefore security is secondary, it uses browser technology and therefore is bound to conform to its security rules.
    var footer = "When you are done, come back here and retry.";
    switch (securityPlatform) {
      case SecurityPlatform.Android:
        return TrustInstructions(lines: [
          header,
          "",
          "Proceed as follows:",
          "1. Download your personal ReaLearn certificate (generated by ReaLearn itself). The Android Certificate Installer will open.",
          "   - In case it doesn't open: Go to Android settings → Security → (More settings) → Encryption and credentials → Install from storage → Select the previously downloaded certificate file in the \"Downloads\" folder.",
          "2. Give the certificate the name \"ReaLearn\", select \"VPN and apps\" as credential use and press OK",
          "",
          footer
        ], action: TrustAction(name: "Download certificate", url: certificateDownloadUrl));
      case SecurityPlatform.iOS:
        return TrustInstructions(lines: [
          header,
          "",
          "Proceed as follows:",
          "1. Download your personal \"ReaLearn\" profile (generated by ReaLearn itself). It contains the certificate for a secure connection.",
          "2. Install the profile! iOS is going to instruct you how to install it.",
          "3. In your iOS settings, go to General → About → Certificate Trust Settings and enable full trust for the root certificate \"ReaLearn\"",
          "",
          footer
        ], action: TrustAction(name: "Download profile", url: certificateDownloadUrl));
      case SecurityPlatform.Windows:
      case SecurityPlatform.macOS:
      case SecurityPlatform.Linux:
        return TrustInstructions(
          lines: [
            header,
            "",
            "Proceed as follows:",
            "1. Navigate to the ReaLearn server page.",
            "2. The browser will complain that this certificate is untrusted. Allow the browser to make an exception.",
            "",
            footer
          ],
          action: TrustAction(
            name: "Navigate to ReaLearn server page",
            url: trustExceptionUrl,
          ),
        );
    }
  }

  void notifyConnectionPossible() {
    Timer(Duration(seconds: 1), () {
      if (!mounted) {
        return;
      }
      debugPrint("Memorize as last connection...");
      final prefs = context.read<AppPreferences>();
      prefs.memorizeAsLastConnection(widget.connectionData.palette);
    });
    final wsUrl = widget.connectionData.buildWebSocketUrl(widget.topics);
    log("Connecting to $wsUrl ...");
    final channel = WebSocketChannel.connect(wsUrl);
    var connectedAtLeastOnce = false;
    final stream = channel.stream.tap(
      (_) {
        // log("WebSocket message received");
        connectedAtLeastOnce = true;
      },
      onDone: () {
        print("WebSocket connection closed");
        if (connectedAtLeastOnce) {
          connect();
        }
      },
      onError: (e, trace) {
        print("WebSocket error: $e");
        if (!connectedAtLeastOnce && e is WebSocketChannelException) {
          // Flutter Web: On Chrome for Android I observed that sometimes the HTTP
          // connection succeeds but the WebSocket connection gets
          // ERR_CERT_AUTHORITY_INVALID.
          notifyTrustIssue();
        }
      },
    ).asBroadcastStream();
    setState(() {
      webSocketStream = stream;
      connectionStatus = ConnectionStatus.Connected;
      successfulConnectsCount += 1;
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
              "${isReconnect ? 'Reconnecting' : 'Connecting'} to ReaLearn...",
              style: Theme.of(context).textTheme.headlineSmall,
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
        return widget.builder(context, webSocketStream);
      default:
        throw UnsupportedError("unknown connection status");
    }
  }

  @override
  void initState() {
    super.initState();
    connect();
  }

  bool get isReconnect => successfulConnectsCount > 0;

  void connect() async {
    setState(() {
      connectionStatus = ConnectionStatus.Connecting;
    });
    try {
      // TODO-low Use one client for all requests
      // TODO-low Use head (it always brings a timeout in my case)
      var uri = widget.connectionData.httpBaseUri;
      debugPrint("Connecting to URI ${uri}...");
      var responseFuture = http.get(uri);
      var awaitedFuture =
          isReconnect ? responseFuture : responseFuture.timeout(Duration(seconds: connectTimeoutInSeconds));
      await awaitedFuture;
      notifyConnectionPossible();
    } on TimeoutException catch (_) {
      notifyTimeout();
    // } on SocketException catch (ex) {
    //   final osError = ex.osError;
    //   if (osError != null) {
    //       if (osError.errorCode == 1) {
    //         // Operation not permitted => https://stackoverflow.com/a/65866640
    //       }
    //   }
    //   notifyTrustIssue();
    } on http.ClientException catch (ex) {
      notifyTrustIssue();
    }
  }
}

class TrustInstructions {
  final List<String> lines;
  final TrustAction? action;

  TrustInstructions({required this.lines, this.action});
}

class TrustAction {
  final String name;
  final Uri url;

  TrustAction({required this.name, required this.url});
}
