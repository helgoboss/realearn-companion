import 'dart:developer';
import 'dart:math' as math;

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
  Controller _controller = null;
  bool _controllerHasEdits = false;

  ControllerModel();

  Controller get controller {
    return _controller;
  }

  bool get controllerHasEdits {
    return _controllerHasEdits;
  }

  void set controller(Controller controller) {
    this._controller = controller;
    this._controllerHasEdits = false;
    notifyListeners();
  }

  void updateControlData(ControlData data) {
    assert(_controller != null);
    _controller.updateControlData(data);
    _controllerHasEdits = true;
    notifyListeners();
  }

  void increaseGridSize() {
    assert(_controller != null);
    _controller.increaseGridSize();
    _controllerHasEdits = true;
    notifyListeners();
  }

  void decreaseGridSize() {
    assert(_controller != null);
    _controller.decreaseGridSize();
    _controllerHasEdits = true;
    notifyListeners();
  }

  void alignControlPositionsToGrid() {
    assert(_controller != null);
    _controller.alignControlPositionsToGrid();
    _controllerHasEdits = true;
    notifyListeners();
  }
}

@JsonSerializable(createToJson: false, nullable: true)
class Controller {
  final String id;
  final String name;
  final List<Mapping> mappings;
  CustomControllerData customData;

  factory Controller.fromJson(Map<String, dynamic> json) =>
      _$ControllerFromJson(json);

  Controller(
      {this.id, this.name, this.mappings, CustomControllerData customData})
      : customData = customData ?? CustomControllerData();

  List<ControlData> get controls {
    return customData.companion.controls;
  }

  void updateControlData(ControlData data) {
    customData.companion.updateControlData(data);
  }

  Mapping findMappingById(String mappingId) {
    return mappings.firstWhere((m) => m.id == mappingId);
  }

  Size calcTotalSize() {
    return customData.companion.calcTotalSize() ?? Size.zero;
  }

  int get gridSize {
    return customData.companion.gridSize;
  }

  void increaseGridSize() {
    customData.companion.increaseGridSize();
  }

  void decreaseGridSize() {
    customData.companion.decreaseGridSize();
  }

  void alignControlPositionsToGrid() {
    customData.companion.alignControlPositionsToGrid();
  }
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

  CustomControllerData({CompanionControllerData companion})
      : companion = companion ?? CompanionControllerData();
}

@JsonSerializable(createToJson: true, nullable: true)
class CompanionControllerData {
  int gridSize;
  List<ControlData> controls;

  factory CompanionControllerData.fromJson(Map<String, dynamic> json) =>
      _$CompanionControllerDataFromJson(json);

  CompanionControllerData({int gridSize, List<ControlData> controls})
      : gridSize = gridSize ?? 10,
        controls = controls ?? [];

  void updateControlData(ControlData data) {
    controls.removeWhere((c) => c.id == data.id);
    if (!data.mappings.isEmpty) {
      controls.add(data);
    }
  }

  Size calcTotalSize() {
    return controls.fold(
      Size(0, 0),
      (Size prev, ControlData data) => Size(
        math.max(prev.width, data.right.toDouble()),
        math.max(prev.height, data.bottom.toDouble()),
      ),
    );
  }

  void increaseGridSize() {
    gridSize += 10;
  }

  void decreaseGridSize() {
    int nextSize = gridSize - 10;
    gridSize = nextSize < 0 ? 10 : nextSize;
  }

  void alignControlPositionsToGrid() {
    var stableControls = [...controls];
    for (var c in stableControls) {
      // TODO-medium A bit weird to have ControlData immutable and this not?
      var updated = c.withPositionAlignedToGrid(gridSize);
      updateControlData(updated);
    }
  }

  Map<String, dynamic> toJson() => _$CompanionControllerDataToJson(this);
}

enum ControlShape { rectangle, circle }

@JsonSerializable(createToJson: true, nullable: true)
class ControlData {
  final String id;
  final List<String> mappings;
  final ControlShape shape;
  final int x;
  final int y;

  factory ControlData.fromJson(Map<String, dynamic> json) =>
      _$ControlDataFromJson(json);

  ControlData(
      {this.id, List<String> mappings, ControlShape shape, num x, num y})
      : mappings = mappings ?? [],
        shape = shape ?? ControlShape.circle,
        x = x.toInt() ?? 0,
        y = y.toInt() ?? 0;

  int get width => 50;

  int get height => 50;

  int get right => x + width;

  int get bottom => y + height;

  Map<String, dynamic> toJson() => _$ControlDataToJson(this);

  ControlData withPositionAlignedToGrid(int gridSize) {
    return copyWith(
      x: roundNumberToGridSize(x, gridSize),
      y: roundNumberToGridSize(y, gridSize),
    );
  }

  ControlData copyWith({
    List<String> mappings,
    ControlShape shape,
    int x,
    int y,
  }) {
    return ControlData(
      id: this.id,
      mappings: mappings ?? this.mappings,
      shape: shape ?? this.shape,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }
}

int roundNumberToGridSize(int number, int gridSize) {
  return (number.toDouble() / gridSize).round() * gridSize;
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
