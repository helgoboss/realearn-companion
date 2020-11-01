import 'package:flutter/material.dart';
import 'package:realearn_companion/domain/connection.dart';

import 'connection_builder.dart';
import 'normal_scaffold.dart';

class ControllerRoutingWidget extends StatelessWidget {
  final ConnectionDataPalette connectionDataPalette;

  const ControllerRoutingWidget({Key key, @required this.connectionDataPalette})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var sessionId = connectionDataPalette.sessionId;
    var controllerTopic = "/realearn/session/$sessionId/controller";
    var controllerRoutingTopic =
        "/realearn/session/$sessionId/controller-routing";
    return NormalScaffold(
        child: ConnectionBuilder(
            connectionDataPalette: connectionDataPalette,
            topics: [controllerTopic, controllerRoutingTopic],
            builder: (BuildContext context, Stream<dynamic> messages) =>
                StreamBuilder(stream: messages, builder: (context, snapshot) {
                  return Text(snapshot.data.toString());
                })));
  }
}
