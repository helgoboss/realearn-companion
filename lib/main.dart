import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:realearn_companion/model.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'configure_nonweb.dart' if (dart.library.html) 'configure_web.dart';
import 'package:fluro/fluro.dart';

void main() {
  Application.config = configureApp();
  runApp(MyApp());
}

class Application {
  static FluroRouter router;
  static AppConfig config;
}

var rootHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
      final args = MainArguments(
        host: params['host']?.first,
        httpPort: params['http-port']?.first,
        httpsPort: params['https-port']?.first,
        sessionId: params['session-id']?.first,
      );
      if (!args.isValid()) {
        return Text("Invalid arguments");
      }
      return MyHomeContainer(args: args);
    });

class Routes {
  static String controllerRouting = "/controller-routing";

  static void configureRoutes(FluroRouter router) {
    router.notFoundHandler = Handler(
        handlerFunc: (BuildContext context, Map<String, List<String>> params) {
          print("ROUTE WAS NOT FOUND !!!");
          return Text("Route doesn't exist");
        });
    router.define(controllerRouting, handler: rootHandler);
  }
}

bool isLocalhost(String host) {
  return host == "localhost" || host == "127.0.0.1";
}

class MyApp extends StatefulWidget {
  MyApp();


  @override
  State createState() {
    return MyAppState();
  }
}

class MyAppState extends State<MyApp> {
  MyAppState() {
    final router = FluroRouter();
    Routes.configureRoutes(router);
    Application.router = router;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);
    return MaterialApp(
      title: 'ReaLearn Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      onGenerateRoute: Application.router.generator,
    );
  }
}

class MyHomeContainer extends StatelessWidget {
  final MainArguments args;

  MyHomeContainer({@required this.args});

