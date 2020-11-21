import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/services.dart';
import 'package:flutter_arc_text/flutter_arc_text.dart';
import 'package:provider/provider.dart';
import 'package:realearn_companion/domain/preferences.dart';
import 'package:realearn_companion/domain/preferences.dart' as preferences;
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

enum PageMode { view, edit, editMulti }

class PageModel extends ChangeNotifier {
  PageMode _pageMode = PageMode.view;
  Set<String> _selectedControlIds = HashSet();

  PageMode get pageMode => _pageMode;

  bool controlIsSelected(String controlId) {
    return isInMultiEditMode && _selectedControlIds.contains(controlId);
  }

  Set<String> get selectedControlIds {
    // Defensive copy
    return HashSet.of(_selectedControlIds);
  }

  int get selectedControlsCount {
    return _selectedControlIds.length;
  }

  void selectOrUnselectControl(String controlId) {
    if (controlIsSelected(controlId)) {
      if (selectedControlsCount == 1) {
        leaveMultiEditMode();
        return;
      }
      _selectedControlIds.remove(controlId);
    } else {
      _selectedControlIds.add(controlId);
    }
    notifyListeners();
  }

  bool get isInEditMode {
    return _pageMode != PageMode.view;
  }

  bool get isInMultiEditMode {
    return _pageMode == PageMode.editMulti;
  }

  void enterEditMode() {
    _pageMode = PageMode.edit;
    notifyListeners();
  }

  void leaveEditMode() {
    _pageMode = PageMode.view;
    _selectedControlIds.clear();
    notifyListeners();
  }

  void enterMultiEditMode(String initiallySelectedControlId) {
    _pageMode = PageMode.editMulti;
    _selectedControlIds.add(initiallySelectedControlId);
    notifyListeners();
  }

  void leaveMultiEditMode() {
    _pageMode = PageMode.edit;
    _selectedControlIds.clear();
    notifyListeners();
  }
}

class ControllerRoutingPageState extends State<ControllerRoutingPage> {
  bool appBarIsVisible = true;

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

