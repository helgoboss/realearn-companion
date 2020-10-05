import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

@JsonSerializable(createToJson: false, nullable: true)
class RealearnEvent {
  final String type;
  final String path;
  final Map<String, dynamic> payload;

  RealearnEvent({this.type, this.path, this.payload});
  factory RealearnEvent.fromJson(Map<String, dynamic> json) => _$RealearnEventFromJson(json);
}

@JsonSerializable(createToJson: false, nullable: true)
class Controller {
  final String id;
  final String name;
  final List<Mapping> mappings;
  final CustomControllerData customData;

  Controller({this.id, this.name, this.mappings, this.customData});
  factory Controller.fromJson(Map<String, dynamic> json) => _$ControllerFromJson(json);
}

@JsonSerializable(createToJson: false, nullable: true)
class Mapping {
  final String id;
  final String name;

  Mapping({this.id, this.name});
  factory Mapping.fromJson(Map<String, dynamic> json) => _$MappingFromJson(json);
}

@JsonSerializable(createToJson: false, nullable: true)
class CustomControllerData {
  final Map<String, dynamic> companion;

  CustomControllerData({this.companion});
  factory CustomControllerData.fromJson(Map<String, dynamic> json) => _$CustomControllerDataFromJson(json);
}

@JsonSerializable(createToJson: true, nullable: true)
class CompanionControllerData {

  CompanionControllerData();
  factory CompanionControllerData.fromJson(Map<String, dynamic> json) => _$CompanionControllerDataFromJson(json);
}

@JsonSerializable(createToJson: false, nullable: true)
class ControllerRouting {
  final Map<String, TargetDescriptor> routes;

  ControllerRouting({this.routes});
  factory ControllerRouting.fromJson(Map<String, dynamic> json) => _$ControllerRoutingFromJson(json);
}

@JsonSerializable(createToJson: false, nullable: true)
class TargetDescriptor {
  final String label;

  TargetDescriptor({this.label});
  factory TargetDescriptor.fromJson(Map<String, dynamic> json) => _$TargetDescriptorFromJson(json);
}