import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:realearn_companion/application/widgets/splash_screen.dart';
import 'package:realearn_companion/domain/model.dart';
import 'package:realearn_companion/domain/preferences.dart';

import '../app.dart';

class AppWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Also rebuild routes on hot reload
    App.instance.configureHotReloadable();
    // Don't show status bar
    SystemChrome.setEnabledSystemUIOverlays([]);
    return FutureBuilder(
      future: AppPreferences.load(),
      builder: (BuildContext context, AsyncSnapshot<AppPreferences> snapshot) {
        if (!snapshot.hasData) {
          return SplashScreen();
        }
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (context) => snapshot.data),
            ChangeNotifierProvider(create: (context) => ControllerModel()),
          ],
          child: Consumer<AppPreferences>(
            builder: (context, prefs, _) => MaterialApp(
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
              themeMode: prefs.themeMode,
              onGenerateRoute: App.instance.router.generator,
            ),
          ),
        );
      },
    );
  }
}
