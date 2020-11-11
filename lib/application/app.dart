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

  // TODO-high Keep this as part of AppPreferences
  Future<ConnectionDataPalette> loadLastConnection() async {
    var prefs = await SharedPreferences.getInstance();
    var jsonStrings = await prefs.getStringList('recentConnections');
    if (jsonStrings == null || jsonStrings.isEmpty) {
      return null;
    }
    var jsonString = jsonStrings.first;
    var jsonMap = jsonDecode(jsonString);
    var recentConnection = RecentConnection.fromJson(jsonMap);
    return recentConnection.toPalette();
  }

  void saveLastConnection(ConnectionDataPalette palette) async {
    var recentConnection = RecentConnection.fromPalette(palette);
    var jsonMap = recentConnection.toJson();
    var jsonString = jsonEncode(jsonMap);
    var prefs = await SharedPreferences.getInstance();
    // Maybe we want to save multiple recent connections in future so we use a
    // list of exactly one connection.
    await prefs.setStringList('recentConnections', [jsonString]);
  }

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
    return palette.use(tls: config.useTls);
  }
}
