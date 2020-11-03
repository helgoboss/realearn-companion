import 'dart:async';
import 'dart:html';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:realearn_companion/application/app_config.dart';

class WebQrCodeScan extends QrCodeScan {
  final Completer<String> resultCompleter = new Completer();

  @override
  WebQrCodeScannerWidget widget;

  WebQrCodeScan() {
    widget = new WebQrCodeScannerWidget(
        callback: (value) => resultCompleter.complete(value));
  }

  @override
  Future<String> get result {
    return resultCompleter.future;
  }
}

class WebQrCodeScannerWidget extends StatefulWidget {
  final Function(String) callback;

  const WebQrCodeScannerWidget({Key key, @required this.callback})
      : super(key: key);

  @override
  _WebQrCodeScannerWidgetState createState() => _WebQrCodeScannerWidgetState();
}

class _WebQrCodeScannerWidgetState extends State<WebQrCodeScannerWidget> {
  IFrameElement _element;

  @override
  void initState() {
    super.initState();
    window.addEventListener("message", (event) {
      var evt = event as MessageEvent;
      widget.callback(evt.data['data']);
    });
    _element = IFrameElement()
      ..style.border = 'none'
      ..srcdoc = """
<!DOCTYPE html>
<html>

<head>
    <meta charset="utf-8">
    <script src="./jsQR.js"></script>
    <style>
        canvas {
            width: 100%;
        }
    </style>
</head>

<body>
    <canvas id="canvas" hidden></canvas>
    <script>
        var video = document.createElement("video");
        var canvasElement = document.getElementById("canvas");
        var canvas = canvasElement.getContext("2d");
        navigator.mediaDevices.getUserMedia({ video: { facingMode: "environment" } }).then(function (stream) {
            video.srcObject = stream;
            video.play();
            requestAnimationFrame(tick);
        });
        function tick() {
            if (video.readyState === video.HAVE_ENOUGH_DATA) {
                canvasElement.hidden = false;
                canvasElement.height = video.videoHeight;
                canvasElement.width = video.videoWidth;
                canvas.drawImage(video, 0, 0, canvasElement.width, canvasElement.height);
                var imageData = canvas.getImageData(0, 0, canvasElement.width, canvasElement.height);
                var code = jsQR(imageData.data, imageData.width, imageData.height, {
                    inversionAttempts: "dontInvert",
                });
                if (code) {
                    window.parent.postMessage(code, "*");
                } else {
                  requestAnimationFrame(tick);
                }
            } else {
              requestAnimationFrame(tick);
            }
        }
    </script>
</body>

</html>
        """;

    ui.platformViewRegistry.registerViewFactory(
      'qr-scanner',
      (int viewId) => _element,
    );
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: 'qr-scanner');
  }
}
