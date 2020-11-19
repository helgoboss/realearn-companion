import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter_arc_text/flutter_arc_text.dart';
import 'package:provider/provider.dart';
import 'package:realearn_companion/domain/preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter/material.dart';
import 'package:realearn_companion/application/repositories/controller.dart';
import 'package:realearn_companion/domain/connection.dart';
import 'package:realearn_companion/domain/model.dart';
import 'package:vibration/vibration.dart';

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
    if (appBarIsVisible) {
      SystemChrome.setEnabledSystemUIOverlays([]);
    } else {
      SystemChrome.setEnabledSystemUIOverlays(
          [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    }
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
          title: Text(controllerModel.controller?.name ?? 'No controller'),
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
            child: Padding(
              padding: controlCanvasPadding,
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: EdgeInsets.all(0),
                minScale: 1.0,
                maxScale: 8,
                child: LayoutBuilder(builder:
                    (BuildContext context, BoxConstraints constraints) {
                  var widthScale = constraints.maxWidth / controllerSize.width;
                  var heightScale =
                      constraints.maxHeight / controllerSize.height;
                  var scale = math.min(widthScale, heightScale);
                  var prefs = context.watch<AppPreferences>();
                  var controls = controller.controls.map((data) {
                    if (isInEditMode) {
                      return EditableControl(
                        labels: data.mappings.map((mappingId) {
                          return controller.findMappingById(mappingId)?.name ??
                              "";
                        }).toList(),
                        data: data,
                        scale: scale,
                        gridSize: controller.gridSize,
                        stackKey: stackKey,
                        controllerModel: controllerModel,
                        appearance: prefs.controlAppearance,
                      );
                    } else {
                      return FixedControl(
                        labels: data.mappings.map((mappingId) {
                          return routing.routes[mappingId]?.label ?? "";
                        }).toList(),
                        data: data,
                        scale: scale,
                        appearance: prefs.controlAppearance,
                      );
                    }
                  }).toList();
                  return GridPaper(
                    divisions: 1,
                    subdivisions: 1,
                    interval: controller.gridSize * scale,
                    color: isInEditMode && prefs.gridEnabled
                        ? Colors.grey
                        : Colors.transparent,
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
                        Vibration.vibrate(duration: 100);
                        controllerModel.addControl(newData);
                      },
                    ),
                  );
                }),
              ),
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
        color: isAccepting ? Colors.grey.shade700 : Colors.grey.shade800,
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
                  onDragStarted: () {
                    Vibration.vibrate(duration: 50);
                  },
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
        Vibration.vibrate(duration: 100);
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
  final ControlAppearance appearance;

  const EditableControl({
    Key key,
    this.labels,
    this.data,
    this.scale,
    this.stackKey,
    this.gridSize,
    this.controllerModel,
    this.appearance,
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
      height: widget.data.height,
      width: widget.data.width,
      labels: widget.labels,
      shape: widget.data.shape,
      scale: widget.scale,
      labelOnePosition: widget.data.labelOne.position,
      labelOneAngle: widget.data.labelOne.angle,
      labelTwoPosition: widget.data.labelTwo.position,
      labelTwoAngle: widget.data.labelTwo.angle,
      appearance: widget.appearance,
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
          Vibration.vibrate(duration: 200);
        },
      ),
      childWhenDragging: SizedBox.shrink(),
      feedback: control,
      onDragStarted: () {
        Vibration.vibrate(duration: 50);
      },
      onDragEnd: (details) {
        if (details.wasAccepted) {
          return;
        }
        Vibration.vibrate(duration: 50);
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
          Vibration.vibrate(duration: 50);
          showDialog(
            context: context,
            builder: (BuildContext context) => createControlDialog(
              context: context,
              title: control.labels[0],
              controlId: widget.data.id,
            ),
          );
        },
        onLongPress: () {},
        child: draggable,
      ),
    );
  }
}

class SettingRowLabel extends StatelessWidget {
  final String label;

  const SettingRowLabel(this.label, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      alignment: Alignment.centerLeft,
      child: Text('$label:'),
    );
  }
}

