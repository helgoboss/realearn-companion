import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:realearn_companion/domain/model.dart';

import '../app.dart';

class AppWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    App.instance.configureHotReloadable();
    SystemChrome.setEnabledSystemUIOverlays([]);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ControllerModel>(
          create: (context) => ControllerModel(null),
        ),
        ChangeNotifierProvider<ControllerRoutingModel>(
          create: (context) => ControllerRoutingModel(null),
        )
      ],
      child: MaterialApp(
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
      ),
    );
  }
}