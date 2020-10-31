import 'dart:convert';

import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';

import 'package:flutter/widgets.dart';
import 'package:realearn_companion/application/widgets/connection_data.dart';
import 'package:realearn_companion/application/widgets/controller_routing_connection.dart';
import 'package:realearn_companion/domain/connection.dart';

import 'app.dart';
import 'widgets/root.dart';

String rootRoute = "/";
String scanConnectionDataRoute = "/scan-connection-data";
String enterConnectionDataRoute = "/enter-connection-data";
String controllerRoutingRoute = "/controller-routing";

void configureRoutes(FluroRouter router) {
  router.notFoundHandler = Handler(
      handlerFunc: (BuildContext context, Map<String, List<String>> params) {
    return Text("Route doesn't exist");
  });
  router.define(rootRoute, handler: _rootHandler);
  router.define(scanConnectionDataRoute, handler: _scanConnectionDataHandler);
  router.define(enterConnectionDataRoute, handler: _enterConnectionDataHandler);
  router.define(controllerRoutingRoute, handler: _controllerRoutingHandler);
}

var _rootHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
      return RootWidget();
    });

var _scanConnectionDataHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
      return App.instance.config.qrCodeScanner();
    });

var _enterConnectionDataHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
      return ConnectionDataWidget();
    });

var _controllerRoutingHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  final args = _ConnectionArgs.fromParams(params);
  if (!args.isComplete) {
    // TODO-medium Display warning and schedule navigation to root route
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

  static _ConnectionArgs fromParams(Map<String, List<String>> params) {
    return _ConnectionArgs(
        host: params['host']?.first,
        httpPort: params['http-port']?.first,
        httpsPort: params['https-port']?.first,
        sessionId: params['session-id']?.first,
        generated: params['generated']?.first,
        cert: params['cert']?.first);
  }

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
