import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:realearn_companion/application/app_config.dart';
import 'package:realearn_companion/application/routes.dart';

import '../app.dart';

class ScanConnectionDataWidget extends StatelessWidget {
  final QrCodeScan qrCodeScan;

  const ScanConnectionDataWidget({super.key, required this.qrCodeScan});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: qrCodeScan.result,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            cancelScanning(
              context,
              "Sorry, QR code scanning is temporarily disabled. It will come back in later versions.",
              isError: true,
            );
          } else if (snapshot.hasData) {
            if (snapshot.data?.isEmpty ?? true) {
              cancelScanning(context, "Cancelled scanning QR code");
            } else {
              try {
                var uri = Uri.parse(snapshot.data!);
                var connectionArgs = ConnectionArgs.fromParams(uri.queryParametersAll);
                if (connectionArgs.isComplete) {
                  handleSuccess(context, connectionArgs);
                } else {
                  handleWrongQrCode(context);
                }
              } on FormatException catch (_) {
                handleWrongQrCode(context);
              }
            }
          }
        }
        return qrCodeScan.widget;
      },
    );
  }
}

void handleSuccess(BuildContext context, ConnectionArgs connectionArgs) {
  WidgetsBinding.instance!.addPostFrameCallback((_) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      getControllerRoutingRoute(connectionArgs),
      ModalRoute.withName(rootRoute),
    );
  });
}

void handleWrongQrCode(BuildContext context) {
  continueOrCancelScanning(
    context: context,
    summary: "Wrong QR code",
    msg: "This doesn't look like a QR code from ReaLearn.",
  );
}

void continueOrCancelScanning({
  required BuildContext context,
  required String summary,
  required String msg,
}) {
  WidgetsBinding.instance!.addPostFrameCallback((_) {
    var dialog = AlertDialog(
      title: Text(summary),
      content: Text(msg),
      actions: [
        TextButton(
          child: Text("Cancel"),
          onPressed: () {
            cancelScanning(context, "Cancelled scanning QR code");
          },
        ),
        TextButton(
          child: Text("Continue"),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              scanConnectionDataRoute,
              ModalRoute.withName(rootRoute),
            );
          },
        ),
      ],
    );
    showDialog(context: context, builder: (BuildContext context) => dialog);
  });
}

void cancelScanning(BuildContext context, String msg, {bool isError = false}) {
  WidgetsBinding.instance!.addPostFrameCallback((_) {
    var snackBar = SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : null);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    Navigator.popUntil(context, ModalRoute.withName(rootRoute));
  });
}
