// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RealearnEvent _$RealearnEventFromJson(Map<String, dynamic> json) {
  return RealearnEvent(
    type: json['type'] as String,
    path: json['path'] as String,
    payload: json['payload'] as Map<String, dynamic>,
  );
}

Controller _$ControllerFromJson(Map<String, dynamic> json) {
  return Controller(
    id: json['id'] as String,
    name: json['name'] as String,
    mappings: (json['mappings'] as List)
        ?.map((e) =>
            e == null ? null : Mapping.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    customData: json['customData'] == null
        ? null
        : CustomControllerData.fromJson(
            json['customData'] as Map<String, dynamic>),
  );
}

Mapping _$MappingFromJson(Map<String, dynamic> json) {
  return Mapping(
    id: json['id'] as String,
    name: json['name'] as String,
  );
}

CustomControllerData _$CustomControllerDataFromJson(Map<String, dynamic> json) {
  return CustomControllerData(
    companion: json['companion'] == null
        ? null
        : CompanionControllerData.fromJson(
            json['companion'] as Map<String, dynamic>),
  );
}

CompanionControllerData _$CompanionControllerDataFromJson(
    Map<String, dynamic> json) {
  return CompanionControllerData(
    controls: (json['controls'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k,
          e == null ? null : ControlData.fromJson(e as Map<String, dynamic>)),
    ),
  );
}

Map<String, dynamic> _$CompanionControllerDataToJson(
        CompanionControllerData instance) =>
    <String, dynamic>{
      'controls': instance.controls,
    };

ControlData _$ControlDataFromJson(Map<String, dynamic> json) {
  return ControlData(
    shape: _$enumDecodeNullable(_$ControlShapeEnumMap, json['shape']),
    x: (json['x'] as num)?.toDouble(),
    y: (json['y'] as num)?.toDouble(),
  );
}

Map<String, dynamic> _$ControlDataToJson(ControlData instance) =>
    <String, dynamic>{
      'shape': _$ControlShapeEnumMap[instance.shape],
      'x': instance.x,
      'y': instance.y,
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

const _$ControlShapeEnumMap = {
  ControlShape.rectangle: 'rectangle',
  ControlShape.circle: 'circle',
};

ControllerRouting _$ControllerRoutingFromJson(Map<String, dynamic> json) {
  return ControllerRouting(
    routes: (json['routes'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(
          k,
          e == null
              ? null
              : TargetDescriptor.fromJson(e as Map<String, dynamic>)),
    ),
  );
}

TargetDescriptor _$TargetDescriptorFromJson(Map<String, dynamic> json) {
  return TargetDescriptor(
    label: json['label'] as String,
  );
}
