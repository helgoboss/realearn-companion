import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:realearn_companion/domain/connection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

part 'preferences.g.dart';

@JsonSerializable()
class AppPreferences extends ChangeNotifier {
  List<RecentConnection> recentConnections;
  LinkedHashSet<RecentConnection> favoriteConnections;
  ThemeMode themeMode;
  bool highContrastEnabled;
  bool backgroundImageEnabled;
  bool gridEnabled;
  ControlAppearance controlAppearance;
  BorderStyle borderStyle;
  int fontSize;
  bool feedbackEnabled;

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
    List<RecentConnection>? recentConnections,
    List<RecentConnection>? favoriteConnections,
    ThemeMode? themeMode,
    bool? highContrastEnabled,
    bool? backgroundImageEnabled,
    bool? gridEnabled,
    ControlAppearance? controlAppearance,
    BorderStyle? borderStyle,
    int? fontSize,
    bool? feedbackEnabled,
  })  : recentConnections = recentConnections ?? [],
        favoriteConnections = favoriteConnections == null
            ? new LinkedHashSet()
            : LinkedHashSet.from(favoriteConnections),
        themeMode = themeMode ?? ThemeMode.dark,
        highContrastEnabled = highContrastEnabled ?? false,
        backgroundImageEnabled = backgroundImageEnabled ?? true,
        gridEnabled = gridEnabled ?? true,
        controlAppearance = controlAppearance ?? ControlAppearance.outlinedMono,
        borderStyle = borderStyle ?? BorderStyle.dotted,
        fontSize = fontSize ?? 14,
        feedbackEnabled = feedbackEnabled ?? true;

  Map<String, dynamic> toJson() => _$AppPreferencesToJson(this);

  void switchThemeMode() {
    themeMode = getNextThemeMode(themeMode);
    _notifyAndSave();
  }

  void toggleFeedback() {
    feedbackEnabled = !feedbackEnabled;
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

  ConnectionDataPalette? get lastConnection {
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

  bool isFavoriteConnection(ConnectionDataPalette palette) {
    final connection = RecentConnection.fromPalette(palette);
    return favoriteConnections.contains(connection);
  }

  void toggleFavoriteConnection(
    ConnectionDataPalette palette, {
    String? controllerName,
  }) {
    final connection = RecentConnection.fromPalette(palette);
    connection.controllerName = controllerName;
    if (!favoriteConnections.remove(connection)) {
      favoriteConnections.add(connection);
    }
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

@JsonSerializable()
class RecentConnection {
  final String host;
  final String httpPort;
  final String httpsPort;
  final String sessionId;
  final String? certContent;
  String? controllerName;

  RecentConnection({
    required this.host,
    required this.httpPort,
    required this.httpsPort,
    required this.sessionId,
    this.certContent,
    this.controllerName,
  });

  factory RecentConnection.fromJson(Map<String, dynamic> json) =>
      _$RecentConnectionFromJson(json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecentConnection &&
          runtimeType == other.runtimeType &&
          host == other.host &&
          httpPort == other.httpPort &&
          httpsPort == other.httpsPort &&
          sessionId == other.sessionId &&
          certContent == other.certContent;

  @override
  int get hashCode =>
      host.hashCode ^
      httpPort.hashCode ^
      httpsPort.hashCode ^
      sessionId.hashCode ^
      certContent.hashCode;

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
