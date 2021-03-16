// @dart=2.9
import 'application/app.dart';
import 'infrastructure/platform/stub/configure_app.dart'
    if (dart.library.html) 'infrastructure/platform/web/configure_app.dart'
    if (dart.library.io) 'infrastructure/platform/native/configure_app.dart';

void main(List<String> arguments) {
  App.run(config: configureApp(arguments));
}
