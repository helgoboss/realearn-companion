import 'package:flutter/material.dart';
import '../app.dart';
import 'normal_scaffold.dart';

class QrCodeScanWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var scan = App.instance.config.scanQrCode();
    return NormalScaffold(
      child: FutureBuilder<String>(
          future: scan.result,
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            if (snapshot.hasData) {
              return AlertDialog(
                title: Text("Continue?"),
                content: Text("Detected ${snapshot.data}"),
              );
            }
            return scan.widget;
          }),
    );
  }
}
