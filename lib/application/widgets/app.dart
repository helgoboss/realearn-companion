import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';

class AppWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    App.instance.configureHotReloadable();
    SystemChrome.setEnabledSystemUIOverlays([]);
    return MaterialApp(
      title: 'ReaLearn Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.deepPurple,
        accentColor: Colors.redAccent.shade700,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.orange,
        accentColor: Colors.amberAccent,
      ),
      themeMode: ThemeMode.dark,
      onGenerateRoute: App.instance.router.generator,
    );
  }
}
