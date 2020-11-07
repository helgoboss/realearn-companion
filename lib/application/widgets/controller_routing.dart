import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'package:uuid/uuid.dart';

import 'package:flutter/material.dart';
import 'package:flutter_circular_text/circular_text.dart';
import 'package:realearn_companion/application/repositories/controller.dart';
import 'package:realearn_companion/domain/connection.dart';
import 'package:realearn_companion/domain/model.dart';

import 'connection_builder.dart';
import 'normal_scaffold.dart';

var uuid = Uuid();

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
      padding: EdgeInsets.all(20),
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
      boundaryMargin: EdgeInsets.all(0),
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
      var remainingMappings = [...controller.mappings];
      var controls = controller.controls.map((data) {
        for (var mappingId in data.mappings) {
          remainingMappings.removeWhere((m) => m.id == mappingId);
        }
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
        children: [
          ...controls,
          if (isInEditMode)
            Positioned(
              top: 0,
              left: 0,
              child: ControlBag(
                stackKey: stackKey,
                mappings: remainingMappings,
                onControlDataUpdate: onControlDataUpdate,
                scale: scale,
              ),
            ),
        ],
      );
    });
  }
}

class ControlBag extends StatelessWidget {
  final Function(ControlData) onControlDataUpdate;
  final List<Mapping> mappings;
  final GlobalKey stackKey;
  final double scale;

  const ControlBag({
    Key key,
    this.onControlDataUpdate,
    this.mappings,
    this.stackKey,
    this.scale,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var bag = Stack(children: [
      Icon(
        Icons.shopping_bag,
        color: theme.colorScheme.onSurface.withOpacity(0.2),
        size: 100,
      ),
      ...mappings.map((m) {
        var potentialControl = Control(
          labels: [m.name],
          width: 50,
          height: 50,
          shape: ControlShape.circle,
        );
        return Draggable(
          childWhenDragging: SizedBox.shrink(),
          feedback: potentialControl,
          child: potentialControl,
          onDragEnd: (details) {
            var finalPos = getFinalDragPosition(
              globalPosition: details.offset,
              stackKey: stackKey,
              scale: scale,
            );
            var newData = ControlData(
              id: uuid.v4(),
              mappings: [m.id],
              x: finalPos.dx,
              y: finalPos.dy,
            );
            onControlDataUpdate(newData);
          },
        );
      })
    ]);
    return DragTarget<ControlData>(
      builder: (context, candidateData, rejectedData) {
        if (candidateData.length > 0) {
          return Transform.scale(
            scale: 2,
            child: bag,
          );
        }
        return bag;
      },
      onWillAccept: (data) => true,
      onAccept: (data) {
        var orphanControl = data.copyWith(mappings: []);
        onControlDataUpdate(orphanControl);
      },
    );
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
        var finalPos = getFinalDragPosition(
          globalPosition: details.offset,
          stackKey: widget.stackKey,
          scale: widget.scale,
        );
        var newData = widget.data.copyWith(x: finalPos.dx, y: finalPos.dy);
        widget.onControlDataUpdate(newData);
      },
    );
    return Positioned(
      top: widget.offset.dy * widget.scale,
      left: widget.offset.dx * widget.scale,
      child: draggable,
    );
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
    var textOneInside = false;
    var textTwoInside = false;
    double insideFontSize = 50;
    double outsideFontSize = 60;
    var baseTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
    );
    double radius = 125;
    double insideSpace = 18;
    double outsideSpace = 13;
    var textOneStyle = baseTextStyle.copyWith(
      fontSize: textOneInside ? insideFontSize : outsideFontSize,
      color: textOneInside
          ? theme.colorScheme.onPrimary
          : theme.colorScheme.onSurface,
    );
    var textTwoStyle = baseTextStyle.copyWith(
      fontSize: textTwoInside ? insideFontSize : outsideFontSize,
      color: textTwoInside
          ? theme.colorScheme.onBackground
          : theme.colorScheme.secondary,
    );
    if (shape == ControlShape.circle) {
      return Container(
        width: width,
        height: height,
        child: Stack(
          children: [
            CircularText(
              radius: radius,
              position: textOneInside
                  ? CircularTextPosition.inside
                  : CircularTextPosition.outside,
              backgroundPaint: Paint()..color = backgroundColor,
              children: [
                TextItem(
                  text: Text(
                    labels[0],
                    style: textOneStyle,
                  ),
                  space: textOneInside ? insideSpace : outsideSpace,
                  startAngle: -90,
                  startAngleAlignment: StartAngleAlignment.center,
                  direction: CircularTextDirection.clockwise,
                ),
              ],
            ),
            if (labels.length > 1)
              CircularText(
                radius: radius,
                position: textTwoInside
                    ? CircularTextPosition.inside
                    : CircularTextPosition.outside,
                children: [
                  TextItem(
                    text: Text(
                      labels[1],
                      style: textTwoStyle,
                    ),
                    space: textTwoInside ? insideSpace : outsideSpace,
                    startAngle: 90,
                    startAngleAlignment: StartAngleAlignment.center,
                    direction: CircularTextDirection.anticlockwise,
                  ),
                ],
              )
          ],
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

Offset getFinalDragPosition({
  GlobalKey stackKey,
  Offset globalPosition,
  double scale,
}) {
  final RenderBox box = stackKey.currentContext.findRenderObject();
  var localPosition = box.globalToLocal(globalPosition);
  var newOffset = Offset(
    localPosition.dx / scale,
    localPosition.dy / scale,
  );
  return alignOffsetToGrid(newOffset, 10, 10);
}
