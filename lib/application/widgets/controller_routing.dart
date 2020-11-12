import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:realearn_companion/domain/preferences.dart';
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
    var controllerModel = this.context.read<ControllerModel>();
    await ControllerRepository(widget.connectionData)
        .save(controllerModel.controller);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Saved controller layout")),
    );
  }

  void setController(Controller controller) {
    var controllerModel = this.context.read<ControllerModel>();
    controllerModel.controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    AppBar controllerRoutingAppBar(ControllerModel controllerModel) {
      var theme = Theme.of(context);
      return AppBar(
          // TODO-high Show controller name here
          title: Text("Controller Routing"),
          actions: [
            if (controllerModel.controller != null)
              IconButton(
                icon: Icon(Icons.save),
                onPressed:
                    controllerModel.controllerHasEdits ? saveController : null,
              ),
            if (controllerModel.controller != null)
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
              ),
            PopupMenuButton(
              itemBuilder: (BuildContext context) {
                return <PopupMenuEntry>[
                  if (!isInEditMode)
                    PopupMenuItem(
                      child: Consumer<AppPreferences>(
                        builder: (context, prefs, child) {
                          return ListTile(
                            leading: Icon(getThemeModeIcon(prefs.themeMode)),
                            onTap: prefs.switchThemeMode,
                            title: Text('Theme mode'),
                          );
                        },
                      ),
                    ),
                  if (!isInEditMode)
                    PopupMenuItem(
                      child: Consumer<AppPreferences>(
                        builder: (context, prefs, child) {
                          return ListTile(
                            leading: Icon(
                                prefs.highContrastEnabled ? Icons.done : null),
                            onTap: prefs.toggleHighContrast,
                            title: Text('High contrast'),
                          );
                        },
                      ),
                    ),
                  if (!isInEditMode)
                    PopupMenuItem(
                      child: Consumer<AppPreferences>(
                        builder: (context, prefs, child) {
                          return ListTile(
                            leading: Icon(prefs.backgroundImageEnabled
                                ? Icons.done
                                : null),
                            onTap: prefs.toggleBackgroundImage,
                            title: Text('Background image'),
                          );
                        },
                      ),
                    ),
                  if (!isInEditMode)
                    PopupMenuItem(
                      child: Consumer<AppPreferences>(
                        builder: (context, prefs, child) {
                          return ListTile(
                            leading: Icon(getControlAppearanceIcon(
                                prefs.controlAppearance)),
                            onTap: prefs.switchControlAppearance,
                            title: Text('Control appearance'),
                          );
                        },
                      ),
                    ),
                  if (isInEditMode)
                    PopupMenuItem(
                      child: Consumer<AppPreferences>(
                        builder: (context, prefs, child) {
                          return ListTile(
                            leading:
                                Icon(prefs.gridEnabled ? Icons.done : null),
                            onTap: prefs.toggleGrid,
                            title: Text('Grid'),
                            trailing: Wrap(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove_circle),
                                  onPressed: () {
                                    context
                                        .read<ControllerModel>()
                                        .decreaseGridSize();
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.add_circle),
                                  onPressed: () {
                                    context
                                        .read<ControllerModel>()
                                        .increaseGridSize();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  if (isInEditMode)
                    PopupMenuItem(
                      child: Consumer<ControllerModel>(
                        builder: (context, prefs, child) {
                          return ListTile(
                            leading: Icon(Icons.vertical_align_bottom),
                            onTap: controllerModel.alignControlPositionsToGrid,
                            title: Text('Align controls to grid'),
                          );
                        },
                      ),
                    ),
                ];
              },
            ),
          ]);
    }

    var sessionId = widget.connectionData.sessionId;
    var controllerTopic = "/realearn/session/$sessionId/controller";
    var controllerRoutingTopic =
        "/realearn/session/$sessionId/controller-routing";
    return Consumer<ControllerModel>(
        builder: (context, controllerModel, child) {
      return NormalScaffold(
        padding: EdgeInsets.zero,
        appBar:
            appBarIsVisible ? controllerRoutingAppBar(controllerModel) : null,
        child: ConnectionBuilder(
          connectionData: widget.connectionData,
          topics: [controllerTopic, controllerRoutingTopic],
          builder: (BuildContext context, Stream<dynamic> messages) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                toggleAppBar();
              },
              child: ControllerRoutingContainer(
                messages: messages,
                isInEditMode: isInEditMode,
                controller: controllerModel.controller,
                onControllerSwitched: setController,
              ),
            );
          },
        ),
      );
    });
  }
}

