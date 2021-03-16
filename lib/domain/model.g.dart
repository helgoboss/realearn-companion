// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RealearnEvent _$RealearnEventFromJson(Map<String, dynamic> json) {
  return RealearnEvent(
    path: json['path'] as String,
    body: json['body'] as Map<String, dynamic>?,
  );
}

MainPreset _$MainPresetFromJson(Map<String, dynamic> json) {
  return MainPreset(
    id: json['id'] as String,
    name: json['name'] as String,
  );
}

Controller _$ControllerFromJson(Map<String, dynamic> json) {
  return Controller(
    id: json['id'] as String,
    name: json['name'] as String,
    mappings: (json['mappings'] as List<dynamic>?)
        ?.map((e) => Mapping.fromJson(e as Map<String, dynamic>))
        .toList(),
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
    gridSize: json['gridSize'] as int?,
    gridDivisionCount: json['gridDivisionCount'] as int?,
    controls: (json['controls'] as List<dynamic>?)
        ?.map((e) => ControlData.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$CompanionControllerDataToJson(
        CompanionControllerData instance) =>
    <String, dynamic>{
      'gridSize': instance.gridSize,
      'gridDivisionCount': instance.gridDivisionCount,
      'controls': instance.controls,
    };

ControlData _$ControlDataFromJson(Map<String, dynamic> json) {
  return ControlData(
    id: json['id'] as String,
    mappings:
        (json['mappings'] as List<dynamic>?)?.map((e) => e as String).toList(),
    shape: _$enumDecodeNullable(_$ControlShapeEnumMap, json['shape']),
    x: json['x'] as num?,
    y: json['y'] as num?,
    width: json['width'] as num?,
    height: json['height'] as num?,
    labelOne: json['labelOne'] == null
        ? null
        : LabelSettings.fromJson(json['labelOne'] as Map<String, dynamic>),
    labelTwo: json['labelTwo'] == null
        ? null
        : LabelSettings.fromJson(json['labelTwo'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$ControlDataToJson(ControlData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mappings': instance.mappings,
      'shape': _$ControlShapeEnumMap[instance.shape],
      'x': instance.x,
      'y': instance.y,
      'width': instance.width,
      'height': instance.height,
      'labelOne': instance.labelOne,
      'labelTwo': instance.labelTwo,
    };

K _$enumDecode<K, V>(
  Map<K, V> enumValues,
  Object? source, {
  K? unknownValue,
}) {
  if (source == null) {
    throw ArgumentError(
      'A value must be provided. Supported values: '
      '${enumValues.values.join(', ')}',
    );
  }

  return enumValues.entries.singleWhere(
    (e) => e.value == source,
    orElse: () {
      if (unknownValue == null) {
        throw ArgumentError(
          '`$source` is not one of the supported values: '
          '${enumValues.values.join(', ')}',
        );
      }
      return MapEntry(unknownValue, enumValues.values.first);
    },
  ).key;
}

K? _$enumDecodeNullable<K, V>(
  Map<K, V> enumValues,
  dynamic source, {
  K? unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<K, V>(enumValues, source, unknownValue: unknownValue);
}

const _$ControlShapeEnumMap = {
  ControlShape.rectangle: 'rectangle',
  ControlShape.circle: 'circle',
};

ControllerRouting _$ControllerRoutingFromJson(Map<String, dynamic> json) {
  return ControllerRouting(
    mainPreset: json['mainPreset'] == null
        ? null
        : MainPreset.fromJson(json['mainPreset'] as Map<String, dynamic>),
    routes: (json['routes'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(
          k,
          (e as List<dynamic>)
              .map((e) => TargetDescriptor.fromJson(e as Map<String, dynamic>))
              .toList()),
    ),
  );
}

TargetDescriptor _$TargetDescriptorFromJson(Map<String, dynamic> json) {
  return TargetDescriptor(
    label: json['label'] as String,
  );
}

LabelSettings _$LabelSettingsFromJson(Map<String, dynamic> json) {
  return LabelSettings(
    position:
        _$enumDecodeNullable(_$ControlLabelPositionEnumMap, json['position']),
    sizeConstrained: json['sizeConstrained'] as bool?,
    angle: json['angle'] as int?,
  );
}

Map<String, dynamic> _$LabelSettingsToJson(LabelSettings instance) =>
    <String, dynamic>{
      'position': _$ControlLabelPositionEnumMap[instance.position],
      'sizeConstrained': instance.sizeConstrained,
      'angle': instance.angle,
    };

const _$ControlLabelPositionEnumMap = {
  ControlLabelPosition.aboveTop: 'aboveTop',
  ControlLabelPosition.belowTop: 'belowTop',
  ControlLabelPosition.center: 'center',
  ControlLabelPosition.aboveBottom: 'aboveBottom',
  ControlLabelPosition.belowBottom: 'belowBottom',
  ControlLabelPosition.leftOfLeft: 'leftOfLeft',
  ControlLabelPosition.rightOfLeft: 'rightOfLeft',
  ControlLabelPosition.leftOfRight: 'leftOfRight',
  ControlLabelPosition.rightOfRight: 'rightOfRight',
};
