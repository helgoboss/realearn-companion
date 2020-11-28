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
  static App _instance;

  final AppConfig config;

  // We need the router hot-reloadable, so it's not final
  FluroRouter router;

  static run({config: AppConfig}) {
    _instance = App._privateConstructor(config: config);
    runApp(AppWidget());
  }

  static App get instance => _instance;

  App._privateConstructor({this.config});

  /**
   * Must be called in a function that's called on hot reload.
   */
  void configureHotReloadable() {
    router = FluroRouter();
    configureRoutes(router);
  }

  ConnectionData createConnectionData(ConnectionDataPalette palette) {
    // TODO There might be some browsers (macOS Safari?) which won't connect
    //  from a secure (companion app) website to a non-secure localhost, so
    //  maybe we should use TLS even then!
    return palette.use(tls: palette.isLocalhost() ? false : config.useTls);
  }
}
