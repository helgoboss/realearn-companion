import 'package:flutter/material.dart';
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
                create: (context) => app_prefs_snapshot.data!),
            ChangeNotifierProvider(create: (context) => ControllerModel()),
            ChangeNotifierProvider(
                create: (context) => ControllerRoutingModel()),
            ChangeNotifierProvider(
                create: (context) => ControlValuesModel()),
          ],
          child: Consumer<AppPreferences>(
            builder: (context, prefs, _) {
              debugPrint("Rebuilding material app");
              return MaterialApp(
                title: 'ReaLearn Companion',
                // initialRoute: App.instance.config.initialRoute,
                initialRoute: App.instance.config.initialRoute,
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  brightness: Brightness.light,
                  colorSchemeSeed: Colors.blue.shade700,
                ),
                darkTheme: ThemeData(
                  brightness: Brightness.dark,
                  colorSchemeSeed: Colors.amber,
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
