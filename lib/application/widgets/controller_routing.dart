import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:realearn_companion/domain/connection.dart';
import 'package:realearn_companion/domain/model.dart';

import 'connection_builder.dart';
import 'normal_scaffold.dart';

class ControllerRoutingPage extends StatefulWidget {
  final ConnectionDataPalette connectionDataPalette;

  const ControllerRoutingPage({Key key, @required this.connectionDataPalette})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ControllerRoutingPageState();
  }
}

class ControllerRoutingPageState extends State<ControllerRoutingPage> {
  bool appBarIsVisible = true;
  Timer timer = null;

  @override
  void initState() {
    super.initState();
    showAppBarForSomeSecs();
  }

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
  }

  void showAppBar(bool show) {
    setState(() {
      appBarIsVisible = show;
    });
  }

  void showAppBarForSomeSecs() {
    showAppBar(true);
    timer?.cancel();
    timer = Timer(Duration(seconds: 3), () {
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
          child: ControllerRoutingContainer(messages: messages),
        ),
      ),
    );
  }
}

class ControllerRoutingContainer extends StatefulWidget {
  final Stream<dynamic> messages;

  const ControllerRoutingContainer({Key key, this.messages}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ControllerRoutingContainerState();
  }
}

class ControllerRoutingContainerState
    extends State<ControllerRoutingContainer> {
  StreamSubscription messagesSubscription;
  Controller controller = null;
  ControllerRouting routing = null;

  @override
  Widget build(BuildContext context) {
    return ControllerRoutingWidget(controller: controller, routing: routing);
  }

  @override
  void initState() {
    super.initState();
    // We have to use setState() and can't just use a StreamBuilder because a
    // WebSocket message doesn't contain the complete picture. It's either a
    // controller update or a controller routing update.
    // We need to "combine latest" (in RX language) to get the full picture.
    // If we would call setState() in the StreamBuilder builder function, we
    // would cause a rebuild of the containing widget - including the
    // StreamBuilder itself, which would resubscribe to stream and process its
    // last message - causing an infinite loop (it makes sense).
    // https://github.com/flutter/flutter/issues/22713#issuecomment-427256380
    messagesSubscription = widget.messages.listen((data) {
      var jsonObject = jsonDecode(data);
      var realearnEvent = RealearnEvent.fromJson(jsonObject);
      if (realearnEvent.type == "updated") {
        if (realearnEvent.path.endsWith("/controller")) {
          updateController(Controller.fromJson(realearnEvent.payload));
        } else if (realearnEvent.path.endsWith("/controller-routing")) {
          updateRouting(ControllerRouting.fromJson(realearnEvent.payload));
        }
      }
    });
  }

  @override
  void dispose() {
    messagesSubscription?.cancel();
    super.dispose();
  }

  void updateController(Controller controller) {
    setState(() {
      this.controller = controller;
    });
  }

  void updateRouting(ControllerRouting routing) {
    setState(() {
      this.routing = routing;
    });
  }
}

class ControllerRoutingWidget extends StatelessWidget {
  final Controller controller;
  final ControllerRouting routing;

  const ControllerRoutingWidget({Key key, this.controller, this.routing})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (controller == null || routing == null) {
      return Center(child: Text("Loading..."));
    }
    return InteractiveViewer(
      panEnabled: false,
      // Set it to false to prevent panning.
      boundaryMargin: EdgeInsets.zero,
      minScale: 0.5,
      maxScale: 4,
      child: Container(
        child: ControllerRoutingCanvas(
          controller: controller,
          routing: routing,
        ),
      ),
    );
  }
}

class ControllerRoutingCanvas extends StatelessWidget {
  final Controller controller;
  final ControllerRouting routing;

  const ControllerRoutingCanvas({Key key, this.controller, this.routing})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var draggables = controller.mappings.map((m) {
      var route = routing.routes[m.id];
      var data =
          controller.findControlData(m.id) ?? ControlData(x: 0.0, y: 0.0);
      return Control(
        label: route?.label ?? "",
        data: data,
      );
    }).toList();
    return Stack(
      children: draggables,
    );
  }
}

class Control extends StatelessWidget {
  final String label;
  final ControlData data;

  const Control({Key key, this.label, this.data}) : super(key: key);

  Offset getOffset() => Offset(data.x, data.y);

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var container = Container(
      height: 50.0,
      width: 50.0,
      decoration: new BoxDecoration(
        color: theme.colorScheme.primary,
        shape: mapControlShapeToBoxShape(data.shape ?? ControlShape.circle),
      ),
      child: FittedBox(
        fit: BoxFit.none,
        clipBehavior: Clip.none,
        child: Text(
          label,
          style: theme.textTheme.button.copyWith(color: theme.colorScheme.onPrimary),
        ),
      ),
    );
    var offset = getOffset();
    return Positioned(top: offset.dy, left: offset.dx, child: container);
  }
}

BoxShape mapControlShapeToBoxShape(ControlShape controlShape) {
  switch (controlShape) {
    case ControlShape.circle:
      return BoxShape.circle;
    case ControlShape.rectangle:
      return BoxShape.rectangle;
  }
}
