// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
