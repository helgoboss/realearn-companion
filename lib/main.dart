import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:realearn_companion/model.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class CustomHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    var customContext = new SecurityContext(withTrustedRoots: false);
    // customContext.setTrustedCertificates("C:\\REAPER\\ReaLearn\\certs\\192.168.178.57.pem");
    var client = super.createHttpClient(customContext);
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return client;
  }
}

void main() {
  HttpOverrides.global = new CustomHttpOverrides();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);
    return MaterialApp(
      title: 'ReaLearn Companion',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(
        title: 'ReaLearn',
        channel: IOWebSocketChannel.connect(
            // 'ws://localhost:3030/?topics=/realearn/session/WGVPeHcA/controller,/realearn/session/WGVPeHcA/controller-routing'),
            'wss://uschi:3030/?topics=/realearn/session/WGVPeHcA/controller,/realearn/session/WGVPeHcA/controller-routing'),
        // 'wss://uschi:3030/?topics=/realearn/session/WGVPeHcA/controller,/realearn/session/WGVPeHcA/controller-routing'),
        // 'wss://echo.websocket.org'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, @required this.title, @required this.channel})
      : super(key: key);

  final String title;
  final WebSocketChannel channel;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  StreamSubscription _websocketSubscription;
  Controller _controller = null;
  ControllerRouting _routing = null;

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
      return Text("Controller or routing not yet set");
    }
    return Scaffold(
        // appBar: AppBar(
        //   title: Text(widget.title),
        // ),
        body: InteractiveViewer(
            panEnabled: false,
            // Set it to false to prevent panning.
            boundaryMargin: EdgeInsets.zero,
            minScale: 0.5,
            maxScale: 4,
            child: Container(
                child: controllerRoutingCanvas(_controller, _routing))));
  }
}

controllerRoutingCanvas(
    Controller controller, ControllerRouting controllerRouting) {
  var draggables = controller.mappings.map((m) {
    var route = controllerRouting.routes[m.id];
    return Control(controlLabel: m.name, targetLabel: route?.label ?? "");
  }).toList();
  return Stack(
    children: draggables,
  );
}

class Control extends StatefulWidget {
  final String controlLabel;
  final String targetLabel;

  Control({Key key, @required this.controlLabel, this.targetLabel})
      : super(key: key);

  @override
  _ControlState createState() => _ControlState();
}

enum ControlShape { rectangle, circle }

class _ControlState extends State<Control> {
  Offset _offset = Offset(0.0, 0.0);
  ControlShape _shape = ControlShape.circle;
  bool _isInEditMode = false;

  void reposition(Offset newOffset) {
    setState(() {
      _offset = newOffset;
    });
  }

  void adjustToGrid() {
    reposition(alignOffsetToGrid(_offset, 10, 10));
  }

  void changeShape(ControlShape newShape) {
    setState(() {
      _shape = newShape;
    });
  }

  @override
  Widget build(BuildContext context) {
    var container = Container(
        height: 50.0,
        width: 50.0,
        decoration: new BoxDecoration(
          color: Colors.orange,
          shape: mapControlShapeToBoxShape(_shape),
        ),
        child: FittedBox(
            fit: BoxFit.fitWidth,
            child: Text(getControlLabel(
                widget.controlLabel, widget.targetLabel, _isInEditMode))));
    var draggable = GestureDetector(
      onPanUpdate: (details) {
        reposition(Offset(
            _offset.dx + details.delta.dx, _offset.dy + details.delta.dy));
      },
      onPanEnd: (_) {
        adjustToGrid();
      },
      onTap: () {
        changeShape(getNextShape(_shape));
      },
      child: container,
    );
    return Positioned(top: _offset.dy, left: _offset.dx, child: draggable);
  }
}

String getControlLabel(
    String controlLabel, String targetLabel, bool isInEditMode) {
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
