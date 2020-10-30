import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:realearn_companion/application/routes.dart';

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
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      onGenerateRoute: App.instance.router.generator,
    );
  }
}

class RootWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      App.instance.router.navigateTo(context, controllerRoutingRoute);
    });
    return Text("TODO You are going to be forwarded");
  }
}