  @override
  Widget build(BuildContext context) {
    var host = args.host;
    var useTls = Application.config.useTls && !isLocalhost(host);
    var wsProtocol = useTls ? "wss" : "ws";
    var httpProtocol = useTls ? "https" : "http";
    var port = useTls ? args.httpsPort : args.httpPort;
    var sessionId = args.sessionId;
    var controllerTopic = "/realearn/session/$sessionId/controller";
    var controllerRoutingTopic =
        "/realearn/session/$sessionId/controller-routing";
    var wsBaseUri = Uri.parse("$wsProtocol://$host:$port");
    var wsUri =
    wsBaseUri.resolve("/ws?topics=$controllerTopic,$controllerRoutingTopic");
    var httpBaseUri = Uri.parse("$httpProtocol://$host:$port");
    return MyHomePage(
      title: 'ReaLearn',
      channel: WebSocketChannel.connect(wsUri),
      httpBaseUri: httpBaseUri,
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  final WebSocketChannel channel;
  final Uri httpBaseUri;

  MyHomePage({Key key,
    @required this.title,
    @required this.channel,
    @required this.httpBaseUri})
      : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  StreamSubscription _websocketSubscription;
  Controller _controller = null;
  ControllerRouting _routing = null;

  void _saveControllerData() {
    http.patch(
      widget.httpBaseUri.resolve('/realearn/controller/${_controller.id}'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'op': 'replace',
        'path': '/customData/companion',
        'value': _controller.customData.companion.toJson()
      }),
    );
  }

  void _updateController(Controller controller) {
    setState(() {
      _controller = controller;
    });
  }

  void _updateRouting(ControllerRouting routing) {
    setState(() {
      _routing = routing;
    });
  }

  @override
  void initState() {
    super.initState();
    _websocketSubscription = widget.channel.stream.listen((data) {
      var jsonObject = jsonDecode(data);
      var realearnEvent = RealearnEvent.fromJson(jsonObject);
      if (realearnEvent.type == "updated") {
        if (realearnEvent.path.endsWith("/controller")) {
          _updateController(Controller.fromJson(realearnEvent.payload));
        } else if (realearnEvent.path.endsWith("/controller-routing")) {
          _updateRouting(ControllerRouting.fromJson(realearnEvent.payload));
        }
      }
    });
  }

  @override
  void dispose() {
    _websocketSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || _routing == null) {
      return Text(widget.httpBaseUri.toString());
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: InteractiveViewer(
        panEnabled: false,
        // Set it to false to prevent panning.
        boundaryMargin: EdgeInsets.zero,
        minScale: 0.5,
        maxScale: 4,
        child: Container(
          child: controllerRoutingCanvas(
            controller: _controller,
            routing: _routing,
            onControlDataUpdate: (mappingId, data) {
              setState(() {
                _controller.updateControlData(mappingId, data);
              });
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveControllerData,
        tooltip: 'Save',
        child: Icon(Icons.save),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

controllerRoutingCanvas({Controller controller,
  ControllerRouting routing,
  Function(String, ControlData) onControlDataUpdate}) {
  var draggables = controller.mappings.map((m) {
    var route = routing.routes[m.id];
    var data = controller.findControlData(m.id) ?? ControlData(x: 0.0, y: 0.0);
    return Control(
      controlLabel: m.name,
      targetLabel: route?.label ?? "",
      data: data,
      onControlDataUpdate: (data) {
        onControlDataUpdate(m.id, data);
      },
    );
  }).toList();
  return Stack(
    children: draggables,
  );
}

class Control extends StatefulWidget {
  // TODO-low Is it good to make those members public?
  final String controlLabel;
  final String targetLabel;
  final ControlData data;
  final Function(ControlData) onControlDataUpdate;

  // TODO-low Lookup this shortcut constructor syntax. Does it work with private members, too?
  Control({
    Key key,
    @required this.controlLabel,
    @required this.targetLabel,
    @required this.data,
    @required this.onControlDataUpdate,
  }) : super(key: key);

  @override
  _ControlState createState() => _ControlState();
}

class _ControlState extends State<Control> {
  Offset _dragOffset = null;

  // TODO-low Put into widget props
  bool _isInEditMode = false;

  void onDragStart() {
    setState(() {
      _dragOffset = widgetOffset();
    });
  }

  Offset widgetOffset() => Offset(widget.data.x, widget.data.y);

  void onDrag(Offset newOffset) {
    setState(() {
      _dragOffset = newOffset;
    });
  }

  void onDragEnd() {
    var alignedToGrid = alignOffsetToGrid(_dragOffset, 10, 10);
    setState(() {
      _dragOffset = null;
    });
    notifyControlDataChanged(x: alignedToGrid.dx, y: alignedToGrid.dy);
  }

  void changeShape(ControlShape newShape) {
    notifyControlDataChanged(shape: newShape);
  }

  void notifyControlDataChanged({ControlShape shape, double x, double y}) {
    widget.onControlDataUpdate(ControlData(
      shape: shape ?? widget.data.shape,
      x: x ?? widget.data.x,
      y: y ?? widget.data.y,
    ));
  }

  @override
  Widget build(BuildContext context) {
    var container = Container(
        height: 50.0,
        width: 50.0,
        decoration: new BoxDecoration(
          color: Colors.green,
          shape: mapControlShapeToBoxShape(
              widget.data.shape ?? ControlShape.circle),
        ),
        child: FittedBox(
            fit: BoxFit.none,
            clipBehavior: Clip.none,
            child: Text(getControlLabel(
                widget.controlLabel, widget.targetLabel, _isInEditMode))));
    var draggable = GestureDetector(
      onPanStart: (_) {
        onDragStart();
      },
      onPanUpdate: (details) {
        onDrag(Offset(_dragOffset.dx + details.delta.dx,
            _dragOffset.dy + details.delta.dy));
      },
      onPanEnd: (_) {
        onDragEnd();
      },
      onTap: () {
        // TODO-medium Introduce shape and x and y getters
        changeShape(getNextShape(widget.data.shape ?? ControlShape.circle));
      },
      child: container,
    );
    var effectiveOffset = _dragOffset ?? widgetOffset();
    return Positioned(
        top: effectiveOffset.dy, left: effectiveOffset.dx, child: draggable);
  }
}

String getControlLabel(String controlLabel, String targetLabel,
    bool isInEditMode) {
  if (isInEditMode) {
    return controlLabel;
  } else {
    if (targetLabel == null) {
      return '';
    } else {
      return targetLabel;
    }
  }
}

ControlShape getNextShape(ControlShape controlShape) {
  return ControlShape
      .values[(controlShape.index + 1) % ControlShape.values.length];
}

BoxShape mapControlShapeToBoxShape(ControlShape controlShape) {
  switch (controlShape) {
    case ControlShape.circle:
      return BoxShape.circle;
    case ControlShape.rectangle:
      return BoxShape.rectangle;
  }
}

// Widget sessionProjectionListView(SessionProjection sessionProjection) {
//   var tiles = sessionProjection.mappingProjections
//       .where((p) => p.targetProjection != null)
//       .map((p) => ListTile(
//             leading: Icon(Icons.map),
//             title: Text('${p.name} → ${p.targetProjection.label}'),
//           ))
//       .toList();
//   return ListView(
//     children: tiles,
//   );
// }

Offset alignOffsetToGrid(Offset offset, double xGridSize, double yGridSize) {
  return Offset(roundNumberToGridSize(offset.dx, xGridSize),
      roundNumberToGridSize(offset.dy, yGridSize));
}

double roundNumberToGridSize(double number, double gridSize) {
  return (number / gridSize).roundToDouble() * gridSize;
}
