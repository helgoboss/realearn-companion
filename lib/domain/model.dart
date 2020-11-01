import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

@JsonSerializable(createToJson: false, nullable: true)
class RealearnEvent {
  final String type;
  final String path;
  final Map<String, dynamic> payload;

  RealearnEvent({this.type, this.path, this.payload});

  factory RealearnEvent.fromJson(Map<String, dynamic> json) =>
      _$RealearnEventFromJson(json);
}

class ControllerModel extends ChangeNotifier {
  final Controller controller;

  ControllerModel(this.controller);
}

class ControllerRoutingModel extends ChangeNotifier {
  final ControllerRouting controllerRouting;

  ControllerRoutingModel(this.controllerRouting);
}

@JsonSerializable(createToJson: false, nullable: true)
class Controller {
  final String id;
  final String name;
  final List<Mapping> mappings;
  CustomControllerData customData;

  ControlData findControlData(String mappingId) {
    return (customData?.companion?.controls ?? const {})[mappingId];
  }

  void updateControlData(String mappingId, ControlData data) {
    if (customData == null) {
      customData = CustomControllerData();
    }
    customData.updateControlData(mappingId, data);
  }

  Controller({this.id, this.name, this.mappings, this.customData});

  factory Controller.fromJson(Map<String, dynamic> json) =>
      _$ControllerFromJson(json);
}

@JsonSerializable(createToJson: false, nullable: true)
class Mapping {
  final String id;
  final String name;

  Mapping({this.id, this.name});

  factory Mapping.fromJson(Map<String, dynamic> json) =>
      _$MappingFromJson(json);
}

@JsonSerializable(createToJson: false, nullable: true)
class CustomControllerData {
  CompanionControllerData companion;

  void updateControlData(String mappingId, ControlData data) {
    if (companion == null) {
      companion = CompanionControllerData();
    }
    companion.updateControlData(mappingId, data);
  }

  CustomControllerData({this.companion});

  factory CustomControllerData.fromJson(Map<String, dynamic> json) =>
      _$CustomControllerDataFromJson(json);
}

@JsonSerializable(createToJson: true, nullable: true)
class CompanionControllerData {
  Map<String, ControlData> controls;

  void updateControlData(String mappingId, ControlData data) {
    if (controls == null) {
      controls = Map();
    }
    controls[mappingId] = data;
  }

  CompanionControllerData({this.controls});

  factory CompanionControllerData.fromJson(Map<String, dynamic> json) =>
      _$CompanionControllerDataFromJson(json);

  Map<String, dynamic> toJson() => _$CompanionControllerDataToJson(this);
}

enum ControlShape { rectangle, circle }

@JsonSerializable(createToJson: true, nullable: true)
class ControlData {
  final ControlShape shape;
  final double x;
  final double y;

  ControlData({this.shape, this.x, this.y});

  factory ControlData.fromJson(Map<String, dynamic> json) =>
      _$ControlDataFromJson(json);

  Map<String, dynamic> toJson() => _$ControlDataToJson(this);
}

@JsonSerializable(createToJson: false, nullable: true)
class ControllerRouting {
  final Map<String, TargetDescriptor> routes;

  ControllerRouting({this.routes});

  factory ControllerRouting.fromJson(Map<String, dynamic> json) =>
      _$ControllerRoutingFromJson(json);
}

@JsonSerializable(createToJson: false, nullable: true)
class TargetDescriptor {
  final String label;

  TargetDescriptor({this.label});

  factory TargetDescriptor.fromJson(Map<String, dynamic> json) =>
      _$TargetDescriptorFromJson(json);
}
