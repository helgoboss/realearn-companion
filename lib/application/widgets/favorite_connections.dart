import 'package:flutter/material.dart';
import 'package:realearn_companion/domain/connection.dart';
import 'package:realearn_companion/domain/preferences.dart';
import 'package:provider/provider.dart';

import '../routes.dart';
import 'normal_scaffold.dart';
import 'space.dart';

class FavoriteConnectionsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<AppPreferences>();
    final connections = prefs.favoriteConnections.toList();
    return NormalScaffold(
        appBar: NormalScaffold.defaultAppBar(),
        child: ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: connections.length,
          itemBuilder: (BuildContext context, int index) {
            final con = connections[index];
            return ListTile(
              title: Text("${con.controllerName ?? 'Unknown controller'}"),
              subtitle: Text("${con.sessionId} on ${con.host}"),
              onTap: () {
                final args = ConnectionArgs.fromPalette(con.toPalette());
                Navigator.pushNamed(context, getControllerRoutingRoute(args));
              },
            );
          },
          separatorBuilder: (BuildContext context, int index) => Divider(),
        ));
  }
}
