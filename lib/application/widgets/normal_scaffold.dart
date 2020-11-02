import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NormalScaffold extends StatelessWidget {
  final Widget child;
  final bool hideAppBar;

  const NormalScaffold({Key key, this.child, this.hideAppBar = false})
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
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: child,
          )
        ],
      ),
    );
  }
}

class Background extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var assetPath = "assets/realearn_logo.svg";
    var color = Theme.of(context).primaryColor.withOpacity(0.05);
    var fit = BoxFit.cover;
    var width = MediaQuery.of(context).size.shortestSide;
    var height = MediaQuery.of(context).size.longestSide;
    return kIsWeb
        ? Image.network(
            assetPath,
            color: color,
            fit: fit,
            width: width,
            height: height,
          )
        : SvgPicture.asset(
            assetPath,
            color: color,
            fit: fit,
            width: width,
            height: height,
          );
  }
}
