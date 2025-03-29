import 'dart:convert';
import 'dart:developer';

import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:realearn_companion/application/routes.dart';
import 'package:realearn_companion/domain/connection.dart';
import 'package:realearn_companion/domain/preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_config.dart';
import 'widgets/app.dart';

class App {
  static late App _instance;

  final AppConfig config;

  // We need the router hot-reloadable, so it's not final
  late FluroRouter router;

  static run({required AppConfig config}) {
    _instance = App._privateConstructor(config: config);
    runApp(AppWidget());
  }

  static App get instance => _instance;

  App._privateConstructor({required this.config});

  /**
   * Must be called in a function that's called on hot reload.
   */
  void configureHotReloadable() {
    router = FluroRouter();
    configureRoutes(router);
  }

  ConnectionData createConnectionData(ConnectionDataPalette palette) {
    return palette.use(
      tls: shouldWeUseTls(config.tlsPolicy, palette.isLocalhost()),
    );
  }
}

bool shouldWeUseTls(TlsPolicy policy, bool isLocalhost) {
  switch (policy) {
    case TlsPolicy.never:
      return false;
    case TlsPolicy.remoteOnly:
      return !isLocalhost;
    case TlsPolicy.evenForLocalhost:
      return true;
  }
}
