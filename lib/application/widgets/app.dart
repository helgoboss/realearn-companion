
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:realearn_companion/domain/connection.dart';

import '../app.dart';

class AppWidget extends StatefulWidget {
  AppWidget();

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
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      onGenerateRoute: App.instance.router.generator,
    );
  }
}