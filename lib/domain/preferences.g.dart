// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppPreferences _$AppPreferencesFromJson(Map<String, dynamic> json) {
  return AppPreferences(
    themeMode: _$enumDecodeNullable(_$ThemeModeEnumMap, json['themeMode']),
    highContrast: json['highContrast'] as bool,
  );
}

Map<String, dynamic> _$AppPreferencesToJson(AppPreferences instance) =>
    <String, dynamic>{
      'themeMode': _$ThemeModeEnumMap[instance.themeMode],
      'highContrast': instance.highContrast,
    };

T _$enumDecode<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }

  final value = enumValues.entries
      .singleWhere((e) => e.value == source, orElse: () => null)
      ?.key;

  if (value == null && unknownValue == null) {
    throw ArgumentError('`$source` is not one of the supported values: '
        '${enumValues.values.join(', ')}');
  }
  return value ?? unknownValue;
}

T _$enumDecodeNullable<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<T>(enumValues, source, unknownValue: unknownValue);
}

const _$ThemeModeEnumMap = {
  ThemeMode.system: 'system',
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
};

RecentConnection _$RecentConnectionFromJson(Map<String, dynamic> json) {
  return RecentConnection(
    host: json['host'] as String,
    httpPort: json['httpPort'] as String,
    httpsPort: json['httpsPort'] as String,
    sessionId: json['sessionId'] as String,
    certContent: json['certContent'] as String,
  );
}

Map<String, dynamic> _$RecentConnectionToJson(RecentConnection instance) =>
    <String, dynamic>{
      'host': instance.host,
      'httpPort': instance.httpPort,
      'httpsPort': instance.httpsPort,
      'sessionId': instance.sessionId,
      'certContent': instance.certContent,
    };
