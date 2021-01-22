import 'dart:convert';
import 'dart:developer';

import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';

import 'package:flutter/widgets.dart';
import 'package:realearn_companion/application/widgets/controller_routing.dart';
import 'package:realearn_companion/application/widgets/enter_connection_data.dart';
import 'package:realearn_companion/application/widgets/scan_connection_data.dart';
import 'package:realearn_companion/domain/connection.dart';
import 'package:wakelock/wakelock.dart';

import 'app.dart';
import 'widgets/root.dart';

String rootRoute = "/";
String scanConnectionDataRoute = "/scan-connection-data";
String enterConnectionDataRoute = "/enter-connection-data";
String controllerRoutingRoute = "/controller-routing";

String getControllerRoutingRoute(ConnectionArgs args) {
  return "$controllerRoutingRoute?${args.toQueryString()}";
}

// Called on hot reload
void configureRoutes(FluroRouter router) {
  // We don't use global handler variables because we want routes to be
  // hot-reloadable.
  log("Reconfigure routes");
  router.notFoundHandler = Handler(
      handlerFunc: (BuildContext context, Map<String, List<String>> params) {
    return Text("Route doesn't exist");
  });
  router.define(rootRoute, handler: Handler(
      handlerFunc: (BuildContext context, Map<String, List<String>> params) {
    Wakelock.disable();
    return RootWidget();
  }));
  router.define(scanConnectionDataRoute, handler: Handler(
      handlerFunc: (BuildContext context, Map<String, List<String>> params) {
    var scan = App.instance.config.scanQrCode(context);
    return ScanConnectionDataWidget(
        scannerWidget: scan.widget, result: scan.result);
  }));
  router.define(enterConnectionDataRoute, handler: Handler(
      handlerFunc: (BuildContext context, Map<String, List<String>> params) {
    return EnterConnectionDataWidget();
  }));
  router.define(controllerRoutingRoute, handler: Handler(
      handlerFunc: (BuildContext context, Map<String, List<String>> params) {
    final args = ConnectionArgs.fromParams(params);
    if (!args.isComplete) {
      // TODO-medium Display warning and schedule navigation to root route.
      //  This can happen when entering URL or call from cmd line manually
      return Text("Incomplete connection args: $params");
    }
    Wakelock.enable();
    return ControllerRoutingPage(
      connectionData: App.instance.createConnectionData(args.toPalette()),
    );
  }));
}

class ConnectionArgs {
  final String host;
  final String httpPort;
  final String httpsPort;
  final String sessionId;
  final String generated;
  final String cert;

  factory ConnectionArgs.fromParams(Map<String, List<String>> params) {
    return ConnectionArgs(
        host: params['host']?.first,
        httpPort: params['http-port']?.first,
        httpsPort: params['https-port']?.first,
        sessionId: params['session-id']?.first,
        generated: params['generated']?.first,
        cert: params['cert']?.first);
  }

  factory ConnectionArgs.fromPalette(ConnectionDataPalette data) {
    return ConnectionArgs(
      host: data.host,
      httpPort: data.httpPort,
      httpsPort: data.httpsPort,
      sessionId: data.sessionId,
      cert: _convertCertContentToArg(data.certContent),
    );
  }

  ConnectionArgs(
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

  String toQueryString() {
    var params = {
      'host': host,
      'http-port': httpPort,
      'https-port': httpsPort,
      'session-id': sessionId,
      'generated': generated,
      'cert': cert,
    };
    return Uri(queryParameters: params).query;
  }

  ConnectionDataPalette toPalette() {
    return ConnectionDataPalette(
        host: host,
        httpPort: httpPort,
        httpsPort: httpsPort,
        sessionId: sessionId,
        isGenerated: generated == "true",
        certContent: _convertCertArgToContent(cert));
  }

  static Codec<String, String> _stringToBase64Url = utf8.fuse(base64Url);

  static String _convertCertContentToArg(String certContent) {
    if (certContent == null) {
      return null;
    }
    return _stringToBase64Url.encode(certContent);
  }

  static String _convertCertArgToContent(String certArg) {
    if (certArg == null) {
      return null;
    }
    return _stringToBase64Url.decode(certArg);
  }
}
