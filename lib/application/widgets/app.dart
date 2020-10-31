import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';

class AppWidget extends StatefulWidget {
  @override
  State createState() {
    return AppWidgetState();
  }
}

class AppWidgetState extends State<AppWidget> {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);
    return MaterialApp(
      title: 'ReaLearn Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.deepPurple,
        // visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        // visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      themeMode: ThemeMode.light,
      onGenerateRoute: App.instance.router.generator,
    );
  }
}
