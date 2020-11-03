import 'package:flutter/material.dart';
import 'package:realearn_companion/application/routes.dart';
import '../app.dart';

class ScanConnectionDataWidget extends StatelessWidget {
  final Widget scannerWidget;
  final Future<String> result;

  const ScanConnectionDataWidget({Key key, this.scannerWidget, this.result})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
        future: result,
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasError) {
            cancelScanning(context, "Couldn't scan QR code", isError: true);
          } else if (snapshot.hasData) {
            if (snapshot.data == null || snapshot.data.isEmpty) {
              cancelScanning(context, "Cancelled scanning QR code");
            } else {
              try {
                var uri = Uri.parse(snapshot.data);
                var connectionArgs =
                    ConnectionArgs.fromParams(uri.queryParametersAll);
                if (!connectionArgs.isComplete) {
                  handleWrongQrCode(context);
                }
                handleSuccess(context, connectionArgs);
              } on FormatException catch (_) {
                handleWrongQrCode(context);
              }
            }
          }
          return scannerWidget;
        });
  }
}

void handleSuccess(BuildContext context, ConnectionArgs connectionArgs) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    App.instance.router.navigateTo(
        context, "$controllerRoutingRoute?${connectionArgs.toQueryString()}",
        replace: true);
  });
}

void handleWrongQrCode(BuildContext context) {
  continueOrCancelScanning(
      context: context,
      summary: "Wrong QR code",
      msg: "This doesn't look like a QR code from ReaLearn.");
}

void continueOrCancelScanning({
  BuildContext context,
  String summary,
  String msg,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    var dialog = AlertDialog(
      title: Text(summary),
      content: Text(msg),
      actions: [
        FlatButton(
          child: Text("Cancel"),
          onPressed: () {
            App.instance.router.pop(context);
            cancelScanning(context, "Cancelled scanning QR code");
          },
        ),
        FlatButton(
          child: Text("Continue"),
          onPressed: () {
            App.instance.router.pop(context);
            App.instance.router
                .navigateTo(context, scanConnectionDataRoute, replace: true);
          },
        ),
      ],
    );
    showDialog(context: context, builder: (BuildContext context) => dialog);
  });
}

void cancelScanning(BuildContext context, String msg, {bool isError = false}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    var snackBar = SnackBar(
        content: Text(msg), backgroundColor: isError ? Colors.red : null);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    App.instance.router.pop(context);
  });
}
