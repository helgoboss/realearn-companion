import 'dart:convert';

import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';

import 'package:flutter/widgets.dart';
import 'package:realearn_companion/application/widgets/controller_routing_connection.dart';
import 'package:realearn_companion/domain/connection.dart';

import 'app.dart';

String controllerRouting = "/controller-routing";

void configureRoutes(FluroRouter router) {
  router.notFoundHandler = Handler(
      handlerFunc: (BuildContext context, Map<String, List<String>> params) {
    print("ROUTE WAS NOT FOUND !!!");
    return Text("Route doesn't exist");
  });
  router.define(controllerRouting, handler: _controllerRoutingHandler);
}

var _controllerRoutingHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  final args = _ConnectionArgs(
      host: params['host']?.first,
      httpPort: params['http-port']?.first,
      httpsPort: params['https-port']?.first,
      sessionId: params['session-id']?.first,
      generated: params['generated']?.first,
      cert: params['cert']?.first);
  if (!args.isComplete) {
    return App.instance.config.qrCodeScanner();
  }
  return ControllerRoutingConnectionWidget(connectionData: args.toData());
});

class _ConnectionArgs {
  final String host;
  final String httpPort;
  final String httpsPort;
  final String sessionId;
  final String generated;
  final String cert;

  _ConnectionArgs(
      {this.host,
      this.httpPort,
      this.httpsPort,
      this.sessionId,
      this.generated,
      this.cert});

  bool get isComplete {
    return host != null ||
        httpPort != null ||
        httpsPort != null ||
        sessionId != null;
  }

  ConnectionData toData() {
    return ConnectionData(
        host: host,
        httpPort: httpPort,
        httpsPort: httpsPort,
        sessionId: sessionId,
        isGenerated: generated == "true",
        certContent: _getCertContent(cert));
  }

  static String _getCertContent(String certArg) {
    if (certArg == null) {
      return null;
    }
    Codec<String, String> stringToBase64Url = utf8.fuse(base64Url);
    return stringToBase64Url.decode(certArg);
  }
}
