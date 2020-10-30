import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:realearn_companion/application/routes.dart';

import 'app_config.dart';
import 'widgets/app.dart';

class App {
  static App _instance;

  final AppConfig config;
  final FluroRouter router;

  static run({config: AppConfig}) {
    _instance = App._privateConstructor(config: config);
    runApp(AppWidget());
  }

  static App get instance => _instance;

  App._privateConstructor({this.config}) : router = FluroRouter() {
    configureRoutes(router);
  }
}
