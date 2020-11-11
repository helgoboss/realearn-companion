import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realearn_companion/domain/preferences.dart';

import '../app.dart';

class NormalScaffold extends StatelessWidget {
  final Widget child;
  final AppBar appBar;
  final EdgeInsets padding;

  static AppBar defaultAppBar() {
    return AppBar(
      title: const Text('ReaLearn Companion'),
    );
  }

  const NormalScaffold({
    Key key,
    this.child,
    this.appBar,
    this.padding = const EdgeInsets.symmetric(horizontal: 30),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: Consumer<AppPreferences>(
          child: this.child,
          builder: (context, prefs, child) {
            var theme = Theme.of(context);
            var isDark = theme.brightness == Brightness.dark;
            return Stack(
              children: [
                if (prefs.backgroundImageEnabled) Center(child: Background()),
                Container(
                  alignment: Alignment.center,
                  padding: padding,
                  child: child,
                  color: prefs.highContrastEnabled
                      ? (isDark
                          ? theme.primaryColorDark
                          : theme.primaryColorLight)
                      : null,
                )
              ],
            );
          }),
    );
  }
}

class Background extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var isDark = theme.brightness == Brightness.dark;
    return App.instance.config.svgImage(
      "assets/realearn_logo.svg",
      color: theme.primaryColor.withOpacity(isDark ? 0.5 : 0.05),
      fit: BoxFit.cover,
      width: MediaQuery.of(context).size.shortestSide,
      height: MediaQuery.of(context).size.longestSide,
    );
  }
}
