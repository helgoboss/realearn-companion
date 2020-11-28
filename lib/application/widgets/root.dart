import 'dart:developer';

import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:realearn_companion/application/routes.dart';
import 'package:realearn_companion/domain/preferences.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import 'normal_scaffold.dart';
import 'space.dart';

class RootWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final prefs = context.watch<AppPreferences>();
    final lastConnection = prefs.lastConnection;
    return NormalScaffold(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            "How do you want to connect to ReaLearn?",
            style: Theme.of(context).textTheme.headline5,
            textAlign: TextAlign.center,
          ),
          TextButton.icon(
            icon: const Icon(Icons.restore),
            label: Text(
              "Last session",
              textScaleFactor: 1.6,
            ),
            onPressed: lastConnection == null
                ? null
                : () {
                    var args = ConnectionArgs.fromPalette(lastConnection);
                    Navigator.pushNamed(
                        context, getControllerRoutingRoute(args));
                  },
          ),
          Flex(
            direction: isPortrait ? Axis.vertical : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FutureBuilder(
                  future: App.instance.config.deviceHasCamera(),
                  builder:
                      (BuildContext context, AsyncSnapshot<bool> snapshot) {
                    var hasCamera = snapshot.data == true;
                    return ProminentButton(
                        icon: const Icon(Icons.qr_code_scanner),
                        text: 'Scan QR code',
                        onPressed: hasCamera
                            ? () {
                                Navigator.pushNamed(
                                    context, scanConnectionDataRoute);
                              }
                            : null);
                  }),
              Space(),
              Text(
                "or",
                style: Theme.of(context).textTheme.subtitle1,
              ),
              Space(),
              ProminentButton(
                  icon: const Icon(Icons.keyboard),
                  text: 'Enter connection data',
                  onPressed: () {
                    Navigator.pushNamed(context, enterConnectionDataRoute);
                  }),
            ],
          )
        ],
      ),
    );
  }
}

class ProminentButton extends StatelessWidget {
  final Widget icon;
  final String text;
  final VoidCallback onPressed;

  const ProminentButton({Key key, this.icon, this.text, this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 250),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            )),
        icon: icon,
        label: Text(text),
        onPressed: onPressed,
      ),
    );
  }
}
