import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:realearn_companion/model.dart';
import 'package:platform_detect/platform_detect.dart';

AppConfig configureApp() {
  setUrlStrategy(PathUrlStrategy());
  return AppConfig(useTls: !browser.isSafari);
}