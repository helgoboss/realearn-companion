import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../application/app_config.dart';

AppConfig configureApp(List<String> arguments) {
  HttpOverrides.global = new _CustomHttpOverrides();
  return _NativeAppConfig(
    securityPlatform: getNativeSecurityPlatform(),
    initialRoute: arguments.isEmpty ? null : arguments[0],
  );
}

SecurityPlatform getNativeSecurityPlatform() {
  if (Platform.isAndroid) {
    return SecurityPlatform.Android;
  }
  if (Platform.isLinux) {
    return SecurityPlatform.Linux;
  }
  if (Platform.isWindows) {
    return SecurityPlatform.Windows;
  }
  if (Platform.isIOS) {
    return SecurityPlatform.iOS;
  }
  if (Platform.isMacOS) {
    return SecurityPlatform.macOS;
  }
  throw UnsupportedError("unknown native security platform");
}

class _NativeAppConfig implements AppConfig {
  final SecurityPlatform securityPlatform;
  final String? initialRoute;

  _NativeAppConfig({required this.securityPlatform, this.initialRoute});

  TlsPolicy get tlsPolicy {
    switch (securityPlatform) {
      case SecurityPlatform.Android:
        return TlsPolicy.remoteOnly;
      case SecurityPlatform.iOS:
        return TlsPolicy.remoteOnly;
      case SecurityPlatform.Windows:
        return TlsPolicy.remoteOnly;
      case SecurityPlatform.Linux:
        return TlsPolicy.remoteOnly;
      case SecurityPlatform.macOS:
        return TlsPolicy.remoteOnly;
    }
  }

  @override
  NativeQrCodeScan scanQrCode(BuildContext context) {
    return NativeQrCodeScan();
  }

  @override
  Future<bool> deviceHasCamera() async {
    var cameras = await availableCameras();
    return !cameras.isEmpty;
  }

  @override
  Uri? createCertObjectUrl(String content) {
    // This shouldn't be necessary anyway in a native app because we can choose
    // to be fine with a self-signed certificate (at least on Android).
    return null;
  }

  @override
  Widget svgImage(
    String assetPath, {
    required Color color,
    required BoxFit fit,
    required double width,
    required double height,
  }) {
    return SvgPicture.asset(assetPath, color: color, fit: fit, width: width, height: height);
  }
}

class _CustomHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    var customContext = new SecurityContext(withTrustedRoots: false);
    // customContext.setTrustedCertificates("realearn.cer");
    var client = super.createHttpClient(customContext);
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      return true;
    };
    return client;
  }
}

class NativeQrCodeScan extends QrCodeScan {
  final _completer = Completer<String>();

  @override
  late final Future<String> result = _completer.future;

  @override
  late final Widget widget = _NativeQrCodeScanWidget(
    onCodeDetected: (code) {
      if (_completer.isCompleted) {
        return;
      }
      _completer.complete(code);
    },
  );
}

class _NativeQrCodeScanWidget extends StatefulWidget {
  final void Function(String code) onCodeDetected;

  const _NativeQrCodeScanWidget({super.key, required this.onCodeDetected});

  @override
  State<_NativeQrCodeScanWidget> createState() => _NativeQrCodeScanWidgetState();
}

class _NativeQrCodeScanWidgetState extends State<_NativeQrCodeScanWidget>
    with WidgetsBindingObserver {
  final MobileScannerController controller = MobileScannerController();
  StreamSubscription<Object?>? _subscription;

  @override
  void initState() {
    super.initState();
    // Start listening to lifecycle changes.
    WidgetsBinding.instance.addObserver(this);

    // Start listening to the barcode events.
    _subscription = controller.barcodes.listen(_handleBarcode);

    // Finally, start the scanner itself.
    unawaited(controller.start());
  }

  @override
  Future<void> dispose() async {
    // Stop listening to lifecycle changes.
    WidgetsBinding.instance.removeObserver(this);
    // Stop listening to the barcode events.
    unawaited(_subscription?.cancel());
    _subscription = null;
    // Dispose the widget itself.
    super.dispose();
    // Finally, dispose of the controller.
    await controller.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the controller is not ready, do not try to start or stop it.
    // Permission dialogs can trigger lifecycle changes before the controller is ready.
    if (!controller.value.hasCameraPermission) {
      return;
    }
    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        // Restart the scanner when the app is resumed.
        // Don't forget to resume listening to the barcode events.
        _subscription = controller.barcodes.listen(_handleBarcode);

        unawaited(controller.start());
      case AppLifecycleState.inactive:
        // Stop the scanner when the app is paused.
        // Also stop the barcode events subscription.
        unawaited(_subscription?.cancel());
        _subscription = null;
        unawaited(controller.stop());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MobileScanner(controller: controller);
  }

  void _handleBarcode(BarcodeCapture cap) {
    final barcode = cap.barcodes.elementAtOrNull(0);
    if (barcode == null) {
      return;
    }
    final rawValue = barcode.rawValue;
    if (rawValue == null) {
      return;
    }
    widget.onCodeDetected(rawValue);
  }
}
