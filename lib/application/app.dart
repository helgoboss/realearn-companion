import 'dart:developer';

import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:realearn_companion/application/routes.dart';

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

  /**
   * Must be called in a function that's called on hot reload.
   */
  void configureHotReloadable() {
    router = FluroRouter();
    configureRoutes(router);
  }

  App._privateConstructor({this.config});
}
