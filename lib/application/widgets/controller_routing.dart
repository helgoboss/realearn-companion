import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/services.dart';
import 'package:flutter_arc_text/flutter_arc_text.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:realearn_companion/application/widgets/space.dart';
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
import 'semi_circle.dart';

var uuid = Uuid();

class ControllerRoutingPage extends StatefulWidget {
  final ConnectionData connectionData;

  const ControllerRoutingPage({Key? key, required this.connectionData})
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
    final controllerModel = this.context.read<ControllerModel>();
    final messengerState = ScaffoldMessenger.of(context);
    try {
      await ControllerRepository(widget.connectionData)
          .save(controllerModel.controller!);
      messengerState.showSnackBar(
        SnackBar(content: Text("Saved controller layout")),
      );
    } catch (err) {
      messengerState.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Couldn't save controller layout: \"$err\""),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    AppBar controllerRoutingAppBar(ControllerModel controllerModel,
        ControllerRoutingModel controllerRoutingModel, PageModel pageModel) {
      var theme = Theme.of(context);
      return AppBar(
          title: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(controllerRoutingModel.controllerRouting.mainPreset?.name ??
                  '<No main preset>'),
              SizedBox(width: 4, height: 4),
              Visibility(
                visible: true,
                child: Text(
                  controllerModel.controller?.name ?? '<No controller preset>',
                  style: TextStyle(
                    fontSize: 12.0,
                  ),
                ),
              ),
            ],
          ),
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

                    if (context.read<ControllerModel>().controllerHasEdits) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: theme.accentColor,
                          content:
                              Text("Don't forget to save once in a while!"),
                        ),
                      );
                    }
                  } else {
                    pageModel.enterEditMode();
                  }
                },
              ),
            PopupMenuButton(
              itemBuilder: (BuildContext context) {
                return <PopupMenuEntry>[
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
                            onChanged: (_) => prefs.toggleBackgroundImage(),
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
                  if (!pageModel.isInEditMode)
                    PopupMenuItem(
                      child: Consumer<AppPreferences>(
                        builder: (context, prefs, child) {
                          return CheckboxListTile(
                            value: prefs.feedbackEnabled,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (_) {
                              prefs.toggleFeedback();
                              if (prefs.feedbackEnabled) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    duration: Duration(milliseconds: 1500),
                                    backgroundColor: theme.accentColor,
                                    content: Text(
                                      "You might need to reconnect to see feedback!",
                                    ),
                                  ),
                                );
                              }
                            },
                            title: Text('Feedback'),
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
                              prefs.isFavoriteConnection(
                                      widget.connectionData.palette)
                                  ? Icons.star
                                  : Icons.star_border,
                            ),
                            onTap: () {
                              prefs.toggleFavoriteConnection(
                                  widget.connectionData.palette,
                                  controllerName:
                                      controllerModel.controller?.name);
                            },
                            title: Text('Favorite'),
                          );
                        },
                      ),
                    ),
                ];
              },
            ),
          ]);
    }

    final sessionId = widget.connectionData.sessionId;
    final sessionTopic = "/realearn/session/$sessionId";
    final controllerTopic = "/realearn/session/$sessionId/controller";
    final controllerRoutingTopic =
        "/realearn/session/$sessionId/controller-routing";
    final feedbackTopic = "/realearn/session/$sessionId/feedback";
    return ChangeNotifierProvider(
      create: (context) => PageModel(),
      child: Consumer3<ControllerModel, ControllerRoutingModel, PageModel>(
          builder: (context, controllerModel, controllerRoutingModel, pageModel,
              child) {
        final feedbackEnabled =
            context.select((AppPreferences prefs) => prefs.feedbackEnabled);
        final topics = [
          sessionTopic,
          controllerTopic,
          controllerRoutingTopic,
          if (feedbackEnabled) feedbackTopic
        ];
        return NormalScaffold(
          padding: EdgeInsets.zero,
          appBar: appBarIsVisible
              ? controllerRoutingAppBar(
                  controllerModel, controllerRoutingModel, pageModel)
              : null,
          child: ConnectionBuilder(
            connectionData: widget.connectionData,
            topics: topics,
            builder: (BuildContext context, Stream<dynamic> messages) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  toggleAppBar();
                },
                child: Container(
                  alignment: Alignment.center,
                  child: ControllerRoutingContainer(
                    messages: messages,
                  ),
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

  const LeadingMenuBarIcon(this.icon, {Key? key}) : super(key: key);

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
    Key? key,
    required this.messages,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ControllerRoutingContainerState();
  }
}

class ControllerRoutingContainerState
    extends State<ControllerRoutingContainer> {
  late StreamSubscription messagesSubscription;
  bool sessionExists = false;

  @override
  Widget build(BuildContext context) {
    final controllerRoutingModel = context.watch<ControllerRoutingModel>();
    return ControllerRoutingWidget(
      routing: controllerRoutingModel.controllerRouting,
      sessionExists: sessionExists,
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
      if (realearnEvent.path.endsWith("/feedback")) {
        final values = Map<String, double>.from(realearnEvent.body!);
        final controlValuesModel = context.read<ControlValuesModel>();
        if (realearnEvent.type == RealearnEventType.patch) {
          controlValuesModel.updateValues(values);
        } else {
          controlValuesModel.values = values;
        }
      } else if (realearnEvent.path.endsWith("/controller")) {
        final controllerModel = context.read<ControllerModel>();
        controllerModel.controller = realearnEvent.body == null
            ? null
            : Controller.fromJson(realearnEvent.body!);
      } else if (realearnEvent.path.endsWith("/controller-routing")) {
        final controllerRoutingModel = context.read<ControllerRoutingModel>();
        controllerRoutingModel.controllerRouting = realearnEvent.body == null
            ? ControllerRouting.empty()
            : ControllerRouting.fromJson(realearnEvent.body!);
      } else {
        setState(() {
          this.sessionExists = realearnEvent.body != null;
        });
      }
    });
  }

  @override
  void dispose() {
    messagesSubscription.cancel();
    super.dispose();
  }
}

var controlCanvasPadding = EdgeInsets.all(30);

class CanvasText extends StatelessWidget {
  final String label;
  final Widget? subText;

  const CanvasText(this.label, {Key? key, this.subText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final subText = this.subText;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.headline6,
          textAlign: TextAlign.center,
        ),
        Space(),
        if (subText != null) subText,
      ],
    );
  }
}

