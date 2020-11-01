import 'package:flutter/material.dart';

import 'normal_scaffold.dart';

class EnterConnectionDataWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NormalScaffold(
      child:
      Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        Container(
          child: Text(
            "Check this out!",
            style: Theme.of(context).textTheme.headline5,
            textAlign: TextAlign.center,
          ),
        ),
      ]),
    );
  }
}