import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:realearn_companion/application/routes.dart';

import '../app.dart';
import 'normal_scaffold.dart';

class RootWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    return NormalScaffold(
      child:
          Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        Container(
          child: Text(
            "How do you want to connect to ReaLearn?",
            style: Theme.of(context).textTheme.headline5,
            textAlign: TextAlign.center,
          ),
        ),
        Flex(
          direction: isPortrait ? Axis.vertical : Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            mainButton(context, const Icon(Icons.qr_code_scanner),
                'Scan QR code', () {}),
            space(),
            Text(
              "or",
              style: Theme.of(context).textTheme.subtitle1,
            ),
            space(),
            mainButton(
                context, const Icon(Icons.keyboard), 'Enter connection data',
                () {
              App.instance.router.navigateTo(context, enterConnectionDataRoute,
                  transition: TransitionType.native);
            }),
          ],
        )
      ]),
    );
  }
}

Widget space() {
  return SizedBox(width: 10, height: 10);
}

Widget mainButton(
    BuildContext context, Widget icon, String text, VoidCallback onPressed) {
  return Container(
    constraints: BoxConstraints(minWidth: 250),
    child: RaisedButton.icon(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 0,
      textColor: Theme.of(context).typography.white.button.color,
      color: Theme.of(context).primaryColor,
      icon: icon,
      label: Text(text),
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      onPressed: onPressed,
    ),
  );
}
