import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:realearn_companion/domain/connection.dart';
import 'package:realearn_companion/domain/model.dart';

class ControllerRepository {
  final ConnectionData connectionData;

  ControllerRepository(this.connectionData);

  void save(Controller controller) async {
    final r = await http.patch(
      connectionData.httpBaseUri
          .resolve('/realearn/controller/${controller.id}'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'op': 'replace',
        'path': '/customData/companion',
        'value': controller.customData.companion.toJson()
      }),
    );
    final isOkay = r.statusCode >= 200 &&
        r.statusCode < 300;
    if (!isOkay) {
      throw "${r.body} (status code ${r.statusCode})";
    }
  }
}
