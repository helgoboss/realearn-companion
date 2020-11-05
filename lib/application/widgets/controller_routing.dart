import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math';

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
  bool isInEditMode = false;

  void toggleAppBar() {
    setState(() {
      appBarIsVisible = !appBarIsVisible;
    });
  }

  void enterEditMode() {
    setState(() {
      isInEditMode = true;
    });
  }

  void leaveEditMode() {
    setState(() {
      isInEditMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    AppBar controllerRoutingAppBar() {
      var themeData = Theme.of(context);
      return AppBar(
        title: Text("Controller Routing"),
        actions: [
          if (isInEditMode)
            IconButton(
              icon: Icon(
                Icons.save,
              ),
              color: themeData.colorScheme.onPrimary,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Saved controller layout")));
              },
            ),
          IconButton(
            icon: Icon(
              isInEditMode ? Icons.clear : Icons.edit,
            ),
            onPressed: () {
              if (isInEditMode) {
                leaveEditMode();
              } else {
                enterEditMode();
              }
            },
          )
        ],
      );
    }

    var sessionId = widget.connectionDataPalette.sessionId;
    var controllerTopic = "/realearn/session/$sessionId/controller";
    var controllerRoutingTopic =
        "/realearn/session/$sessionId/controller-routing";
    return NormalScaffold(
      padding: EdgeInsets.all(10),
      appBar: appBarIsVisible ? controllerRoutingAppBar() : null,
      child: ConnectionBuilder(
        connectionDataPalette: widget.connectionDataPalette,
        topics: [controllerTopic, controllerRoutingTopic],
        builder: (BuildContext context, Stream<dynamic> messages) =>
            GestureDetector(
          onTap: () {
            toggleAppBar();
          },
          child: ControllerRoutingContainer(
              messages: messages, isInEditMode: isInEditMode),
        ),
      ),
    );
  }
}

class ControllerRoutingContainer extends StatefulWidget {
  final Stream<dynamic> messages;
  final bool isInEditMode;

  const ControllerRoutingContainer({Key key, this.messages, this.isInEditMode})
      : super(key: key);

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
    return ControllerRoutingWidget(
      controller: controller,
      routing: routing,
      isInEditMode: widget.isInEditMode,
    );
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
  final bool isInEditMode;

  const ControllerRoutingWidget(
      {Key key, this.controller, this.routing, this.isInEditMode})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (controller == null || routing == null) {
      return Center(child: Text("Loading..."));
    }
    return InteractiveViewer(
      panEnabled: true,
      boundaryMargin: EdgeInsets.zero,
      minScale: 0.5,
      maxScale: 4,
      child: ControllerRoutingCanvas(
        controller: controller,
        routing: routing,
        isInEditMode: isInEditMode,
      ),
    );
  }
}

class ControllerRoutingCanvas extends StatelessWidget {
  final Controller controller;
  final ControllerRouting routing;
  final bool isInEditMode;

  const ControllerRoutingCanvas(
      {Key key, this.controller, this.routing, this.isInEditMode})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var controllerSize = controller.calcTotalSize();
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      var widthScale = constraints.maxWidth / controllerSize.width;
      var heightScale = constraints.maxHeight / controllerSize.height;
      var scale = min(widthScale, heightScale);
      var controls = controller.mappings.map((m) {
        var route = routing.routes[m.id];
        var data =
            controller.findControlData(m.id) ?? ControlData(x: 0.0, y: 0.0);
        if (isInEditMode) {
          return EditableControl(
            label: m.name,
            data: data,
            scale: scale,
          );
        } else {
          return FixedControl(
            label: route?.label ?? "",
            data: data,
            scale: scale,
          );
        }
      }).toList();
      return Stack(
        children: controls,
      );
    });
  }
}

class EditableControl extends StatefulWidget {
  final String label;
  final ControlData data;
  final double scale;

  const EditableControl({Key key, this.label, this.data, this.scale})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return EditableControlState();
  }

  Offset get offset => Offset(data.x, data.y);
}

class EditableControlState extends State<EditableControl> {
  Offset dragOffset = null;

  void onDragStart() {
    setState(() {
      dragOffset = widget.offset;
    });
  }

  void onDrag(Offset newOffset) {
    setState(() {
      dragOffset = newOffset;
    });
  }

  void onDragEnd() {
    // var alignedToGrid = alignOffsetToGrid(dragOffset, 10, 10);
    setState(() {
      dragOffset = null;
    });
    // notifyControlDataChanged(x: alignedToGrid.dx, y: alignedToGrid.dy);
  }

  @override
  Widget build(BuildContext context) {
    var draggable = GestureDetector(
        onPanStart: (_) {
          onDragStart();
        },
        onPanUpdate: (details) {
          var newOffset = Offset(
            dragOffset.dx + details.delta.dx / widget.scale,
            dragOffset.dy + details.delta.dy / widget.scale,
          );
          onDrag(newOffset);
        },
        onPanEnd: (_) {
          onDragEnd();
        },
        onTap: () {
          // TODO-medium Introduce shape and x and y getters
          // changeShape(getNextShape(widget.data.shape ?? ControlShape.circle));
        },
        child: Control(
          height: widget.scale * widget.data.height,
          width: widget.scale * widget.data.width,
          label: widget.label,
          shape: widget.data.shape,
        ));
    var effectiveOffset = (dragOffset ?? widget.offset);
    var scaledEffectiveOffset =
        effectiveOffset.scale(widget.scale, widget.scale);
    return Positioned(
      top: scaledEffectiveOffset.dy,
      left: scaledEffectiveOffset.dx,
      child: draggable,
    );
  }
}

class FixedControl extends StatelessWidget {
  final String label;
  final ControlData data;
  final double scale;

  const FixedControl({Key key, this.label, this.data, this.scale})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
        top: scale * data.y,
        left: scale * data.x,
        child: Control(
          height: scale * data.height,
          width: scale * data.width,
          label: label,
          shape: data.shape,
        ));
  }
}

class Control extends StatelessWidget {
  final double width;
  final double height;
  final String label;
  final ControlShape shape;

  const Control({Key key, this.label, this.width, this.height, this.shape})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      decoration: new BoxDecoration(
        color: theme.colorScheme.primary,
        shape: mapControlShapeToBoxShape(shape ?? ControlShape.circle),
      ),
      child: FittedBox(
        fit: BoxFit.none,
        clipBehavior: Clip.none,
        child: Text(
          label,
          style: theme.textTheme.button
              .copyWith(color: theme.colorScheme.onPrimary),
        ),
      ),
    );
  }
}

BoxShape mapControlShapeToBoxShape(ControlShape controlShape) {
  switch (controlShape) {
    case ControlShape.circle:
      return BoxShape.circle;
    case ControlShape.rectangle:
      return BoxShape.rectangle;
    default:
      throw UnsupportedError("Unknown value $controlShape");
  }
}
