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
    companion: json['companion'] as Map<String, dynamic>,
  );
}

CompanionControllerData _$CompanionControllerDataFromJson(
    Map<String, dynamic> json) {
  return CompanionControllerData();
}

Map<String, dynamic> _$CompanionControllerDataToJson(
        CompanionControllerData instance) =>
    <String, dynamic>{};

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