  void saveController() async {
    var controllerModel = this.context.read<ControllerModel>();
    await ControllerRepository(widget.connectionData)
        .save(controllerModel.controller);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Saved controller layout")),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppBar controllerRoutingAppBar(
        ControllerModel controllerModel, PageModel pageModel) {
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
                color: pageModel.isInEditMode ? theme.accentColor : null,
                onPressed: () {
                  if (pageModel.isInEditMode) {
                    pageModel.leaveEditMode();
                  } else {
                    pageModel.enterEditMode();
                  }
                },
              ),
            PopupMenuButton(
              itemBuilder: (BuildContext context) {
                return <PopupMenuEntry>[
                  if (!pageModel.isInEditMode)
                    PopupMenuItem(
                      child: Consumer<AppPreferences>(
                        builder: (context, prefs, child) {
                          return ListTile(
                            leading: LeadingMenuBarIcon(Icons.format_size),
                            title: Text('Text'),
                            onTap: () {},
                            trailing: MinusPlus(
                              onMinus: () {
                                prefs.adjustFontSizeBy(-1);
                              },
                              onPlus: () {
                                prefs.adjustFontSizeBy(1);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  if (!pageModel.isInEditMode)
                    PopupMenuItem(
                      child: Consumer<AppPreferences>(
                        builder: (context, prefs, child) {
                          return ListTile(
                            leading: LeadingMenuBarIcon(
                              getThemeModeIcon(prefs.themeMode),
                            ),
                            onTap: prefs.switchThemeMode,
                            title: Text('Theme mode'),
                          );
                        },
                      ),
                    ),
                  if (!pageModel.isInEditMode)
                    PopupMenuItem(
                      child: Consumer<AppPreferences>(
                        builder: (context, prefs, child) {
                          return CheckboxListTile(
                            value: prefs.highContrastEnabled,
                            onChanged: (_) => prefs.toggleHighContrast(),
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text('High contrast'),
                          );
                        },
                      ),
                    ),
                  if (!pageModel.isInEditMode)
                    PopupMenuItem(
                      child: Consumer<AppPreferences>(
                        builder: (context, prefs, child) {
                          return CheckboxListTile(
                            value: prefs.backgroundImageEnabled,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: prefs.highContrastEnabled
                                ? null
                                : (_) => prefs.toggleBackgroundImage(),
                            title: Text('Background image'),
                          );
                        },
                      ),
                    ),
                  if (!pageModel.isInEditMode)
                    PopupMenuItem(
                      child: Consumer<AppPreferences>(
                        builder: (context, prefs, child) {
                          return ListTile(
                            leading: LeadingMenuBarIcon(
                              getControlAppearanceIcon(prefs.controlAppearance),
                            ),
                            onTap: prefs.switchControlAppearance,
                            title: Text('Control coloring'),
                          );
                        },
                      ),
                    ),
                  if (!pageModel.isInEditMode)
                    PopupMenuItem(
                      child: Consumer<AppPreferences>(
                        builder: (context, prefs, child) {
                          return ListTile(
                            leading: LeadingMenuBarIcon(
                              getBorderStyleIcon(prefs.borderStyle),
                            ),
                            onTap: prefs.switchBorderStyle,
                            title: Text('Control border style'),
                          );
                        },
                      ),
                    ),
                  if (pageModel.isInEditMode)
                    PopupMenuItem(
                      child: Consumer<AppPreferences>(
                        builder: (context, prefs, child) {
                          return CheckboxListTile(
                            value: prefs.gridEnabled,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (_) => prefs.toggleGrid(),
                            title: Text('Grid'),
                            secondary: prefs.gridEnabled
                                ? MinusPlus(
                                    onMinus: () {
                                      context
                                          .read<ControllerModel>()
                                          .decreaseGridSize();
                                    },
                                    onPlus: () {
                                      context
                                          .read<ControllerModel>()
                                          .increaseGridSize();
                                    },
                                  )
                                : null,
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
    return ChangeNotifierProvider(
      create: (context) => PageModel(),
      child: Consumer2<ControllerModel, PageModel>(
          builder: (context, controllerModel, pageModel, child) {
        return NormalScaffold(
          padding: EdgeInsets.zero,
          appBar: appBarIsVisible
              ? controllerRoutingAppBar(controllerModel, pageModel)
              : null,
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
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

class LeadingMenuBarIcon extends StatelessWidget {
  final IconData icon;

  const LeadingMenuBarIcon(this.icon, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      // For being on the same horizontal position like the checkbox in the
      // CheckboxListTile
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Icon(icon),
    );
  }
}

class ControllerRoutingContainer extends StatefulWidget {
  final Stream<dynamic> messages;

  const ControllerRoutingContainer({
    Key key,
    this.messages,
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
          final controllerModel = context.read<ControllerModel>();
          controllerModel.controller =
              Controller.fromJson(realearnEvent.payload);
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
  final GlobalKey stackKey = GlobalKey();

  ControllerRoutingWidget({
    Key key,
    this.routing,
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

    final pageModel = context.watch<PageModel>();
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
                boundaryMargin: EdgeInsets.all(200),
                minScale: 0.25,
                maxScale: 8,
                child: LayoutBuilder(builder:
                    (BuildContext context, BoxConstraints constraints) {
                  var widthScale = constraints.maxWidth / controllerSize.width;
                  var heightScale =
                      constraints.maxHeight / controllerSize.height;
                  var scale = math.min(widthScale, heightScale);
                  var prefs = context.watch<AppPreferences>();
                  var controls = controller.controls.map((data) {
                    if (pageModel.isInEditMode) {
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
                        borderStyle: prefs.borderStyle,
                        fontSize: prefs.fontSize,
                      );
                    } else {
                      final descriptorsForEachMapping =
                          data.mappings.map((mappingId) {
                        return routing.routes[mappingId] ?? [];
                      }).toList();
                      return FixedControl(
                        labels: getLabels(descriptorsForEachMapping),
                        data: data,
                        scale: scale,
                        appearance: prefs.controlAppearance,
                        borderStyle: prefs.borderStyle,
                        fontSize: prefs.fontSize,
                      );
                    }
                  }).toList();
                  return GridPaper(
                    divisions: 1,
                    subdivisions: 1,
                    interval: controller.gridSize * scale,
                    color: pageModel.isInEditMode && prefs.gridEnabled
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
        if (pageModel.isInEditMode)
          createControlBag(
            direction: isPortrait ? Axis.horizontal : Axis.vertical,
          )
      ],
    );
  }
}

List<String> getLabels(
  List<List<TargetDescriptor>> descriptorsForEachMapping,
) {
  var sourceCount = descriptorsForEachMapping.length;
  if (sourceCount == 1) {
    // There's just one source that this control element represents. If there's
    // a second target mapped to this source, we can display it as second label.
    final descriptors = descriptorsForEachMapping.first;
    if (descriptors.isEmpty) {
      // Not assigned
      return [];
    }
    return [
      descriptors.first.label,
      if (descriptors.length > 1) formatAsOneLabel(descriptors.sublist(1))
    ];
  }
  if (sourceCount == 2) {
    // The two control labels are reserved for two different sources that are
    // united in one control element (e.g. push encoder). So we need to place
    // each source in one label.
    final firstSourceDescriptors = descriptorsForEachMapping.first;
    final secondSourceDescriptors = descriptorsForEachMapping[1];
    return [
      if (firstSourceDescriptors.isNotEmpty)
        formatAsOneLabel(firstSourceDescriptors),
      if (secondSourceDescriptors.isNotEmpty)
        formatAsOneLabel(secondSourceDescriptors),
    ];
  }
  // A control element must only exist if it has at least one mapping.
  // Control elements that represent more than 2 mappings are not possible at
  // the moment.
  assert(false);
}

String formatAsOneLabel(List<TargetDescriptor> descriptors) {
  final count = descriptors.length;
  if (count == 0) {
    return "";
  }
  if (count == 1) {
    return descriptors.first.label;
  }
  if (count > 1) {
    return '${descriptors.first.label} +${count - 1}';
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
                  borderStyle: preferences.BorderStyle.solid,
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
        final pageModel = context.read<PageModel>();
        if (pageModel.isInMultiEditMode) {
          return;
        }
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
  final preferences.BorderStyle borderStyle;
  final int fontSize;

  const EditableControl({
    Key key,
    this.labels,
    this.data,
    this.scale,
    this.stackKey,
    this.gridSize,
    this.controllerModel,
    this.appearance,
    this.borderStyle,
    this.fontSize,
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
    final coreControl = Control(
      height: widget.data.height,
      width: widget.data.width,
      labels: widget.labels,
      shape: widget.data.shape,
      scale: widget.scale,
      labelOnePosition: widget.data.labelOne.position,
      labelOneSizeConstrained: widget.data.labelOne.sizeConstrained,
      labelOneAngle: widget.data.labelOne.angle,
      labelTwoPosition: widget.data.labelTwo.position,
      labelTwoSizeConstrained: widget.data.labelTwo.sizeConstrained,
      labelTwoAngle: widget.data.labelTwo.angle,
      appearance: widget.appearance,
      borderStyle: widget.borderStyle,
      fontSize: widget.fontSize,
    );
    final pageModel = context.watch<PageModel>();
    final theme = Theme.of(context);
    final control = pageModel.controlIsSelected(widget.data.id)
        ? ColorFiltered(
            colorFilter: ColorFilter.mode(
              theme.colorScheme.secondary.withOpacity(0.4),
              BlendMode.srcOver,
            ),
            child: coreControl,
          )
        : coreControl;
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
          if (pageModel.isInMultiEditMode) {
            return;
          }
          final controllerModel = context.read<ControllerModel>();
          controllerModel.uniteControls(widget.data, data);
          Vibration.vibrate(duration: 200);
        },
      ),
      childWhenDragging: SizedBox.shrink(),
      feedback: control,
      onDragEnd: (details) {
        if (details.wasAccepted) {
          return;
        }
        if (pageModel.isInMultiEditMode &&
            !pageModel.selectedControlIds.contains(widget.data.id)) {
          return;
        }
        final controlIds = pageModel.isInMultiEditMode
            ? pageModel.selectedControlIds
            : [widget.data.id];
        Vibration.vibrate(duration: 50);
        var finalPos = getFinalDragPosition(
          gridSize: widget.gridSize,
          globalPosition: details.offset,
          stackKey: widget.stackKey,
          scale: widget.scale,
        );
        final controllerModel = context.read<ControllerModel>();
        final xDelta = finalPos.dx.toInt() - widget.data.x;
        final yDelta = finalPos.dy.toInt() - widget.data.y;
        controllerModel.moveControlsBy(controlIds, xDelta, yDelta);
      },
    );
    return Positioned(
      top: widget.offset.dy * widget.scale,
      left: widget.offset.dx * widget.scale,
      child: GestureDetector(
        onTap: () {
          Vibration.vibrate(duration: 50);
          if (pageModel.isInMultiEditMode) {
            pageModel.selectOrUnselectControl(widget.data.id);
          } else {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return createControlDialog(
                  context: context,
                  title: coreControl.labels[0],
                  controlIds: HashSet.of([widget.data.id]),
                );
              },
            );
          }
        },
        onLongPress: () {
          Vibration.vibrate(duration: 200);
          if (pageModel.isInMultiEditMode) {
            if (!pageModel.controlIsSelected(widget.data.id)) {
              return;
            }
            Vibration.vibrate(duration: 50);
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return createControlDialog(
                  context: context,
                  title: '${pageModel.selectedControlsCount} controls',
                  controlIds: pageModel.selectedControlIds,
                  italic: true,
                );
              },
            );
          } else {
            pageModel.enterMultiEditMode(widget.data.id);
          }
        },
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

final italicTextStyle = const TextStyle(fontStyle: FontStyle.italic);
final multipleText = Text("multiple", style: italicTextStyle);

AlertDialog createControlDialog({
  BuildContext context,
  String title,
  Set<String> controlIds,
  bool italic = false,
}) {
  final controllerModel = context.watch<ControllerModel>();
  final controls = controlIds.map(controllerModel.findControlById).toList();
  final theme = Theme.of(context);
  int controlSize = 35;
  final shape = getValueIfAllEqual(controls, (c) => c.shape);
  final isCircular = shape == ControlShape.circle;
  final labelOnePosition =
      getValueIfAllEqual(controls, (c) => c.labelOne.position);
  final labelOneAngle = getValueIfAllEqual(controls, (c) => c.labelOne.angle);
  final labelOneSizedConstrained =
      getValueIfAllEqual(controls, (c) => c.labelOne.sizeConstrained);
  final labelTwoPosition =
      getValueIfAllEqual(controls, (c) => c.labelTwo.position);
  final labelTwoAngle = getValueIfAllEqual(controls, (c) => c.labelTwo.angle);
  final labelTwoSizeConstrained =
      getValueIfAllEqual(controls, (c) => c.labelTwo.sizeConstrained);
  return AlertDialog(
    backgroundColor: theme.dialogBackgroundColor.withOpacity(0.75),
    title: Text(
      title,
      style: italic ? italicTextStyle : null,
    ),
    content: Scrollbar(
      child: SingleChildScrollView(
        child: Container(
          width: 270,
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            defaultColumnWidth: IntrinsicColumnWidth(),
            children: [
              createSettingRow(
                label: 'Shape',
                child: RawMaterialButton(
                  constraints: BoxConstraints(
                    minWidth: controlSize.toDouble() + 20,
                    minHeight: controlSize.toDouble() + 20,
                  ),
                  shape: StadiumBorder(),
                  onPressed: () {
                    controllerModel.changeControls(controlIds, (c) {
                      if (shape == null) {
                        c.shape = ControlShape.circle;
                      } else {
                        c.switchShape();
                      }
                    });
                  },
                  child: shape == null
                      ? multipleText
                      : Control(
                          width: controlSize,
                          height: controlSize,
                          shape: shape,
                          appearance: ControlAppearance.outlined,
                        ),
                ),
              ),
              createSettingRow(
                label: isCircular ? 'Diameter' : 'Width',
                child: MinusPlus(
                  onMinus: () {
                    controllerModel.decreaseControlWidth(controlIds);
                  },
                  onPlus: () {
                    controllerModel.increaseControlWidth(controlIds);
                  },
                ),
              ),
              if (!isCircular)
                createSettingRow(
                  label: 'Height',
                  child: MinusPlus(
                    onMinus: () {
                      controllerModel.decreaseControlHeight(controlIds);
                    },
                    onPlus: () {
                      controllerModel.increaseControlHeight(controlIds);
                    },
                  ),
                ),
              createSettingRow(
                label: 'Label 1 position',
                child: ControlLabelPositionDropdownButton(
                  value: labelOnePosition,
                  onChanged: (pos) {
                    controllerModel.changeControls(
                      controlIds,
                      (control) => control.labelOne.position = pos,
                    );
                  },
                ),
              ),
              if (!labelPositionIsInside(labelOnePosition))
                createSettingRow(
                  label: 'Label 1 sized',
                  child: SizeConstrainedCheckbox(
                    sizeConstrained: labelOneSizedConstrained,
                    onChanged: (sizeConstrained) {
                      controllerModel.changeControls(
                        controlIds,
                        (control) =>
                            control.labelOne.sizeConstrained = sizeConstrained,
                      );
                    },
                  ),
                ),
              createSettingRow(
                label: 'Label 1 rotation',
                child: RotationSlider(
                  angle: labelOneAngle,
                  shape: shape,
                  onChanged: (angle) {
                    controllerModel.changeControls(
                      controlIds,
                      (c) => c.labelOne.angle = angle,
                    );
                  },
                ),
              ),
              createSettingRow(
                label: 'Label 2 position',
                child: ControlLabelPositionDropdownButton(
                  value: labelTwoPosition,
                  onChanged: (pos) {
                    controllerModel.changeControls(
                      controlIds,
                      (control) => control.labelTwo.position = pos,
                    );
                  },
                ),
              ),
              if (!labelPositionIsInside(labelTwoPosition))
                createSettingRow(
                  label: 'Label 2 sized',
                  child: SizeConstrainedCheckbox(
                    sizeConstrained: labelTwoSizeConstrained,
                    onChanged: (sizeConstrained) {
                      controllerModel.changeControls(
                        controlIds,
                        (control) =>
                            control.labelTwo.sizeConstrained = sizeConstrained,
                      );
                    },
                  ),
                ),
              createSettingRow(
                label: 'Label 2 rotation',
                child: RotationSlider(
                  angle: labelTwoAngle,
                  shape: shape,
                  onChanged: (angle) {
                    controllerModel.changeControls(
                      controlIds,
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
  final preferences.BorderStyle borderStyle;
  final int fontSize;

  const FixedControl({
    Key key,
    this.labels,
    this.data,
    this.scale,
    this.appearance,
    this.borderStyle,
    this.fontSize,
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
        labelOneSizeConstrained: data.labelOne.sizeConstrained,
        labelOneAngle: data.labelOne.angle,
        labelTwoPosition: data.labelTwo.position,
        labelTwoSizeConstrained: data.labelTwo.sizeConstrained,
        labelTwoAngle: data.labelTwo.angle,
        appearance: appearance,
        borderStyle: borderStyle,
        fontSize: fontSize,
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
  final bool labelOneSizeConstrained;
  final int labelOneAngle;
  final ControlLabelPosition labelTwoPosition;
  final int labelTwoAngle;
  final bool labelTwoSizeConstrained;
  final ControlAppearance appearance;
  final preferences.BorderStyle borderStyle;
  final int fontSize;

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
    this.borderStyle = preferences.BorderStyle.dotted,
    this.fontSize = 14,
    this.labelOneSizeConstrained = true,
    this.labelTwoSizeConstrained = true,
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
        borderStyle: borderStyle,
        fontSize: fontSize,
      );
    } else {
      return RectangularControl(
        width: width,
        height: height,
        appearance: appearance,
        labels: labels,
        labelOnePosition: labelOnePosition,
        labelOneSizeConstrained: labelOneSizeConstrained,
        labelOneAngle: labelOneAngle,
        labelTwoPosition: labelTwoPosition,
        labelTwoSizeConstrained: labelTwoSizeConstrained,
        labelTwoAngle: labelTwoAngle,
        scale: scale,
        borderStyle: borderStyle,
        fontSize: fontSize,
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
  final int fontSize;

  DerivedControlProps({
    @required this.labelOneIsInside,
    @required this.labelTwoIsInside,
    @required this.appearance,
    @required this.theme,
    @required this.fontSize,
    this.enforcedFillColor,
  });

  Color get mainColor => enforcedFillColor ?? theme.colorScheme.primary;

  TextStyle get baseTextStyle => TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: fontSize.toDouble(),
        fontFamily: "monospace",
      );

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
      return labelTwoIsInside && !strokeOnly
          ? theme.colorScheme.onPrimary
          : theme.colorScheme.onSurface;
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

  Radius get borderRadius {
    return Radius.circular(10);
  }

  BoxDecoration get boxDecoration {
    return new BoxDecoration(
      color: decorationColor,
      borderRadius: BorderRadius.all(borderRadius),
    );
  }

  BoxDecoration get solidBoxDecoration {
    return new BoxDecoration(
      color: decorationColor,
      border: border,
      borderRadius: BorderRadius.all(borderRadius),
    );
  }

  DottedBorder createDottedRectangleBorder({Widget child}) {
    return DottedBorder(
      color: borderColor,
      strokeWidth: strokeWidth,
      child: child,
      padding: EdgeInsets.zero,
      radius: borderRadius,
      borderType: BorderType.RRect,
    );
  }

  DottedBorder createDottedCircularBorder({Widget child}) {
    return DottedBorder(
      color: borderColor,
      strokeWidth: strokeWidth,
      child: child,
      padding: EdgeInsets.zero,
      borderType: BorderType.Circle,
      strokeCap: StrokeCap.butt,
    );
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
  final preferences.BorderStyle borderStyle;
  final int fontSize;
  final bool labelOneSizeConstrained;
  final bool labelTwoSizeConstrained;

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
    @required this.borderStyle,
    @required this.fontSize,
    @required this.labelOneSizeConstrained,
    @required this.labelTwoSizeConstrained,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final props = DerivedControlProps(
      labelOneIsInside: labelPositionIsInside(labelOnePosition),
      labelTwoIsInside: labelPositionIsInside(labelTwoPosition),
      appearance: appearance,
      theme: Theme.of(context),
      fontSize: fontSize,
    );
    final labelOne = labels.length > 0 ? labels[0] : null;
    final labelTwo = labels.length > 1 ? labels[1] : null;
    final scaledWidth = scale * width;
    final scaledHeight = scale * height;
    Positioned buildLabelText(
      String label, {
      ControlLabelPosition position,
      int angle,
      bool sizeConstrained,
      TextStyle style,
    }) {
      final attrs = _getAttributesForPosition(position);
      var child = Align(
        alignment: attrs.alignment,
        child: RotatedBox(
          quarterTurns: convertAngleToQuarterTurns(angle),
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: style,
              textScaleFactor: scale,
            ),
          ),
        ),
      );
      if (labelPositionIsInside(position)) {
        return Positioned(
          top: attrs.top * scaledHeight.toDouble(),
          height: scaledHeight.toDouble(),
          left: attrs.left * scaledWidth.toDouble(),
          width: scaledWidth.toDouble(),
          child: child,
        );
      } else {
        final expansionFactor = sizeConstrained ? 1 : 4;
        final expandedWidth = scaledWidth.toDouble() * expansionFactor;
        final expandedHeight = scaledHeight.toDouble() * expansionFactor;
        final centeredTop = scaledHeight / 2 - expandedHeight / 2;
        final centeredLeft = scaledWidth / 2 - expandedWidth / 2;
        final topShift = expandedHeight / 2 + scaledHeight / 2;
        final leftShift = expandedWidth / 2 + scaledWidth / 2;
        return Positioned(
          left: centeredLeft + attrs.left * leftShift,
          top: centeredTop + attrs.top * topShift,
          width: expandedWidth,
          height: expandedHeight,
          child: child,
        );
      }
    }

    var core = Container(
      width: scaledWidth.toDouble(),
      height: scaledHeight.toDouble(),
      decoration: isDotted(borderStyle)
          ? props.boxDecoration
          : props.solidBoxDecoration,
    );
    return Stack(
      // We want to draw text outside of the stack's dimensions!
      clipBehavior: Clip.none,
      children: [
        isDotted(borderStyle)
            ? props.createDottedRectangleBorder(
                child: core,
              )
            : core,
        if (labelOne != null)
          buildLabelText(
            labelOne,
            position: labelOnePosition,
            angle: labelOneAngle,
            style: props.labelOneTextStyle,
            sizeConstrained: labelOneSizeConstrained,
          ),
        if (labelTwo != null)
          buildLabelText(
            labelTwo,
            position: labelTwoPosition,
            angle: labelTwoAngle,
            style: props.labelTwoTextStyle,
            sizeConstrained: labelTwoSizeConstrained,
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
  final preferences.BorderStyle borderStyle;
  final int fontSize;

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
    @required this.borderStyle,
    @required this.fontSize,
    this.fillColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final props = DerivedControlProps(
      labelOneIsInside: labelPositionIsInside(labelOnePosition),
      labelTwoIsInside: labelPositionIsInside(labelTwoPosition),
      appearance: appearance,
      theme: Theme.of(context),
      fontSize: fontSize,
      enforcedFillColor: fillColor,
    );
    final scaledDiameter = scale * diameter;
    double actualDiameter = scaledDiameter;
    double scaledFontSize = props.fontSize * scale;
    Widget createCenterText(
      String label, {
      TextStyle style,
      int angle,
    }) {
      return Align(
        child: RotatedBox(
          quarterTurns: convertAngleToQuarterTurns(angle),
          child: Padding(
            padding: const EdgeInsets.all(2.0),
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
          radius: (scaledDiameter / 2) + (isInside ? -1 : 1) * 1,
          text: label,
          textStyle:
              style.copyWith(fontSize: scaledFontSize, letterSpacing: -1),
          startAngle: (attrs.startAngle * math.pi) / 180.0 + math.pi / 2,
          placement: isInside ? Placement.inside : Placement.outside,
          direction: attrs.direction,
          startAngleAlignment: StartAngleAlignment.center,
        ),
      );
    }

    var core = Container(
      decoration: new BoxDecoration(
        color: props.decorationColor,
        shape: BoxShape.circle,
        border: isDotted(borderStyle) ? null : props.border,
      ),
    );
    return Container(
      width: actualDiameter,
      height: actualDiameter,
      child: Stack(
        children: [
          isDotted(borderStyle)
              ? props.createDottedCircularBorder(child: core)
              : core,
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
  }
}

IconData getBorderStyleIcon(preferences.BorderStyle value) {
  switch (value) {
    case preferences.BorderStyle.solid:
      return Icons.horizontal_rule;
    case preferences.BorderStyle.dotted:
      return Icons.more_horiz;
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
    return value == null
        ? TextButton(
            child: multipleText,
            onPressed: () => onChanged(ControlLabelPosition.center),
          )
        : DropdownButton(
            value: value,
            items: ControlLabelPosition.values.map((value) {
              return new DropdownMenuItem(
                value: value,
                child: Text(getControlLabelPositionLabel(value)),
              );
            }).toList(),
            onChanged: onChanged,
          );
  }
}

class SizeConstrainedCheckbox extends StatelessWidget {
  final bool sizeConstrained;
  final Function(bool sizeConstrained) onChanged;

  const SizeConstrainedCheckbox({Key key, this.sizeConstrained, this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return sizeConstrained == null
        ? TextButton(
            child: multipleText,
            onPressed: () => onChanged(true),
          )
        : Checkbox(
            value: sizeConstrained,
            onChanged: (bool value) {
              onChanged(value);
            },
          );
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
    return angle == null
        ? TextButton(
            child: multipleText,
            onPressed: () => onChanged(0),
          )
        : Slider(
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

bool isDotted(preferences.BorderStyle style) {
  return style == preferences.BorderStyle.dotted;
}

T getValueIfAllEqual<T>(
  List<ControlData> controls,
  T Function(ControlData control) getValue,
) {
  final count = controls.length;
  if (count == 0) {
    return null;
  }
  final firstValue = getValue(controls.first);
  if (count == 1) {
    return firstValue;
  }
  final allEqualFirst = controls.every((c) => getValue(c) == firstValue);
  return allEqualFirst ? firstValue : null;
}
