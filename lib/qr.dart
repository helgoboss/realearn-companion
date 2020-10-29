import 'dart:ui' as ui;
import 'dart:js' as js;
import 'dart:html' as html;
import 'package:flutter/material.dart';

class IFrameDemoPage extends StatefulWidget {
  @override
  _IFrameDemoPageState createState() => _IFrameDemoPageState();
}

class _IFrameDemoPageState extends State<IFrameDemoPage> {
  html.IFrameElement _element;
  js.JsObject _connector;

  @override
  void initState() {
    super.initState();

    js.context["connect_content_to_flutter"] = (content) {
      _connector = content;
    };

    _element = html.IFrameElement()
      ..style.border = 'none'
      ..srcdoc = """
        <!DOCTYPE html>
          <head>
            <script src="qr-scanner.umd.min.js"></script>
          </head>
          <body>
            <video id="qr-code-video"></video>
            <script>
              const videoElement = document.getElementById("qr-code-video");
              const qrScanner = new QrScanner(
                videoElement, 
                result => {
                  alert('decoded qr code: ' + result);
                  qrScanner.stop();
                }
              );
                
              // variant 1
              parent.connect_content_to_flutter && parent.connect_content_to_flutter(window)
              function hello(msg) {
                qrScanner.start().catch(console.log);
              }

              // variant 2
              window.addEventListener("message", (message) => {
                if (message.data.id === "test") {
                  qrScanner.start().catch(console.log);
                }
              })
            </script>
          </body>
        </html>
        """;

    // ignore:undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'example',
          (int viewId) => _element,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.filter_1),
            tooltip: 'Test with connector',
            onPressed: () {
              _connector.callMethod('hello', ['Hello from first variant']);
            },
          ),
          IconButton(
            icon: Icon(Icons.filter_2),
            tooltip: 'Test with postMessage',
            onPressed: () {
              _element.contentWindow.postMessage({
                'id': 'test',
                'msg': 'Hello from second variant',
              }, "*");
            },
          )
        ],
      ),
      body: Container(
        child: HtmlElementView(viewType: 'example'),
      ),
    );
  }
}
