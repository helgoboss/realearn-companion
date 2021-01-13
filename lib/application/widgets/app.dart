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
    return FutureBuilder(
      future: AppPreferences.load(),
      builder: (BuildContext context,
          AsyncSnapshot<AppPreferences> app_prefs_snapshot) {
        if (!app_prefs_snapshot.hasData) {
          return SecondSplashScreen();
        }
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(
                create: (context) => app_prefs_snapshot.data),
            ChangeNotifierProvider(create: (context) => ControllerModel()),
            ChangeNotifierProvider(
                create: (context) => ControllerRoutingModel()),
          ],
          child: Consumer<AppPreferences>(
            builder: (context, prefs, _) {
              debugPrint("Rebuilding material app");
              return MaterialApp(
                title: 'ReaLearn Companion',
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  brightness: Brightness.light,
                  primaryColor: Colors.blue.shade700,
                  accentColor: Colors.deepOrange,
                ),
                darkTheme: ThemeData(
                  brightness: Brightness.dark,
                  primarySwatch: Colors.amber,
                  accentColor: Colors.blueAccent,
                ),
                themeMode: prefs.themeMode,
                onGenerateRoute: App.instance.router.generator,
              );
            },
          ),
        );
      },
    );
  }
}
