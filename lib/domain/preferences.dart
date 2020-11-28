import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:realearn_companion/domain/connection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

part 'preferences.g.dart';

@JsonSerializable(nullable: true)
class AppPreferences extends ChangeNotifier {
  List<RecentConnection> recentConnections;
  ThemeMode themeMode;
  bool highContrastEnabled;
  bool backgroundImageEnabled;
  bool gridEnabled;
  ControlAppearance controlAppearance;
  BorderStyle borderStyle;
  int fontSize;

  static Future<AppPreferences> load() async {
    var prefs = await SharedPreferences.getInstance();
    var jsonString = await prefs.getString('preferences');
    if (jsonString == null) {
      return AppPreferences();
    }
    var jsonMap = jsonDecode(jsonString);
    return AppPreferences.fromJson(jsonMap);
  }

  factory AppPreferences.fromJson(Map<String, dynamic> json) =>
      _$AppPreferencesFromJson(json);

  AppPreferences({
    List<RecentConnection> recentConnections,
    ThemeMode themeMode,
    bool highContrastEnabled,
    bool backgroundImageEnabled,
    bool gridEnabled,
    ControlAppearance controlAppearance,
    BorderStyle borderStyle,
    int fontSize,
  })  : recentConnections = recentConnections ?? [],
        themeMode = themeMode ?? ThemeMode.dark,
        highContrastEnabled = highContrastEnabled ?? false,
        backgroundImageEnabled = backgroundImageEnabled ?? true,
        gridEnabled = gridEnabled ?? true,
        controlAppearance = controlAppearance ?? ControlAppearance.outlinedMono,
        borderStyle = borderStyle ?? BorderStyle.dotted,
        fontSize = fontSize ?? 14;

  Map<String, dynamic> toJson() => _$AppPreferencesToJson(this);

  void switchThemeMode() {
    themeMode = getNextThemeMode(themeMode);
    _notifyAndSave();
  }

  void toggleHighContrast() {
    highContrastEnabled = !highContrastEnabled;
    _notifyAndSave();
  }

  void toggleBackgroundImage() {
    backgroundImageEnabled = !backgroundImageEnabled;
    _notifyAndSave();
  }

  void toggleGrid() {
    gridEnabled = !gridEnabled;
    _notifyAndSave();
  }

  void switchControlAppearance() {
    controlAppearance = getNextControlAppearance(controlAppearance);
    _notifyAndSave();
  }

  void switchBorderStyle() {
    borderStyle = getNextBorderStyle(borderStyle);
    _notifyAndSave();
  }

  void adjustFontSizeBy(int amount) {
    fontSize = math.max(8, fontSize + amount);
    _notifyAndSave();
  }

  // Can be null
  ConnectionDataPalette get lastConnection {
    if (recentConnections.isEmpty) {
      return null;
    }
    return recentConnections.first.toPalette();
  }

  void memorizeAsLastConnection(ConnectionDataPalette palette) {
    // Maybe we want to save multiple recent connections in future so we use a
    // list of exactly one connection.
    recentConnections = [RecentConnection.fromPalette(palette)];
    _notifyAndSave();
  }

  void _notifyAndSave() {
    notifyListeners();
    _save();
  }

  void _save() async {
    var jsonMap = toJson();
    var jsonString = jsonEncode(jsonMap);
    var prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferences', jsonString);
  }
}

enum ControlAppearance {
  filled,
  outlined,
  filledAndOutlined,
  outlinedMono,
}

enum BorderStyle {
  solid,
  dotted,
}

ThemeMode getNextThemeMode(ThemeMode value) {
  return ThemeMode.values[(value.index + 1) % ThemeMode.values.length];
}

ControlAppearance getNextControlAppearance(ControlAppearance value) {
  return ControlAppearance
      .values[(value.index + 1) % ControlAppearance.values.length];
}

BorderStyle getNextBorderStyle(BorderStyle value) {
  return BorderStyle.values[(value.index + 1) % BorderStyle.values.length];
}

@JsonSerializable(nullable: true)
class RecentConnection {
  final String host;
  final String httpPort;
  final String httpsPort;
  final String sessionId;
  final String certContent;

  RecentConnection({
    this.host,
    this.httpPort,
    this.httpsPort,
    this.sessionId,
    this.certContent,
  });

  factory RecentConnection.fromJson(Map<String, dynamic> json) =>
      _$RecentConnectionFromJson(json);

  Map<String, dynamic> toJson() => _$RecentConnectionToJson(this);

  factory RecentConnection.fromPalette(ConnectionDataPalette palette) {
    return RecentConnection(
      host: palette.host,
      httpPort: palette.httpPort,
      httpsPort: palette.httpsPort,
      sessionId: palette.sessionId,
      certContent: palette.certContent,
    );
  }

  ConnectionDataPalette toPalette() {
    return ConnectionDataPalette(
      host: host,
      httpPort: httpPort,
      httpsPort: httpsPort,
      sessionId: sessionId,
      // Recent connections are only saved as recent connection if we already
      // managed to successfully connect. So there's no possibility for typos.
      isGenerated: true,
      certContent: certContent,
    );
  }
}
