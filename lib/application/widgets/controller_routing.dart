import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_circular_text/circular_text.dart';
import 'package:realearn_companion/application/repositories/controller.dart';
import 'package:realearn_companion/domain/connection.dart';
import 'package:realearn_companion/domain/model.dart';

import 'connection_builder.dart';
import 'normal_scaffold.dart';

class ControllerRoutingPage extends StatefulWidget {
  final ConnectionData connectionData;

  const ControllerRoutingPage({Key key, @required this.connectionData})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ControllerRoutingPageState();
  }
}

class ControllerRoutingPageState extends State<ControllerRoutingPage> {
  bool appBarIsVisible = true;
  bool isInEditMode = false;
  bool madeEdit = false;
  Controller controller = null;

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

  void saveController() async {
    await ControllerRepository(widget.connectionData).save(controller);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Saved controller layout")),
    );
    setState(() {
      madeEdit = false;
    });
  }

  void setController(Controller controller) {
    setState(() {
      this.controller = controller;
    });
  }

  @override
  Widget build(BuildContext context) {
    AppBar controllerRoutingAppBar() {
      var theme = Theme.of(context);
      return AppBar(
        title: Text("Controller Routing"),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: madeEdit ? saveController : null,
          ),
          IconButton(
            icon: Icon(Icons.edit),
            color: isInEditMode ? theme.accentColor : null,
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

    var sessionId = widget.connectionData.sessionId;
    var controllerTopic = "/realearn/session/$sessionId/controller";
    var controllerRoutingTopic =
        "/realearn/session/$sessionId/controller-routing";
    return NormalScaffold(
      padding: EdgeInsets.all(10),
      appBar: appBarIsVisible ? controllerRoutingAppBar() : null,
      child: ConnectionBuilder(
        connectionData: widget.connectionData,
        topics: [controllerTopic, controllerRoutingTopic],
        builder: (BuildContext context, Stream<dynamic> messages) =>
            GestureDetector(
          onTap: () {
            toggleAppBar();
          },
          child: ControllerRoutingContainer(
            messages: messages,
            isInEditMode: isInEditMode,
            onControlDataUpdated: (data) {
              setState(() {
                controller.updateControlData(data);
                madeEdit = true;
              });
            },
            controller: controller,
            onControllerSwitched: setController,
          ),
        ),
      ),
    );
  }
}

class ControllerRoutingContainer extends StatefulWidget {
  final Controller controller;
  final Stream<dynamic> messages;
  final bool isInEditMode;
  final Function(Controller controller) onControllerSwitched;
  final Function(ControlData data) onControlDataUpdated;

  const ControllerRoutingContainer({
    Key key,
    this.messages,
    this.isInEditMode,
    this.controller,
    this.onControllerSwitched,
    this.onControlDataUpdated,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ControllerRoutingContainerState();
  }
}

class ControllerRoutingContainerState
    extends State<ControllerRoutingContainer> {
  StreamSubscription messagesSubscription;
  ControllerRouting routing;

  @override
  Widget build(BuildContext context) {
    return ControllerRoutingWidget(
      controller: widget.controller,
      routing: routing,
      isInEditMode: widget.isInEditMode,
      onControlDataUpdate: (data) {
        widget.onControlDataUpdated(data);
      },
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
          widget
              .onControllerSwitched(Controller.fromJson(realearnEvent.payload));
        } else if (realearnEvent.path.endsWith("/controller-routing")) {
          setRouting(ControllerRouting.fromJson(realearnEvent.payload));
        }
      }
    });
  }

  @override
  void dispose() {
    messagesSubscription?.cancel();
    super.dispose();
  }

  void setRouting(ControllerRouting routing) {
    setState(() {
      this.routing = routing;
    });
  }
}

class ControllerRoutingWidget extends StatelessWidget {
  final Controller controller;
  final ControllerRouting routing;
  final bool isInEditMode;
  final Function(ControlData) onControlDataUpdate;

  const ControllerRoutingWidget({
    Key key,
    this.controller,
    this.routing,
    this.isInEditMode,
    this.onControlDataUpdate,
  }) : super(key: key);

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
        onControlDataUpdate: onControlDataUpdate,
      ),
    );
  }
}

class ControllerRoutingCanvas extends StatelessWidget {
  final Controller controller;
  final ControllerRouting routing;
  final bool isInEditMode;
  final Function(ControlData) onControlDataUpdate;
  final GlobalKey stackKey = GlobalKey();

  ControllerRoutingCanvas({
    Key key,
    this.controller,
    this.routing,
    this.isInEditMode,
    this.onControlDataUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var controllerSize = controller.calcTotalSize();
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      var widthScale = constraints.maxWidth / controllerSize.width;
      var heightScale = constraints.maxHeight / controllerSize.height;
      var scale = math.min(widthScale, heightScale);
      var controls = controller.controls.map((data) {
        if (isInEditMode) {
          return EditableControl(
            labels: data.mappings.map((mappingId) {
              return controller.findMappingById(mappingId)?.name ?? "";
            }).toList(),
            data: data,
            scale: scale,
            stackKey: stackKey,
            onControlDataUpdate: onControlDataUpdate,
          );
        } else {
          return FixedControl(
            labels: data.mappings.map((mappingId) {
              return routing.routes[mappingId]?.label ?? "";
            }).toList(),
            data: data,
            scale: scale,
          );
        }
      }).toList();
      return Stack(
        key: stackKey,
        children: controls,
      );
    });
  }
}

