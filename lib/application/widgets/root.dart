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
      hideAppBar: true,
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
            FutureBuilder<bool>(
                future: App.instance.config.deviceHasCamera(),
                builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                  return ProminentButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      text: 'Scan QR code',
                      onPressed: snapshot.data == true
                          ? () {
                              App.instance.router.navigateTo(
                                  context, scanConnectionDataRoute,
                                  transition: TransitionType.native);
                            }
                          : null);
                }),
            space(),
            Text(
              "or",
              style: Theme.of(context).textTheme.subtitle1,
            ),
            space(),
            ProminentButton(
                icon: const Icon(Icons.keyboard),
                text: 'Enter connection data',
                onPressed: () {
                  App.instance.router.navigateTo(
                      context, enterConnectionDataRoute,
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

class ProminentButton extends StatelessWidget {
  final Widget icon;
  final String text;
  final VoidCallback onPressed;

  const ProminentButton({Key key, this.icon, this.text, this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    return Container(
      constraints: BoxConstraints(minWidth: 250),
      child: RaisedButton.icon(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 0,
        disabledElevation: 0,
        textColor: themeData.typography.white.button.color,
        disabledTextColor: themeData.typography.white.button.color,
        color: themeData.primaryColor,
        disabledColor: themeData.disabledColor,
        icon: icon,
        label: Text(text),
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        onPressed: onPressed,
      ),
    );
  }
}