const minControllerWidth = defaultControlSize * 8;
const minControllerHeight = minControllerWidth;
const defaultFontSize = atomicSize * 2;

class ControllerRoutingWidget extends StatelessWidget {
  final ControllerRouting routing;
  final bool sessionExists;
  final GlobalKey stackKey = GlobalKey();

  ControllerRoutingWidget({
    Key? key,
    required this.routing,
    required this.sessionExists,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controllerModel = context.watch<ControllerModel>();
    final controller = controllerModel.controller;
    if (!sessionExists) {
      return CanvasText("Please open this ReaLearn session in REAPER!",
          subText: Text("or connect to another one"));
    }
    if (controller == null) {
      return CanvasText(
        "Please select a controller preset in ReaLearn!",
        subText: MarkdownBody(
          data: '**Show:** Controller compartment | **Controller preset:** ...',
        ),
      );
    }
    final pageModel = context.watch<PageModel>();
    if (!pageModel.isInEditMode && controller.controls.isEmpty) {
      return CanvasText(
        "Please create a controller layout!",
        subText: Text(
            "Just press the pencil button in the app bar and drag the controls on the canvas."),
      );
    }
    var isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    var controllerSize = controller.calcTotalSize();
    Widget createControlBag({required Axis direction}) {
      final remainingMappings = controller.mappings.where((m) {
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
                boundaryMargin: EdgeInsets.all(200),
                minScale: 0.25,
                maxScale: 8,
                clipBehavior: Clip.none,
                child: LayoutBuilder(builder:
                    (BuildContext context, BoxConstraints constraints) {
                  final controllerWidth =
                      math.max(minControllerWidth, controllerSize.width);
                  final controllerHeight =
                      math.max(minControllerHeight, controllerSize.height);
                  var widthScale = constraints.maxWidth / controllerWidth;
                  var heightScale = constraints.maxHeight / controllerHeight;
                  var scale = math.min(widthScale, heightScale);
                  var prefs = context.watch<AppPreferences>();
                  var controls = controller.controls.map((data) {
                    if (pageModel.isInEditMode) {
                      return EditableControl(
                        contents: data.mappings.map((mappingId) {
                          final name =
                              controller.findMappingById(mappingId)?.name;
                          return name == null
                              ? null
                              : ControlContent(label: name);
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
                          feedbackEnabled: prefs.feedbackEnabled);
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
                          clipBehavior: Clip.none,
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
                          width: controller.gridSize,
                          height: controller.gridSize,
                        );
                        vibrateMedium();
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

List<String?> getLabels(
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
      firstSourceDescriptors.isEmpty
          ? null
          : formatAsOneLabel(firstSourceDescriptors),
      secondSourceDescriptors.isEmpty
          ? null
          : formatAsOneLabel(secondSourceDescriptors),
    ];
  }
  // A control element must only exist if it has at least one mapping.
  // Control elements that represent more than 2 mappings are not possible at
  // the moment.
  throw UnsupportedError("control elements with no or more than 2 mappings");
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
  throw StateError("negative length impossible");
}

class ControlBag extends StatelessWidget {
  final List<Mapping> mappings;
  final GlobalKey stackKey;
  final Axis direction;

  const ControlBag({
    Key? key,
    required this.mappings,
    required this.stackKey,
    required this.direction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget createBag({required bool isAccepting}) {
      return Container(
        padding: EdgeInsets.all(10),
        width: direction == Axis.vertical ? 100 : null,
        height: direction == Axis.horizontal ? 100 : null,
        color: isAccepting ? Colors.grey.shade700 : Colors.grey.shade800,
        child: SingleChildScrollView(
          scrollDirection: direction,
          child: Flex(
            direction: direction,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: mappings.map((m) {
              Widget createPotentialControl({Color? fillColor}) {
                return Control(
                  contents: [ControlContent(label: m.name)],
                  width: 50,
                  height: 50,
                  shape: ControlShape.circle,
                  fillColor: fillColor,
                  fontColor: Colors.white,
                  borderStyle: preferences.BorderStyle.solid,
                );
              }

              var normalPotentialControl = createPotentialControl();
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Draggable<String>(
                  data: m.id,
                  childWhenDragging: createPotentialControl(
                    fillColor: Colors.grey,
                  ),
                  maxSimultaneousDrags: 1,
                  feedback: normalPotentialControl,
                  child: normalPotentialControl,
                  onDragStarted: () {
                    vibrateShortly();
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
        vibrateMedium();
      },
    );
  }
}

class EditableControl extends StatefulWidget {
  final List<ControlContent?> contents;
  final ControlData data;
  final double scale;
  final GlobalKey stackKey;
  final int gridSize;
  final ControllerModel controllerModel;
  final ControlAppearance appearance;
  final preferences.BorderStyle borderStyle;
  final int fontSize;

  const EditableControl({
    Key? key,
    required this.contents,
    required this.data,
    required this.scale,
    required this.stackKey,
    required this.gridSize,
    required this.controllerModel,
    required this.appearance,
    required this.borderStyle,
    required this.fontSize,
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
      contents: widget.contents,
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
      maxSimultaneousDrags: 1,
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
          if (data == null) {
            return false;
          }
          return data.mappings.length == 1 && widget.data.mappings.length == 1;
        },
        onAccept: (data) {
          if (pageModel.isInMultiEditMode) {
            return;
          }
          final controllerModel = context.read<ControllerModel>();
          controllerModel.uniteControls(widget.data, data);
          vibrateLong();
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
        vibrateShortly();
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
          vibrateShortly();
          if (pageModel.isInMultiEditMode) {
            pageModel.selectOrUnselectControl(widget.data.id);
          } else {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return createControlDialog(
                  context: context,
                  title: coreControl.contents[0]?.label ?? '',
                  controlIds: HashSet.of([widget.data.id]),
                );
              },
            );
          }
        },
        onLongPress: () {
          vibrateLong();
          if (pageModel.isInMultiEditMode) {
            if (!pageModel.controlIsSelected(widget.data.id)) {
              return;
            }
            vibrateShortly();
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

  const SettingRowLabel(this.label, {Key? key}) : super(key: key);

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
  required BuildContext context,
  required String title,
  required Set<String> controlIds,
  bool italic = false,
}) {
  final controllerModel = context.watch<ControllerModel>();
  final controls = controllerModel.findControlsByIds(controlIds).toList();
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
  final List<String?> labels;
  final ControlData data;
  final double scale;
  final ControlAppearance appearance;
  final preferences.BorderStyle borderStyle;
  final int fontSize;
  final bool feedbackEnabled;

  const FixedControl({
    Key? key,
    required this.labels,
    required this.data,
    required this.scale,
    required this.appearance,
    required this.borderStyle,
    required this.fontSize,
    required this.feedbackEnabled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: scale * data.y,
      left: scale * data.x,
      child: Control(
        height: data.height,
        width: data.width,
        contents: getContents(context),
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

  List<ControlContent?> getContents(BuildContext context) {
    if (feedbackEnabled) {
      final values =
          context.select((ControlValuesModel m) => m.getValues(data.mappings));
      var i = 0;
      return data.mappings.map((id) {
        final label = i < labels.length ? labels[i] : null;
        i += 1;
        if (label == null) {
          return null;
        }
        return ControlContent(label: label, value: values[id]);
      }).toList();
    } else {
      return labels
          .map((l) => l == null ? null : ControlContent(label: l))
          .toList();
    }
  }
}

class ControlContent {
  final String label;
  final double? value;

  ControlContent({required this.label, this.value});
}

class Control extends StatelessWidget {
  final int width;
  final int height;
  final List<ControlContent?> contents;
  final ControlShape shape;
  final Color? fillColor;
  final Color? fontColor;
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
    Key? key,
    this.contents = const [],
    required this.width,
    required this.height,
    this.shape = ControlShape.circle,
    this.fillColor = null,
    this.fontColor = null,
    this.scale = 1.0,
    this.labelOnePosition = ControlLabelPosition.aboveTop,
    this.labelOneAngle = 0,
    this.labelTwoPosition = ControlLabelPosition.belowBottom,
    this.labelTwoAngle = 0,
    this.appearance = ControlAppearance.filled,
    this.borderStyle = preferences.BorderStyle.dotted,
    this.fontSize = defaultFontSize,
    this.labelOneSizeConstrained = true,
    this.labelTwoSizeConstrained = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (shape == ControlShape.circle) {
      return CircularControl(
        diameter: width,
        appearance: appearance,
        contents: contents,
        labelOnePosition: labelOnePosition,
        labelOneSizeConstrained: labelOneSizeConstrained,
        labelOneAngle: labelOneAngle,
        labelTwoPosition: labelTwoPosition,
        labelTwoSizeConstrained: labelTwoSizeConstrained,
        labelTwoAngle: labelTwoAngle,
        scale: scale,
        fillColor: fillColor,
        fontColor: fontColor,
        borderStyle: borderStyle,
        fontSize: fontSize,
      );
    } else {
      return RectangularControl(
        width: width,
        height: height,
        appearance: appearance,
        contents: contents,
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
  final Color? enforcedFillColor;
  final Color? enforcedFontColor;
  final int fontSize;

  DerivedControlProps({
    required this.labelOneIsInside,
    required this.labelTwoIsInside,
    required this.appearance,
    required this.theme,
    required this.fontSize,
    this.enforcedFillColor,
    this.enforcedFontColor,
  });

  Color get mainColor => enforcedFillColor ?? theme.colorScheme.primary;

  Color get mainFeedbackColor {
    switch (appearance) {
      case ControlAppearance.outlined:
      case ControlAppearance.outlinedMono:
        return mainColor;
      case ControlAppearance.filled:
      case ControlAppearance.filledAndOutlined:
        return HSLColor.fromColor(mainColor).withLightness(0.4).toColor();
    }
  }

  Color get secondaryFeedbackColor {
    switch (appearance) {
      case ControlAppearance.outlinedMono:
      case ControlAppearance.filledAndOutlined:
        return theme.colorScheme.secondary;
      case ControlAppearance.filled:
      case ControlAppearance.outlined:
        switch (theme.brightness) {
          case Brightness.light:
            return theme.colorScheme.secondary;
          case Brightness.dark:
            return theme.colorScheme.onSurface;
        }
    }
  }

  BoxDecoration get mainFeedbackBoxDecoration {
    return new BoxDecoration(
      color: mainFeedbackColor,
    );
  }

  BoxDecoration get secondaryFeedbackBoxDecoration {
    return new BoxDecoration(
      color: secondaryFeedbackColor,
    );
  }

  TextStyle get baseTextStyle => TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: fontSize.toDouble(),
        fontFamily: "monospace",
      );

  TextStyle get labelOneTextStyle {
    return baseTextStyle.copyWith(color: enforcedFontColor ?? labelOneColor);
  }

  TextStyle get labelTwoTextStyle {
    return baseTextStyle.copyWith(
      color: enforcedFontColor ?? labelTwoColor,
      shadows: labelTwoTextShadows,
    );
  }

  List<Shadow> get textShadows {
    switch (theme.brightness) {
      case Brightness.light:
        return [];
      case Brightness.dark:
        return [
          Shadow(
            offset: Offset(1.0, 1.0),
            blurRadius: 5.0,
            color: theme.colorScheme.onPrimary,
          )
        ];
    }
  }

  List<Shadow> get labelTwoTextShadows {
    switch (appearance) {
      case ControlAppearance.outlined:
        return textShadows;
      case ControlAppearance.outlinedMono:
      case ControlAppearance.filled:
      case ControlAppearance.filledAndOutlined:
        return [];
    }
  }

  Color get labelOneColor {
    switch (appearance) {
      case ControlAppearance.outlinedMono:
        return theme.colorScheme.primary;
      case ControlAppearance.outlined:
      case ControlAppearance.filled:
      case ControlAppearance.filledAndOutlined:
        return labelOneIsInside && !strokeOnly
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface;
    }
  }

  Color get labelTwoColor {
    switch (appearance) {
      case ControlAppearance.outlinedMono:
        return labelTwoIsInside && !strokeOnly
            ? theme.colorScheme.onBackground
            : theme.colorScheme.secondary;
      case ControlAppearance.outlined:
      case ControlAppearance.filled:
      case ControlAppearance.filledAndOutlined:
        return labelTwoIsInside && !strokeOnly
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface;
    }
  }

  bool get strokeOnly {
    return appearance == ControlAppearance.outlined ||
        appearance == ControlAppearance.outlinedMono;
  }

  Color? get decorationColor => strokeOnly ? null : mainColor;

  BoxBorder? get border {
    switch (appearance) {
      case ControlAppearance.filled:
        return null;
      case ControlAppearance.filledAndOutlined:
      case ControlAppearance.outlined:
      case ControlAppearance.outlinedMono:
        return Border.all(width: strokeWidth, color: borderColor);
    }
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

  DottedBorder createDottedRectangleBorder({required Widget child}) {
    return createDottedBorder(child: child, borderType: BorderType.RRect);
  }

  Widget createNormalRectangleBorder({required Widget child}) {
    return Stack(
      children: <Widget>[
        child,
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              border: border,
              borderRadius: BorderRadius.all(borderRadius),
            ),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  DottedBorder createDottedCircularBorder({required Widget child}) {
    return createDottedBorder(child: child, borderType: BorderType.Circle);
  }

  DottedBorder createDottedBorder({
    required Widget child,
    required BorderType borderType,
  }) {
    return DottedBorder(
      color: borderColor,
      strokeWidth: strokeWidth,
      child: child,
      padding: EdgeInsets.zero,
      radius: borderRadius,
      borderType: borderType,
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

bool labelPositionIsInside(ControlLabelPosition? pos) {
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
  final List<ControlContent?> contents;
  final ControlLabelPosition labelOnePosition;
  final bool labelOneSizeConstrained;
  final int labelOneAngle;
  final ControlLabelPosition labelTwoPosition;
  final bool labelTwoSizeConstrained;
  final int labelTwoAngle;
  final double scale;
  final preferences.BorderStyle borderStyle;
  final int fontSize;

  const RectangularControl({
    Key? key,
    required this.appearance,
    required this.contents,
    required this.width,
    required this.height,
    required this.labelOnePosition,
    required this.labelOneSizeConstrained,
    required this.labelOneAngle,
    required this.labelTwoPosition,
    required this.labelTwoSizeConstrained,
    required this.labelTwoAngle,
    required this.scale,
    required this.borderStyle,
    required this.fontSize,
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
    final contentOne = contents.length > 0 ? contents[0] : null;
    final contentTwo = contents.length > 1 ? contents[1] : null;
    final scaledWidth = scale * width;
    final scaledHeight = scale * height;
    Positioned buildLabelText(
      String label, {
      required ControlLabelPosition position,
      required int angle,
      required bool sizeConstrained,
      required TextStyle style,
    }) {
      final attrs = _getAttributesForPosition(position);
      final child = createRotatedText(
        label,
        alignment: attrs.alignment,
        angle: angle,
        style: style,
        scale: scale,
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
        return createOuterRectangularText(
          controlWidth: scaledWidth,
          controlHeight: scaledHeight,
          expansionFactor: sizeConstrained ? 1 : 4,
          leftFactor: attrs.left,
          topFactor: attrs.top,
          child: child,
        );
      }
    }

    final valueOne = contents.length > 0 ? contents[0]?.value : null;
    final valueTwo = contents.length > 1 ? contents[1]?.value : null;
    final core = Container(
      clipBehavior: Clip.hardEdge,
      alignment: scaledWidth > scaledHeight
          ? Alignment.centerLeft
          : Alignment.bottomCenter,
      width: scaledWidth.toDouble(),
      height: scaledHeight.toDouble(),
      decoration: props.boxDecoration,
      child: valueOne == null && valueTwo == null
          ? null
          : Flex(
              direction:
                  scaledWidth > scaledHeight ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: scaledWidth > scaledHeight
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                if (valueOne != null)
                  Expanded(
                    child: Container(
                      height: scaledWidth > scaledHeight
                          ? null
                          : valueOne * scaledHeight.toDouble(),
                      width: scaledWidth > scaledHeight
                          ? valueOne * scaledWidth.toDouble()
                          : null,
                      decoration: props.mainFeedbackBoxDecoration,
                    ),
                  ),
                if (valueTwo != null)
                  Expanded(
                    child: Container(
                      height: scaledWidth > scaledHeight
                          ? null
                          : valueTwo * scaledHeight.toDouble(),
                      width: scaledWidth > scaledHeight
                          ? valueTwo * scaledWidth.toDouble()
                          : null,
                      decoration: props.secondaryFeedbackBoxDecoration,
                    ),
                  ),
              ],
            ),
    );
    return Stack(
      // We want to draw text outside of the stack's dimensions!
      clipBehavior: Clip.none,
      children: [
        isDotted(borderStyle)
            ? props.createDottedRectangleBorder(
                child: core,
              )
            : props.createNormalRectangleBorder(
                child: core,
              ),
        if (contentOne != null)
          buildLabelText(
            contentOne.label,
            position: labelOnePosition,
            angle: labelOneAngle,
            style: props.labelOneTextStyle,
            sizeConstrained: labelOneSizeConstrained,
          ),
        if (contentTwo != null)
          buildLabelText(
            contentTwo.label,
            position: labelTwoPosition,
            angle: labelTwoAngle,
            style: props.labelTwoTextStyle,
            sizeConstrained: labelTwoSizeConstrained,
          )
      ],
    );
  }
}

Positioned createOuterRectangularText({
  required Widget child,
  required int expansionFactor,
  required double controlWidth,
  required double controlHeight,
  required int leftFactor,
  required int topFactor,
}) {
  final expandedWidth = controlWidth.toDouble() * expansionFactor;
  final expandedHeight = controlHeight.toDouble() * expansionFactor;
  final centeredLeft = controlWidth / 2 - expandedWidth / 2;
  final centeredTop = controlHeight / 2 - expandedHeight / 2;
  final topShift = expandedHeight / 2 + controlHeight / 2;
  final leftShift = expandedWidth / 2 + controlWidth / 2;
  return Positioned(
    left: centeredLeft + leftFactor * leftShift,
    top: centeredTop + topFactor * topShift,
    width: expandedWidth,
    height: expandedHeight,
    child: child,
  );
}

Widget createRotatedText(
  String? label, {
  required AlignmentGeometry alignment,
  required int angle,
  required TextStyle style,
  required double scale,
}) {
  return Align(
    alignment: alignment,
    child: RotatedBox(
      quarterTurns: convertAngleToQuarterTurns(angle),
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: Text(
          label ?? "",
          textAlign: TextAlign.center,
          style: style,
          textScaleFactor: scale,
        ),
      ),
    ),
  );
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

  _PosAttrs({required this.top, required this.left, required this.alignment});
}

class CircularControl extends StatelessWidget {
  final int diameter;
  final ControlAppearance appearance;
  final List<ControlContent?> contents;
  final ControlLabelPosition labelOnePosition;
  final bool labelOneSizeConstrained;
  final int labelOneAngle;
  final ControlLabelPosition labelTwoPosition;
  final bool labelTwoSizeConstrained;
  final int labelTwoAngle;
  final double scale;
  final Color? fillColor;
  final Color? fontColor;
  final preferences.BorderStyle borderStyle;
  final int fontSize;

  const CircularControl({
    Key? key,
    required this.appearance,
    required this.contents,
    required this.diameter,
    required this.labelOnePosition,
    required this.labelOneSizeConstrained,
    required this.labelOneAngle,
    required this.labelTwoPosition,
    required this.labelTwoSizeConstrained,
    required this.labelTwoAngle,
    required this.scale,
    required this.borderStyle,
    required this.fontSize,
    this.fillColor,
    this.fontColor,
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
      enforcedFontColor: fontColor,
    );
    final scaledDiameter = scale * diameter;
    double actualDiameter = scaledDiameter;
    double scaledFontSize = fontSize * scale;
    Widget createCenterText(
      String? label, {
      required TextStyle style,
      required int angle,
    }) {
      return createRotatedText(
        label,
        alignment: Alignment.center,
        angle: angle,
        style: style,
        scale: scale,
      );
    }

    Widget createCircularText(
      String? label, {
      required ControlLabelPosition pos,
      required TextStyle style,
      required int angle,
    }) {
      final attrs = convertToCircularAttributes(pos, angle);
      final isInside = labelPositionIsInside(pos);
      return Align(
        child: ArcText(
          radius: (scaledDiameter / 2) + (isInside ? -1 : 1) * 1,
          text: label ?? "",
          textStyle:
              style.copyWith(fontSize: scaledFontSize, letterSpacing: -1),
          startAngle: (attrs.startAngle * math.pi) / 180.0 + math.pi / 2,
          placement: isInside ? Placement.inside : Placement.outside,
          direction: attrs.direction,
          startAngleAlignment: StartAngleAlignment.center,
        ),
      );
    }

    Widget createNonCenterText(
      String? label, {
      required ControlLabelPosition pos,
      required bool sizeConstrained,
      required TextStyle style,
      required int angle,
    }) {
      if (sizeConstrained || labelPositionIsInside(pos)) {
        return createCircularText(label, pos: pos, style: style, angle: angle);
      } else {
        final attrs = _getAttributesForPosition(pos);
        return createOuterRectangularText(
          controlWidth: scaledDiameter,
          controlHeight: scaledDiameter,
          expansionFactor: 4,
          leftFactor: attrs.left,
          topFactor: attrs.top,
          child: createRotatedText(
            label,
            alignment: attrs.alignment,
            angle: angle,
            style: style,
            scale: scale,
          ),
        );
      }
    }

    final valueOne = contents.length > 0 ? contents[0]?.value : null;
    final valueTwo = contents.length > 1 ? contents[1]?.value : null;
    var core = Container(
      decoration: new BoxDecoration(
        color: props.decorationColor,
        shape: BoxShape.circle,
        border: isDotted(borderStyle) ? null : props.border,
      ),
      child: valueOne == null
          ? null
          : Container(
              margin: EdgeInsets.all(0),
              child: SemiCircle(
                diameter: actualDiameter,
                degrees: valueOne * 360,
                color: props.mainFeedbackColor,
                fill: true,
              ),
            ),
    );
    return Container(
      width: actualDiameter,
      height: actualDiameter,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          isDotted(borderStyle)
              ? props.createDottedCircularBorder(child: core)
              : core,
          if (valueTwo != null)
            Container(
              margin: EdgeInsets.all(1),
              child: SemiCircle(
                diameter: actualDiameter,
                degrees: valueTwo * 360,
                color: props.secondaryFeedbackColor,
                fill: false,
              ),
            ),
          if (contents.length > 0)
            labelOnePosition == ControlLabelPosition.center
                ? createCenterText(
                    contents[0]?.label,
                    style: props.labelOneTextStyle,
                    angle: labelOneAngle,
                  )
                : createNonCenterText(
                    contents[0]?.label,
                    sizeConstrained: labelOneSizeConstrained,
                    pos: labelOnePosition,
                    style: props.labelOneTextStyle,
                    angle: labelOneAngle,
                  ),
          if (contents.length > 1)
            labelTwoPosition == ControlLabelPosition.center
                ? createCenterText(
                    contents[1]?.label,
                    style: props.labelTwoTextStyle,
                    angle: labelTwoAngle,
                  )
                : createNonCenterText(
                    contents[1]?.label,
                    sizeConstrained: labelTwoSizeConstrained,
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
  required int gridSize,
  required GlobalKey stackKey,
  required Offset globalPosition,
  required double scale,
}) {
  final RenderBox box =
      stackKey.currentContext!.findRenderObject() as RenderBox;
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

TableRow createSettingRow({required String label, required Widget child}) {
  return TableRow(
    children: [
      SettingRowLabel(label),
      Center(child: child),
    ],
  );
}

class MinusPlus extends StatelessWidget {
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  const MinusPlus({Key? key, this.onMinus, this.onPlus}) : super(key: key);

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
  final ControlLabelPosition? value;
  final Function(ControlLabelPosition pos) onChanged;

  const ControlLabelPositionDropdownButton(
      {Key? key, this.value, required this.onChanged})
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
            onChanged: (ControlLabelPosition? pos) {
              if (pos == null) {
                return;
              }
              onChanged(pos);
            },
          );
  }
}

class SizeConstrainedCheckbox extends StatelessWidget {
  final bool? sizeConstrained;
  final Function(bool sizeConstrained) onChanged;

  const SizeConstrainedCheckbox(
      {Key? key, this.sizeConstrained, required this.onChanged})
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
            onChanged: (bool? value) {
              if (value == null) {
                return;
              }
              onChanged(value);
            },
          );
  }
}

class RotationSlider extends StatelessWidget {
  final int? angle;
  final Function(int angle) onChanged;
  final bool onlyReverseAllowed;

  const RotationSlider({
    Key? key,
    this.angle,
    required this.onChanged,
    this.onlyReverseAllowed = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final a = angle;
    return a == null
        ? TextButton(
            child: multipleText,
            onPressed: () => onChanged(0),
          )
        : Slider(
            value: onlyReverseAllowed ? (a == 180 ? 180 : 0) : a.toDouble(),
            min: 0,
            max: onlyReverseAllowed ? 180 : 270,
            divisions: onlyReverseAllowed ? 1 : 3,
            label: '$a°',
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

  _CircularAttr({required this.startAngle, required this.direction});
}

bool isDotted(preferences.BorderStyle style) {
  return style == preferences.BorderStyle.dotted;
}

T? getValueIfAllEqual<T>(
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

void vibrateShortly() {
  Vibration.vibrate(duration: 50);
}

void vibrateMedium() {
  Vibration.vibrate(duration: 100);
}

void vibrateLong() {
  Vibration.vibrate(duration: 200);
}
