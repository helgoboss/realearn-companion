import 'dart:math';

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

  // TODO-low Take care in constructor that mappings and customData is never
  //  null instead of doing null checks everywhere!
  Controller({this.id, this.name, this.mappings, this.customData});

  List<ControlData> get controls {
    return customData?.companion?.controls ?? const [];
  }

  void updateControlData(ControlData data) {
    if (customData == null) {
      customData = CustomControllerData();
    }
    customData.updateControlData(data);
  }

  Mapping findMappingById(String mappingId) {
    return mappings.firstWhere((m) => m.id == mappingId);
  }

  Size calcTotalSize() {
    return customData?.calcTotalSize() ?? Size.zero;
  }

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

  factory CustomControllerData.fromJson(Map<String, dynamic> json) =>
      _$CustomControllerDataFromJson(json);

  // TODO-low Take care in constructor that mappings and customData is never
  //  null instead of doing null checks everywhere!
  CustomControllerData({this.companion});

  Size calcTotalSize() {
    return companion?.calcTotalSize() ?? Size.zero;
  }

  void updateControlData(ControlData data) {
    if (companion == null) {
      companion = CompanionControllerData();
    }
    companion.updateControlData(data);
  }
}

@JsonSerializable(createToJson: true, nullable: true)
class CompanionControllerData {
  List<ControlData> controls;

  factory CompanionControllerData.fromJson(Map<String, dynamic> json) =>
      _$CompanionControllerDataFromJson(json);

  CompanionControllerData({List<ControlData> controls}) {
    this.controls = controls ?? [];
  }

  void updateControlData(ControlData data) {
    controls.removeWhere((c) => c.id == data.id);
    controls.add(data);
  }

  Size calcTotalSize() {
    return controls.fold(
        Size(0, 0),
        (Size prev, ControlData data) =>
            Size(max(prev.width, data.right), max(prev.height, data.bottom)));
  }

  Map<String, dynamic> toJson() => _$CompanionControllerDataToJson(this);
}

enum ControlShape { rectangle, circle }

@JsonSerializable(createToJson: true, nullable: true)
class ControlData {
  final String id;
  final List<String> mappings;
  final ControlShape shape;
  final double x;
  final double y;

  factory ControlData.fromJson(Map<String, dynamic> json) =>
      _$ControlDataFromJson(json);

  ControlData({this.id, List<String> mappings, ControlShape shape, double x, double y})
      : mappings = mappings ?? [],
        shape = shape ?? ControlShape.circle,
        x = x ?? 0.0,
        y = y ?? 0.0;

  double get width => 50.0;

  double get height => 50.0;

  double get right => x + width;

  double get bottom => y + height;

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
