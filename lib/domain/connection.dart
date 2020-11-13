import 'dart:convert';

import 'package:flutter/widgets.dart';

/**
 * A "palette" of connection data to choose from.
 */
class ConnectionDataPalette {
  final String host;
  final String httpPort;
  final String httpsPort;
  final String sessionId;
  final bool isGenerated;
  final String certContent;

  ConnectionDataPalette(
      {@required this.host,
      @required this.httpPort,
      @required this.httpsPort,
      @required this.sessionId,
      @required this.isGenerated,
      this.certContent})
      : assert(host != null && host.isNotEmpty),
        assert(httpPort != null && httpPort.isNotEmpty),
        assert(httpsPort != null && httpsPort.isNotEmpty),
        assert(sessionId != null && sessionId.isNotEmpty);

  bool isLocalhost() {
    return host == "localhost" || host == "127.0.0.1";
  }

  ConnectionData use({bool tls}) {
    return ConnectionData(tls, this);
  }
}

/**
 * Actual data which is used for connection.
 */
class ConnectionData {
  final bool tls;
  final ConnectionDataPalette palette;

  ConnectionData(this.tls, this.palette);

  Uri get httpBaseUri => Uri.parse("$httpProtocol://$host:$port");

  Uri get wsBaseUri => Uri.parse("$wsProtocol://$host:$port");

  String get httpPort => palette.httpPort;

  String get httpProtocol => tls ? "https" : "http";

  String get wsProtocol => tls ? "wss" : "ws";

  String get host => palette.host;

  String get port => tls ? palette.httpsPort : palette.httpPort;

  String get certContent => palette.certContent;

  String get sessionId => palette.sessionId;

  bool get isGenerated => palette.isGenerated;

  Uri buildWebSocketUrl(List<String> topics) {
    var joinedTopics = topics.join(",");
    return wsBaseUri.resolve("/ws?topics=$joinedTopics");
  }
}
