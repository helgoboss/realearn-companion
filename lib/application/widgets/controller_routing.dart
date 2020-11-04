import 'dart:async';

import 'package:flutter/material.dart';
import 'package:realearn_companion/domain/connection.dart';

import 'connection_builder.dart';
import 'normal_scaffold.dart';

class ControllerRoutingWidget extends StatefulWidget {
  final ConnectionDataPalette connectionDataPalette;

  const ControllerRoutingWidget({Key key, @required this.connectionDataPalette})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ControllerRoutingWidgetState();
  }
}

class ControllerRoutingWidgetState extends State<ControllerRoutingWidget> {
  bool appBarIsVisible = true;

  @override
  void initState() {
    super.initState();
    showAppBarForSomeSecs();
  }

  void showAppBar(bool show) {
    setState(() {
      appBarIsVisible = show;
    });
  }

  void showAppBarForSomeSecs() {
    showAppBar(true);
    Timer(Duration(seconds: 3), () {
      showAppBar(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    var sessionId = widget.connectionDataPalette.sessionId;
    var controllerTopic = "/realearn/session/$sessionId/controller";
    var controllerRoutingTopic =
        "/realearn/session/$sessionId/controller-routing";
    return NormalScaffold(
        hideAppBar: !appBarIsVisible,
        child: ConnectionBuilder(
            connectionDataPalette: widget.connectionDataPalette,
            topics: [controllerTopic, controllerRoutingTopic],
            builder: (BuildContext context, Stream<dynamic> messages) =>
                GestureDetector(
                  onTap: () {
                    showAppBarForSomeSecs();
                  },
                  child: StreamBuilder(
                      stream: messages,
                      builder: (context, snapshot) {
                        return Text(snapshot.data.toString());
                      }),
                )));
  }
}