AlertDialog createControlDialog({
  BuildContext context,
  String title,
  String controlId,
}) {
  final controllerModel = context.watch<ControllerModel>();
  var control = controllerModel.findControlById(controlId);
  final theme = Theme.of(context);
  int controlSize = 35;
  final isCircular = control.shape == ControlShape.circle;
  return AlertDialog(
    backgroundColor: theme.dialogBackgroundColor.withOpacity(0.75),
    title: Text(title),
    content: Scrollbar(
      child: SingleChildScrollView(
        child: Container(
          width: 270,
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            defaultColumnWidth: IntrinsicColumnWidth(),
            children: [
              TableRow(
                children: [
                  SettingRowLabel("Shape"),
                  Center(
                    child: RawMaterialButton(
                      constraints: BoxConstraints(
                        minWidth: controlSize.toDouble() + 20,
                        minHeight: controlSize.toDouble() + 20,
                      ),
                      shape: StadiumBorder(),
                      onPressed: () =>
                          controllerModel.switchControlShape(controlId),
                      child: Control(
                        width: controlSize,
                        height: controlSize,
                        shape: control.shape,
                      ),
                    ),
                  )
                ],
              ),
              createSettingRow(
                label: isCircular ? 'Diameter' : 'Width',
                child: MinusPlus(
                  onMinus: () =>
                      controllerModel.decreaseControlWidth(controlId),
                  onPlus: () => controllerModel.increaseControlWidth(controlId),
                ),
              ),
              if (!isCircular)
                createSettingRow(
                  label: 'Height',
                  child: MinusPlus(
                    onMinus: () =>
                        controllerModel.decreaseControlHeight(controlId),
                    onPlus: () =>
                        controllerModel.increaseControlHeight(controlId),
                  ),
                ),
              createSettingRow(
                label: 'Label 1 position',
                child: ControlLabelPositionDropdownButton(
                  value: control.labelOne.position,
                  onChanged: (pos) {
                    controllerModel.changeControl(controlId, (control) {
                      control.labelOne.position = pos;
                    });
                  },
                ),
              ),
              createSettingRow(
                label: 'Label 1 rotation',
                child: RotationSlider(
                  angle: control.labelOne.angle,
                  shape: control.shape,
                  onChanged: (angle) {
                    controllerModel.changeControl(
                      controlId,
                      (c) => c.labelOne.angle = angle,
                    );
                  },
                ),
              ),
              createSettingRow(
                label: 'Label 2 position',
                child: ControlLabelPositionDropdownButton(
                  value: control.labelTwo.position,
                  onChanged: (pos) {
                    controllerModel.changeControl(controlId, (control) {
                      control.labelTwo.position = pos;
                    });
                  },
                ),
              ),
              createSettingRow(
                label: 'Label 2 rotation',
                child: RotationSlider(
                  angle: control.labelTwo.angle,
                  shape: control.shape,
                  onChanged: (angle) {
                    controllerModel.changeControl(
                      controlId,
                      (c) => c.labelTwo.angle = angle,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
  final ControlAppearance appearance;

  const FixedControl({
    Key key,
    this.labels,
    this.data,
    this.scale,
    this.appearance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: scale * data.y,
      left: scale * data.x,
      child: Control(
        height: data.height,
        width: data.width,
        labels: labels,
        shape: data.shape,
        scale: scale,
        labelOnePosition: data.labelOne.position,
        labelOneAngle: data.labelOne.angle,
        labelTwoPosition: data.labelTwo.position,
        labelTwoAngle: data.labelTwo.angle,
        appearance: appearance,
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
  final ControlLabelPosition labelOnePosition;
  final int labelOneAngle;
  final ControlLabelPosition labelTwoPosition;
  final int labelTwoAngle;
  final ControlAppearance appearance;

  const Control({
    Key key,
    this.labels = const [],
    @required this.width,
    @required this.height,
    this.shape = ControlShape.circle,
    this.fillColor = null,
    this.scale = 1.0,
    this.labelOnePosition = ControlLabelPosition.aboveTop,
    this.labelOneAngle = 0,
    this.labelTwoPosition = ControlLabelPosition.belowBottom,
    this.labelTwoAngle = 0,
    this.appearance = ControlAppearance.filled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (shape == ControlShape.circle) {
      return CircularControl(
        diameter: width,
        appearance: appearance,
        labels: labels,
        labelOnePosition: labelOnePosition,
        labelOneAngle: labelOneAngle,
        labelTwoPosition: labelTwoPosition,
        labelTwoAngle: labelTwoAngle,
        scale: scale,
        fillColor: fillColor,
      );
    } else {
      return RectangularControl(
        width: width,
        height: height,
        appearance: appearance,
        labels: labels,
        labelOnePosition: labelOnePosition,
        labelOneAngle: labelOneAngle,
        labelTwoPosition: labelTwoPosition,
        labelTwoAngle: labelTwoAngle,
        scale: scale,
      );
    }
  }
}

class DerivedControlProps {
  final ThemeData theme;
  final bool labelOneIsInside;
  final bool labelTwoIsInside;
  final ControlAppearance appearance;
  final Color enforcedFillColor;

  DerivedControlProps({
    @required this.labelOneIsInside,
    @required this.labelTwoIsInside,
    @required this.appearance,
    @required this.theme,
    this.enforcedFillColor,
  });

  Color get mainColor => enforcedFillColor ?? theme.colorScheme.primary;

  TextStyle get baseTextStyle => TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: fontSize,
        fontFamily: "monospace",
      );

  double get fontSize => 14;

  TextStyle get labelOneTextStyle {
    return baseTextStyle.copyWith(color: labelOneColor);
  }

  TextStyle get labelTwoTextStyle {
    return baseTextStyle.copyWith(color: labelTwoColor);
  }

  Color get labelOneColor {
    if (appearance == ControlAppearance.outlinedMono) {
      return theme.colorScheme.primary;
    } else {
      return labelOneIsInside && !strokeOnly
          ? theme.colorScheme.onPrimary
          : theme.colorScheme.onSurface;
    }
  }

  Color get labelTwoColor {
    if (appearance == ControlAppearance.outlinedMono) {
      return labelTwoIsInside && !strokeOnly
          ? theme.colorScheme.onBackground
          : theme.colorScheme.secondary;
    } else {
      return labelOneColor;
    }
  }

  bool get strokeOnly {
    return appearance == ControlAppearance.outlined ||
        appearance == ControlAppearance.outlinedMono;
  }

  Color get decorationColor => strokeOnly ? null : mainColor;

  BoxBorder get border {
    return Border.all(width: strokeWidth, color: borderColor);
  }

  Color get borderColor {
    switch (appearance) {
      case ControlAppearance.filled:
      case ControlAppearance.outlined:
        return mainColor;
      case ControlAppearance.filledAndOutlined:
      case ControlAppearance.outlinedMono:
        return theme.colorScheme.onSurface;
    }
  }

  double get strokeWidth => 2;
}

bool labelPositionIsInside(ControlLabelPosition pos) {
  switch (pos) {
    case ControlLabelPosition.belowTop:
    case ControlLabelPosition.center:
    case ControlLabelPosition.aboveBottom:
    case ControlLabelPosition.rightOfLeft:
    case ControlLabelPosition.leftOfRight:
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
  final ControlLabelPosition labelOnePosition;
  final int labelOneAngle;
  final ControlLabelPosition labelTwoPosition;
  final int labelTwoAngle;
  final double scale;

  const RectangularControl({
    Key key,
    @required this.appearance,
    @required this.labels,
    @required this.width,
    @required this.height,
    @required this.labelOnePosition,
    @required this.labelOneAngle,
    @required this.labelTwoPosition,
    @required this.labelTwoAngle,
    @required this.scale,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final props = DerivedControlProps(
      labelOneIsInside: labelPositionIsInside(labelOnePosition),
      labelTwoIsInside: labelPositionIsInside(labelTwoPosition),
      appearance: appearance,
      theme: Theme.of(context),
    );
    final labelOne = labels.length > 0 ? labels[0] : null;
    final labelTwo = labels.length > 1 ? labels[1] : null;
    final scaledWidth = scale * width;
    final scaledHeight = scale * height;
    Positioned buildLabelText(
      String label, {
      ControlLabelPosition position,
      int angle,
      TextStyle style,
    }) {
      final attrs = _getAttributesForPosition(position);
      return Positioned(
        top: attrs.top * scaledHeight.toDouble(),
        height: scaledHeight.toDouble(),
        left: attrs.left * scaledWidth.toDouble(),
        width: scaledWidth.toDouble(),
        child: Align(
          alignment: attrs.alignment,
          child: RotatedBox(
            quarterTurns: convertAngleToQuarterTurns(angle),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: style,
              textScaleFactor: scale,
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    return Stack(
      // We want to draw text outside of the stack's dimensions!
      clipBehavior: Clip.none,
      children: [
        Container(
          width: scaledWidth.toDouble(),
          height: scaledHeight.toDouble(),
          decoration: new BoxDecoration(
            color: props.decorationColor,
            border: props.border,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
        if (labelOne != null)
          buildLabelText(
            labelOne,
            position: labelOnePosition,
            angle: labelOneAngle,
            style: props.labelOneTextStyle,
          ),
        if (labelTwo != null)
          buildLabelText(
            labelTwo,
            position: labelTwoPosition,
            angle: labelTwoAngle,
            style: props.labelTwoTextStyle,
          )
      ],
    );
  }
}

_PosAttrs _getAttributesForPosition(ControlLabelPosition pos) {
  switch (pos) {
    case ControlLabelPosition.aboveTop:
      return _PosAttrs(top: -1, left: 0, alignment: Alignment.bottomCenter);
    case ControlLabelPosition.belowTop:
      return _PosAttrs(top: 0, left: 0, alignment: Alignment.topCenter);
    case ControlLabelPosition.center:
      return _PosAttrs(top: 0, left: 0, alignment: Alignment.center);
    case ControlLabelPosition.aboveBottom:
      return _PosAttrs(top: 0, left: 0, alignment: Alignment.bottomCenter);
    case ControlLabelPosition.belowBottom:
      return _PosAttrs(top: 1, left: 0, alignment: Alignment.topCenter);
    case ControlLabelPosition.leftOfLeft:
      return _PosAttrs(top: 0, left: -1, alignment: Alignment.centerRight);
    case ControlLabelPosition.rightOfLeft:
      return _PosAttrs(top: 0, left: 0, alignment: Alignment.centerLeft);
    case ControlLabelPosition.leftOfRight:
      return _PosAttrs(top: 0, left: 0, alignment: Alignment.centerRight);
    case ControlLabelPosition.rightOfRight:
      return _PosAttrs(top: 0, left: 1, alignment: Alignment.centerLeft);
  }
}

class _PosAttrs {
  final int top;
  final int left;
  final AlignmentGeometry alignment;

  _PosAttrs({this.top, this.left, this.alignment});
}

class CircularControl extends StatelessWidget {
  final int diameter;
  final ControlAppearance appearance;
  final List<String> labels;
  final ControlLabelPosition labelOnePosition;
  final int labelOneAngle;
  final ControlLabelPosition labelTwoPosition;
  final int labelTwoAngle;
  final double scale;
  final Color fillColor;

  const CircularControl({
    Key key,
    @required this.appearance,
    @required this.labels,
    @required this.diameter,
    @required this.labelOnePosition,
    @required this.labelOneAngle,
    @required this.labelTwoPosition,
    @required this.labelTwoAngle,
    @required this.scale,
    this.fillColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final props = DerivedControlProps(
      labelOneIsInside: labelPositionIsInside(labelOnePosition),
      labelTwoIsInside: labelPositionIsInside(labelTwoPosition),
      appearance: appearance,
      theme: Theme.of(context),
      enforcedFillColor: fillColor,
    );
    final scaledDiameter = scale * diameter;
    double actualDiameter = scaledDiameter;
    double fontSize = props.fontSize * scale;
    Widget createCenterText(
      String label, {
      TextStyle style,
      int angle,
    }) {
      return Align(
        child: RotatedBox(
          quarterTurns: convertAngleToQuarterTurns(angle),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: style,
            textScaleFactor: scale,
          ),
        ),
      );
    }

    Widget createCircularText(
      String label, {
      ControlLabelPosition pos,
      TextStyle style,
      int angle,
    }) {
      final attrs = convertToCircularAttributes(pos, angle);
      final isInside = labelPositionIsInside(pos);
      return Align(
        child: ArcText(
          radius: scaledDiameter / 2,
          text: label,
          textStyle: style.copyWith(fontSize: fontSize, letterSpacing: -1),
          startAngle: (attrs.startAngle * math.pi) / 180.0 + math.pi / 2,
          placement: isInside ? Placement.inside : Placement.outside,
          direction: attrs.direction,
          startAngleAlignment: StartAngleAlignment.center,
        ),
      );
    }

    return Container(
      width: actualDiameter,
      height: actualDiameter,
      child: Stack(
        children: [
          Container(
            decoration: new BoxDecoration(
              color: props.decorationColor,
              shape: BoxShape.circle,
              border: props.border,
            ),
          ),
          if (labels.length > 0)
            labelOnePosition == ControlLabelPosition.center
                ? createCenterText(
                    labels[0],
                    style: props.labelOneTextStyle,
                    angle: labelOneAngle,
                  )
                : createCircularText(
                    labels[0],
                    pos: labelOnePosition,
                    style: props.labelOneTextStyle,
                    angle: labelOneAngle,
                  ),
          if (labels.length > 1)
            labelTwoPosition == ControlLabelPosition.center
                ? createCenterText(
                    labels[1],
                    style: props.labelTwoTextStyle,
                    angle: labelTwoAngle,
                  )
                : createCircularText(
                    labels[1],
                    pos: labelTwoPosition,
                    style: props.labelTwoTextStyle,
                    angle: labelTwoAngle,
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
    case ControlAppearance.filledAndOutlined:
      return Icons.radio_button_checked;
    case ControlAppearance.outlinedMono:
      return Icons.remove_circle_outline;
      break;
  }
}

String getControlLabelPositionLabel(ControlLabelPosition pos) {
  switch (pos) {
    case ControlLabelPosition.aboveTop:
      return "Above top";
    case ControlLabelPosition.belowTop:
      return "Below top";
    case ControlLabelPosition.center:
      return "Center";
    case ControlLabelPosition.aboveBottom:
      return "Above bottom";
    case ControlLabelPosition.belowBottom:
      return "Below bottom";
    case ControlLabelPosition.leftOfLeft:
      return "Left of left";
    case ControlLabelPosition.rightOfLeft:
      return "Right of left";
    case ControlLabelPosition.leftOfRight:
      return "Left of right";
    case ControlLabelPosition.rightOfRight:
      return "Right of right";
  }
}

TableRow createSettingRow({String label, Widget child}) {
  return TableRow(
    children: [
      SettingRowLabel(label),
      Center(child: child),
    ],
  );
}

class MinusPlus extends StatelessWidget {
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const MinusPlus({Key key, this.onMinus, this.onPlus}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.remove_circle),
          onPressed: onMinus,
        ),
        IconButton(
          icon: Icon(Icons.add_circle),
          onPressed: onPlus,
        ),
      ],
    );
  }
}

class ControlLabelPositionDropdownButton extends StatelessWidget {
  final ControlLabelPosition value;
  final Function(ControlLabelPosition pos) onChanged;

  const ControlLabelPositionDropdownButton(
      {Key key, this.value, this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButton(
        value: value,
        items: ControlLabelPosition.values.map((value) {
          return new DropdownMenuItem(
            value: value,
            child: Text(getControlLabelPositionLabel(value)),
          );
        }).toList(),
        onChanged: onChanged);
  }
}

class RotationSlider extends StatelessWidget {
  final int angle;
  final Function(int angle) onChanged;
  final ControlShape shape;

  const RotationSlider({Key key, this.angle, this.onChanged, this.shape})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isCircular = shape == ControlShape.circle;
    return Slider(
      value: isCircular ? (angle == 180 ? 180 : 0) : angle.toDouble(),
      min: 0,
      max: isCircular ? 180 : 270,
      divisions: isCircular ? 1 : 3,
      label: '$angle°',
      onChanged: (double value) {
        onChanged(value.toInt());
      },
    );
  }
}

int convertAngleToQuarterTurns(int angle) {
  if (angle < 90) {
    return 0;
  }
  if (angle < 180) {
    return 1;
  }
  if (angle < 270) {
    return 2;
  }
  return 3;
}

_CircularAttr convertToCircularAttributes(ControlLabelPosition pos, int angle) {
  switch (pos) {
    case ControlLabelPosition.aboveTop:
    case ControlLabelPosition.belowTop:
    case ControlLabelPosition.center:
      return _CircularAttr(
        startAngle: -90,
        direction: invertIf180(Direction.clockwise, angle),
      );
    case ControlLabelPosition.aboveBottom:
    case ControlLabelPosition.belowBottom:
      return _CircularAttr(
          startAngle: 90,
          direction: invertIf180(Direction.counterClockwise, angle));
    case ControlLabelPosition.leftOfLeft:
    case ControlLabelPosition.rightOfLeft:
      return _CircularAttr(
          startAngle: 180, direction: invertIf180(Direction.clockwise, angle));
    case ControlLabelPosition.leftOfRight:
    case ControlLabelPosition.rightOfRight:
      return _CircularAttr(
          startAngle: 0, direction: invertIf180(Direction.clockwise, angle));
  }
}

Direction invertIf180(Direction dir, int angle) {
  if (angle == 180) {
    return dir == Direction.clockwise
        ? Direction.counterClockwise
        : Direction.clockwise;
  } else {
    return dir;
  }
}

class _CircularAttr {
  final double startAngle;
  final Direction direction;

  _CircularAttr({this.startAngle, this.direction});
}