class EditableControl extends StatefulWidget {
  final List<String> labels;
  final ControlData data;
  final double scale;
  final Function(ControlData) onControlDataUpdate;
  final GlobalKey stackKey;

  const EditableControl({
    Key key,
    this.labels,
    this.data,
    this.scale,
    this.onControlDataUpdate,
    this.stackKey,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return EditableControlState();
  }

  Offset get offset => Offset(data.x, data.y);
}

class EditableControlState extends State<EditableControl> {
  @override
  Widget build(BuildContext context) {
    var control = Control(
      height: widget.scale * widget.data.height,
      width: widget.scale * widget.data.width,
      labels: widget.labels,
      shape: widget.data.shape,
    );
    var draggable = Draggable<ControlData>(
      data: widget.data,
      child: DragTarget<ControlData>(
        builder: (context, candidateData, rejectedData) {
          if (candidateData.length > 0) {
            return Transform.scale(
              scale: 2,
              child: control,
            );
          }
          return control;
        },
        onWillAccept: (data) {
          return data.mappings.length == 1 && widget.data.mappings.length == 1;
        },
        onAccept: (data) {
          var fatControl = widget.data.copyWith(
            mappings: [...widget.data.mappings, ...data.mappings],
          );
          var orphanControl = data.copyWith(
            mappings: [],
          );
          widget.onControlDataUpdate(fatControl);
          widget.onControlDataUpdate(orphanControl);
        },
      ),
      childWhenDragging: SizedBox.shrink(),
      feedback: control,
      onDragEnd: (details) {
        if (details.wasAccepted) {
          return;
        }
        final RenderBox box = widget.stackKey.currentContext.findRenderObject();
        var localDetailsOffset = box.globalToLocal(details.offset);
        var newOffset = Offset(
          localDetailsOffset.dx / widget.scale,
          localDetailsOffset.dy / widget.scale,
        );
        _onDragEnd(newOffset);
      },
    );
    return Positioned(
      top: widget.offset.dy * widget.scale,
      left: widget.offset.dx * widget.scale,
      child: draggable,
    );
  }

  void _onDragEnd(Offset offset) {
    var alignedToGrid = alignOffsetToGrid(offset, 10, 10);
    var newData =
        widget.data.copyWith(x: alignedToGrid.dx, y: alignedToGrid.dy);
    widget.onControlDataUpdate(newData);
  }
}

class FixedControl extends StatelessWidget {
  final List<String> labels;
  final ControlData data;
  final double scale;

  const FixedControl({Key key, this.labels, this.data, this.scale})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
        top: scale * data.y,
        left: scale * data.x,
        child: Control(
          height: scale * data.height,
          width: scale * data.width,
          labels: labels,
          shape: data.shape,
        ));
  }
}

class Control extends StatelessWidget {
  final double width;
  final double height;
  final List<String> labels;
  final ControlShape shape;

  const Control({Key key, this.labels, this.width, this.height, this.shape})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var backgroundColor = theme.colorScheme.primary;
    var inside = false;
    var baseTextStyle = TextStyle(
      fontSize: 40,
      color:
          inside ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
      fontWeight: FontWeight.bold,
    );
    double space = inside ? 15 : 10;
    var textOneStyle = baseTextStyle;
    var textTwoStyle = baseTextStyle;
    if (shape == ControlShape.circle) {
      return Container(
        width: width,
        height: height,
        child: CircularText(
          children: [
            TextItem(
              text: Text(
                labels[0],
                style: textOneStyle,
              ),
              space: space,
              startAngle: -90,
              startAngleAlignment: StartAngleAlignment.center,
              direction: CircularTextDirection.clockwise,
            ),
            if (labels.length > 1)
              TextItem(
                text: Text(
                  labels[1],
                  style: textTwoStyle,
                ),
                space: space,
                startAngle: 90,
                startAngleAlignment: StartAngleAlignment.center,
                direction: CircularTextDirection.anticlockwise,
              ),
          ],
          radius: 125,
          position: inside
              ? CircularTextPosition.inside
              : CircularTextPosition.outside,
          backgroundPaint: Paint()..color = backgroundColor,
        ),
      );
    } else {
      return Container(
        width: width,
        height: height,
        child: FittedBox(
          fit: BoxFit.none,
          clipBehavior: Clip.none,
          child: Column(children: [
            Text(
              labels[0],
              style: theme.textTheme.button,
            ),
            Container(
              width: width,
              height: height,
              decoration: new BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.rectangle,
              ),
            ),
            if (labels.length > 1)
              Text(
                labels[1],
                style: theme.textTheme.button,
              ),
          ]),
        ),
      );
    }
  }
}

Offset alignOffsetToGrid(Offset offset, double xGridSize, double yGridSize) {
  return Offset(
    roundNumberToGridSize(offset.dx, xGridSize),
    roundNumberToGridSize(offset.dy, yGridSize),
  );
}

double roundNumberToGridSize(double number, double gridSize) {
  return (number / gridSize).roundToDouble() * gridSize;
}
