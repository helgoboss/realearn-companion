import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:realearn_companion/application/routes.dart';

import '../app.dart';

class AppWidget extends StatefulWidget {
  @override
  State createState() {
    return AppWidgetState();
  }
}

class AppWidgetState extends State<AppWidget> {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);
    return MaterialApp(
      title: 'ReaLearn Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.deepPurple,
        // visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        // visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      themeMode: ThemeMode.light,
      onGenerateRoute: App.instance.router.generator,
    );
  }
}

class RootWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReaLearn Companion'),
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(30),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
              children: [
                if (isPortrait) SvgPicture.asset(
                  "assets/realearn_logo.svg",
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
                Container(
                  padding: EdgeInsets.all(30),
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
                        'Scan QR code'),
                    space(),
                    Text(
                      "or",
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                    space(),
                    mainButton(context, const Icon(Icons.keyboard),
                        'Enter connection data'),
                  ],
                )
              ]),
        ),
      ),
    );
  }
}

Widget space() {
  return SizedBox(width: 10, height: 10);
}

Widget mainButton(BuildContext context, Widget icon, String text) {
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
      onPressed: () {},
    ),
  );
}
