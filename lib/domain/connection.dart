import 'dart:convert';

import 'package:flutter/widgets.dart';

class ConnectionData {
  final String host;
  final String httpPort;
  final String httpsPort;
  final String sessionId;
  final bool isGenerated;
  final String certContent;

  ConnectionData(
      {@required this.host,
      @required this.httpPort,
      @required this.httpsPort,
      @required this.sessionId,
      @required this.isGenerated,
      this.certContent});

  bool isLocalhost() {
    return host == "localhost" || host == "127.0.0.1";
  }
}