class ControllerRoutingContainer extends StatefulWidget {
  final Controller controller;
  final Stream<dynamic> messages;
  final bool isInEditMode;
  final Function(Controller controller) onControllerSwitched;

  const ControllerRoutingContainer({
    Key key,
    this.messages,
    this.isInEditMode,
    this.controller,
    this.onControllerSwitched,
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

var controlCanvasPadding = EdgeInsets.all(20);

class ControllerRoutingWidget extends StatelessWidget {
  final ControllerRouting routing;
  final bool isInEditMode;
  final GlobalKey stackKey = GlobalKey();

  ControllerRoutingWidget({
    Key key,
    this.routing,
    this.isInEditMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controllerModel = context.watch<ControllerModel>();
    final controller = controllerModel.controller;
    if (controller == null || routing == null) {
      return Center(child: Text("Loading..."));
    }
    var isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    var controllerSize = controller.calcTotalSize();
    Widget createControlBag({Axis direction}) {
      var remainingMappings = controller.mappings.where((m) {
        return !controller.controls.any((c) => c.mappings.contains(m.id));
      }).toList();
      return ControlBag(
        direction: direction,
        stackKey: stackKey,
        mappings: remainingMappings,
      );
    }

    return Flex(
      direction: isPortrait ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                var widthFactor = constraints.maxWidth / controllerSize.width;
                var heightFactor =
                    constraints.maxHeight / controllerSize.height;
                return Container(
                  width:
                      isPortrait ? null : controllerSize.width * heightFactor,
                  height:
                      isPortrait ? controllerSize.height * widthFactor : null,
                  child: Padding(
                    padding: controlCanvasPadding,
                    child: InteractiveViewer(
                      panEnabled: true,
                      boundaryMargin: EdgeInsets.all(0),
                      minScale: 1.0,
                      maxScale: 4,
                      child: LayoutBuilder(builder:
                          (BuildContext context, BoxConstraints constraints) {
                        var widthScale =
                            constraints.maxWidth / controllerSize.width;
                        var heightScale =
                            constraints.maxHeight / controllerSize.height;
                        var scale = math.min(widthScale, heightScale);
                        var controls = controller.controls.map((data) {
                          if (isInEditMode) {
                            return EditableControl(
                              labels: data.mappings.map((mappingId) {
                                return controller
                                        .findMappingById(mappingId)
                                        ?.name ??
                                    "";
                              }).toList(),
                              data: data,
                              scale: scale,
                              gridSize: controller.gridSize,
                              stackKey: stackKey,
                              controllerModel: controllerModel,
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
                        return Consumer<AppPreferences>(
                          builder: (context, prefs, child) {
                            return GridPaper(
                              divisions: 1,
                              subdivisions: 1,
                              interval: controller.gridSize * scale,
                              color: isInEditMode && prefs.gridEnabled
                                  ? Colors.grey
                                  : Colors.transparent,
                              child: child,
                            );
                          },
                          child: DragTarget<String>(
                            builder: (context, candidateData, rejectedData) {
                              return Stack(
                                key: stackKey,
                                children: controls,
                              );
                            },
                            onWillAccept: (data) => true,
                            onAcceptWithDetails: (details) {
                              var finalPos = getFinalDragPosition(
                                gridSize: controller.gridSize,
                                globalPosition: details.offset,
                                stackKey: stackKey,
                                scale: scale,
                              );
                              var newData = ControlData(
                                id: uuid.v4(),
                                mappings: [details.data],
                                x: finalPos.dx.toInt(),
                                y: finalPos.dy.toInt(),
                              );
                              controllerModel.addControl(newData);
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (isInEditMode)
          createControlBag(
            direction: isPortrait ? Axis.horizontal : Axis.vertical,
          )
      ],
    );
  }
}

class ControlBag extends StatelessWidget {
  final List<Mapping> mappings;
  final GlobalKey stackKey;
  final Axis direction;

  const ControlBag({
    Key key,
    this.mappings,
    this.stackKey,
    this.direction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget createBag({bool isAccepting}) {
      return Container(
        padding: controlCanvasPadding,
        width: direction == Axis.vertical ? 100 : null,
        height: direction == Axis.horizontal ? 100 : null,
        color: isAccepting
            ? Colors.grey.withOpacity(0.3)
            : Colors.grey.withOpacity(0.1),
        child: SingleChildScrollView(
          scrollDirection: direction,
          child: Flex(
            direction: direction,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: mappings.map((m) {
              Widget createPotentialControl({Color fillColor}) {
                return Control(
                  labels: [m.name],
                  width: 50,
                  height: 50,
                  shape: ControlShape.circle,
                  fillColor: fillColor,
                  scale: 1.0,
                );
              }

              var normalPotentialControl = createPotentialControl();
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Draggable<String>(
                  data: m.id,
                  childWhenDragging: createPotentialControl(
                    fillColor: Colors.grey,
                  ),
                  feedback: normalPotentialControl,
                  child: normalPotentialControl,
                ),
              );
            }).toList(),
          ),
        ),
      );
    }

    return DragTarget<ControlData>(
      builder: (context, candidateData, rejectedData) {
        return createBag(isAccepting: candidateData.length > 0);
      },
      onWillAccept: (data) => true,
      onAccept: (data) {
        final controllerModel = context.read<ControllerModel>();
        controllerModel.removeControl(data.id);
      },
    );
  }
}

class EditableControl extends StatefulWidget {
  final List<String> labels;
  final ControlData data;
  final double scale;
  final GlobalKey stackKey;
  final int gridSize;
  final ControllerModel controllerModel;

  const EditableControl({
    Key key,
    this.labels,
    this.data,
    this.scale,
    this.stackKey,
    this.gridSize,
    this.controllerModel,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return EditableControlState();
  }

  Offset get offset => Offset(data.x.toDouble(), data.y.toDouble());
}

class EditableControlState extends State<EditableControl> {
  @override
  Widget build(BuildContext context) {
    var control = Control(
      height: (widget.scale * widget.data.height).toInt(),
      width: (widget.scale * widget.data.width).toInt(),
      labels: widget.labels,
      shape: widget.data.shape,
      scale: widget.scale,
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
          final controllerModel = context.read<ControllerModel>();
          controllerModel.uniteControls(widget.data, data);
        },
      ),
      childWhenDragging: SizedBox.shrink(),
      feedback: control,
      onDragEnd: (details) {
        if (details.wasAccepted) {
          return;
        }
        var finalPos = getFinalDragPosition(
          gridSize: widget.gridSize,
          globalPosition: details.offset,
          stackKey: widget.stackKey,
          scale: widget.scale,
        );
        final controllerModel = context.read<ControllerModel>();
        controllerModel.moveControl(
            widget.data, finalPos.dx.toInt(), finalPos.dy.toInt());
      },
    );
    return Positioned(
      top: widget.offset.dy * widget.scale,
      left: widget.offset.dx * widget.scale,
      child: GestureDetector(
        onTap: () {
          showDialog(
              context: context,
              builder: (BuildContext context) => createControlDialog(
                    context: context,
                    controlLabels: control.labels,
                    controllerModel: widget.controllerModel,
                    control: widget.data,
                  ));
        },
        child: draggable,
      ),
    );
  }
}

AlertDialog createControlDialog({
  BuildContext context,
  List<String> controlLabels,
  ControllerModel controllerModel,
  ControlData control,
}) {
  final theme = Theme.of(context);
  return AlertDialog(
    backgroundColor: theme.dialogBackgroundColor.withOpacity(0.75),
    title: Text(controlLabels[0]),
    content: SingleChildScrollView(
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              Text("Width"),
              Wrap(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove_circle),
                    onPressed: () {
                      controllerModel.decreaseControlWidth(control);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle),
                    onPressed: () {
                      controllerModel.increaseControlWidth(control);
                    },
                  ),
                ],
              ),
            ],
          ),
          TableRow(
            children: [
              Text("Height"),
              Wrap(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove_circle),
                    onPressed: () {
                      controllerModel.decreaseControlHeight(control);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle),
                    onPressed: () {
                      controllerModel.increaseControlHeight(control);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        child: Text("Ok"),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    ],
  );
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
        height: (scale * data.height).toInt(),
        width: (scale * data.width).toInt(),
        labels: labels,
        shape: data.shape,
        scale: scale,
      ),
    );
  }
}

class Control extends StatelessWidget {
  final int width;
  final int height;
  final List<String> labels;
  final ControlShape shape;
  final Color fillColor;
  final double scale;

  const Control({
    Key key,
    this.labels,
    this.width,
    this.height,
    this.shape,
    this.fillColor,
    this.scale,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var prefs = context.watch<AppPreferences>();
    if (shape == ControlShape.circle) {
      return CircularControl(
        labelOnePosition: CircularControlLabelPosition.aboveTop,
        labelTwoPosition: CircularControlLabelPosition.belowBottom,
        diameter: width,
        appearance: prefs.controlAppearance,
        labels: labels,
      );
    } else {
      return RectangularControl(
        labelOnePosition: RectangularControlLabelPosition.aboveTop,
        labelTwoPosition: RectangularControlLabelPosition.belowBottom,
        width: width,
        height: height,
        appearance: prefs.controlAppearance,
        labels: labels,
      );
    }
  }
}

class DerivedControlProps {
  final ThemeData theme;
  final bool textOneIsInside;
  final bool textTwoIsInside;
  final ControlAppearance appearance;
  final Color enforcedFillColor;

  DerivedControlProps({
    @required this.textOneIsInside,
    @required this.textTwoIsInside,
    @required this.appearance,
    @required this.theme,
    this.enforcedFillColor,
  });

  double get insideFontSize => 50;

  double get outsideFontSize => 60;

  Color get mainColor => enforcedFillColor ?? theme.colorScheme.primary;

  TextStyle get baseTextStyle => TextStyle(
        fontWeight: FontWeight.bold,
      );

  TextStyle get textOneStyle => baseTextStyle.copyWith(
        fontSize: textOneIsInside ? insideFontSize : outsideFontSize,
        color: textOneIsInside
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface,
      );

  TextStyle get textTwoStyle => baseTextStyle.copyWith(
        fontSize: textTwoIsInside ? insideFontSize : outsideFontSize,
        color: textTwoIsInside
            ? theme.colorScheme.onBackground
            : theme.colorScheme.secondary,
      );

  bool get strokeOnly => appearance == ControlAppearance.outlined;

  double get divider => 5;

  double get strokeWidth => 5;
}

enum RectangularControlLabelPosition {
  aboveTop,
  onTop,
  belowTop,
  center,
  aboveBottom,
  onBottom,
  belowBottom,
  leftToLeft,
  onLeft,
  rightToLeft,
  leftToRight,
  onRight,
  rightToRight,
}

bool rectangularLabelPositionIsInside(RectangularControlLabelPosition pos) {
  switch (pos) {
    case RectangularControlLabelPosition.belowTop:
    case RectangularControlLabelPosition.center:
    case RectangularControlLabelPosition.aboveBottom:
    case RectangularControlLabelPosition.rightToLeft:
    case RectangularControlLabelPosition.leftToRight:
      return true;
    default:
      return false;
  }
}

enum CircularControlLabelPosition {
  aboveTop,
  belowTop,
  center,
  aboveBottom,
  belowBottom,
  leftToLeft,
  rightToLeft,
  leftToRight,
  rightToRight,
}

bool circularLabelPositionIsInside(CircularControlLabelPosition pos) {
  switch (pos) {
    case CircularControlLabelPosition.belowTop:
    case CircularControlLabelPosition.center:
    case CircularControlLabelPosition.aboveBottom:
    case CircularControlLabelPosition.rightToLeft:
    case CircularControlLabelPosition.leftToRight:
      return true;
    default:
      return false;
  }
}

class RectangularControl extends StatelessWidget {
  final int width;
  final int height;
  final ControlAppearance appearance;
  final List<String> labels;
  final RectangularControlLabelPosition labelOnePosition;
  final RectangularControlLabelPosition labelTwoPosition;

  const RectangularControl({
    Key key,
    @required this.appearance,
    @required this.labels,
    @required this.width,
    @required this.height,
    @required this.labelOnePosition,
    @required this.labelTwoPosition,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final props = DerivedControlProps(
      textOneIsInside: rectangularLabelPositionIsInside(labelOnePosition),
      textTwoIsInside: rectangularLabelPositionIsInside(labelTwoPosition),
      appearance: appearance,
      theme: Theme.of(context),
    );
    Widget createText(String label, TextStyle baseStyle) {
      return Text(
        label,
        softWrap: false,
        style:
            baseStyle.copyWith(fontSize: props.outsideFontSize / props.divider),
      );
    }

    return Column(
      children: [
        createText(labels[0], props.textOneStyle),
        Container(
          width: width.toDouble(),
          height: height.toDouble(),
          decoration: new BoxDecoration(
            color: props.strokeOnly ? null : props.mainColor,
            border: Border.all(
              width: props.strokeWidth / props.divider,
              color: props.mainColor,
            ),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
        if (labels.length > 1) createText(labels[1], props.textTwoStyle)
      ],
    );
  }
}

class CircularControl extends StatelessWidget {
  final int diameter;
  final ControlAppearance appearance;
  final List<String> labels;
  final CircularControlLabelPosition labelOnePosition;
  final CircularControlLabelPosition labelTwoPosition;

  const CircularControl({
    Key key,
    @required this.appearance,
    @required this.labels,
    @required this.diameter,
    @required this.labelOnePosition,
    @required this.labelTwoPosition,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final props = DerivedControlProps(
      textOneIsInside: circularLabelPositionIsInside(labelOnePosition),
      textTwoIsInside: circularLabelPositionIsInside(labelTwoPosition),
      appearance: appearance,
      theme: Theme.of(context),
    );
    var actualWidth = props.strokeOnly
        ? diameter - props.strokeWidth / props.divider
        : diameter;
    double radius = 125;
    double insideSpace = 18;
    double outsideSpace = 13;
    return Container(
      width: actualWidth,
      height: actualWidth,
      child: Stack(
        children: [
          CircularText(
            radius: radius,
            position: props.textOneIsInside
                ? CircularTextPosition.inside
                : CircularTextPosition.outside,
            backgroundPaint: Paint()
              ..color = props.mainColor
              ..style = props.strokeOnly ? PaintingStyle.stroke : PaintingStyle.fill
              ..strokeWidth = props.strokeWidth,
            children: [
              TextItem(
                text: Text(
                  labels[0],
                  style: props.textOneStyle,
                ),
                space: props.textOneIsInside ? insideSpace : outsideSpace,
                startAngle: -90,
                startAngleAlignment: StartAngleAlignment.center,
                direction: CircularTextDirection.clockwise,
              ),
            ],
          ),
          if (labels.length > 1)
            CircularText(
              radius: radius,
              position: props.textTwoIsInside
                  ? CircularTextPosition.inside
                  : CircularTextPosition.outside,
              children: [
                TextItem(
                  text: Text(
                    labels[1],
                    style: props.textTwoStyle,
                  ),
                  space: props.textTwoIsInside ? insideSpace : outsideSpace,
                  startAngle: 90,
                  startAngleAlignment: StartAngleAlignment.center,
                  direction: CircularTextDirection.anticlockwise,
                ),
              ],
            )
        ],
      ),
    );
  }
}

Offset getFinalDragPosition({
  int gridSize,
  GlobalKey stackKey,
  Offset globalPosition,
  double scale,
}) {
  final RenderBox box = stackKey.currentContext.findRenderObject();
  var localPosition = box.globalToLocal(globalPosition);
  return Offset(
    localPosition.dx / scale,
    localPosition.dy / scale,
  );
}

IconData getThemeModeIcon(ThemeMode value) {
  switch (value) {
    case ThemeMode.system:
      return Icons.brightness_auto;
    case ThemeMode.light:
      return Icons.brightness_7;
    case ThemeMode.dark:
      return Icons.brightness_1;
  }
}

IconData getControlAppearanceIcon(ControlAppearance value) {
  switch (value) {
    case ControlAppearance.filled:
      return Icons.fiber_manual_record;
    case ControlAppearance.outlined:
      return Icons.fiber_manual_record_outlined;
  }
}
