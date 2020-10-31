import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NormalScaffold extends StatelessWidget {
  final Widget child;

  const NormalScaffold({Key key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReaLearn Companion'),
      ),
      body: Stack(
        children: [
          SvgPicture.asset(
            "assets/realearn_logo.svg",
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            fit: BoxFit.cover,
            width: MediaQuery.of(context).size.shortestSide,
            height: MediaQuery.of(context).size.longestSide,
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: child,
          )
        ],
      ),
    );
  }
}