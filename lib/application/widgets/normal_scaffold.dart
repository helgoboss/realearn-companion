import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app.dart';

class NormalScaffold extends StatelessWidget {
  final Widget child;
  final bool hideAppBar;
  final EdgeInsets padding;

  const NormalScaffold(
      {Key key,
      this.child,
      this.hideAppBar = false,
      this.padding = const EdgeInsets.symmetric(horizontal: 30)})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: hideAppBar
          ? null
          : AppBar(
              title: const Text('ReaLearn Companion'),
            ),
      body: Stack(
        children: [
          Center(child: Background()),
          Container(
            alignment: Alignment.center,
            padding: padding,
            child: child,
            // In dark mode black might look better than the SVG background
            // color: Colors.black
          )
        ],
      ),
    );
  }
}

class Background extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return App.instance.config.svgImage(
      "assets/realearn_logo.svg",
      color: Theme.of(context).primaryColor.withOpacity(0.05),
      fit: BoxFit.cover,
      width: MediaQuery.of(context).size.shortestSide,
      height: MediaQuery.of(context).size.longestSide,
    );
  }
}
