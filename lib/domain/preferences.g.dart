// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppPreferences _$AppPreferencesFromJson(Map<String, dynamic> json) =>
    AppPreferences(
      recentConnections: (json['recentConnections'] as List<dynamic>?)
          ?.map((e) => RecentConnection.fromJson(e as Map<String, dynamic>))
          .toList(),
      favoriteConnections: (json['favoriteConnections'] as List<dynamic>?)
          ?.map((e) => RecentConnection.fromJson(e as Map<String, dynamic>))
          .toList(),
      themeMode: $enumDecodeNullable(_$ThemeModeEnumMap, json['themeMode']),
      highContrastEnabled: json['highContrastEnabled'] as bool?,
      backgroundImageEnabled: json['backgroundImageEnabled'] as bool?,
      gridEnabled: json['gridEnabled'] as bool?,
      controlAppearance: $enumDecodeNullable(
          _$ControlAppearanceEnumMap, json['controlAppearance']),
      borderStyle:
          $enumDecodeNullable(_$BorderStyleEnumMap, json['borderStyle']),
      fontSize: json['fontSize'] as int?,
      feedbackEnabled: json['feedbackEnabled'] as bool?,
    );

Map<String, dynamic> _$AppPreferencesToJson(AppPreferences instance) =>
    <String, dynamic>{
      'recentConnections': instance.recentConnections,
      'favoriteConnections': instance.favoriteConnections.toList(),
      'themeMode': _$ThemeModeEnumMap[instance.themeMode]!,
      'highContrastEnabled': instance.highContrastEnabled,
      'backgroundImageEnabled': instance.backgroundImageEnabled,
      'gridEnabled': instance.gridEnabled,
      'controlAppearance':
          _$ControlAppearanceEnumMap[instance.controlAppearance]!,
      'borderStyle': _$BorderStyleEnumMap[instance.borderStyle]!,
      'fontSize': instance.fontSize,
      'feedbackEnabled': instance.feedbackEnabled,
    };

const _$ThemeModeEnumMap = {
  ThemeMode.system: 'system',
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
};

const _$ControlAppearanceEnumMap = {
  ControlAppearance.filled: 'filled',
  ControlAppearance.outlined: 'outlined',
  ControlAppearance.filledAndOutlined: 'filledAndOutlined',
  ControlAppearance.outlinedMono: 'outlinedMono',
};

const _$BorderStyleEnumMap = {
  BorderStyle.solid: 'solid',
  BorderStyle.dotted: 'dotted',
};

RecentConnection _$RecentConnectionFromJson(Map<String, dynamic> json) =>
    RecentConnection(
      host: json['host'] as String,
      httpPort: json['httpPort'] as String,
      httpsPort: json['httpsPort'] as String,
      sessionId: json['sessionId'] as String,
      certContent: json['certContent'] as String?,
      controllerName: json['controllerName'] as String?,
    );

Map<String, dynamic> _$RecentConnectionToJson(RecentConnection instance) =>
    <String, dynamic>{
      'host': instance.host,
      'httpPort': instance.httpPort,
      'httpsPort': instance.httpsPort,
      'sessionId': instance.sessionId,
      'certContent': instance.certContent,
      'controllerName': instance.controllerName,
    };
