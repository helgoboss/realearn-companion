import 'package:flutter/material.dart';
import 'colors.dart' as colors;

/**
 * This one is shown shortly after the native splash screen while loading
 * preferences. It appears only *very* shortly, that's why it's just a
 * background color. That creates a seamless experience.
 */
class SecondSplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => Material(
        child: Container(
          color: colors.background
        ),
      ),
    );
  }
}
