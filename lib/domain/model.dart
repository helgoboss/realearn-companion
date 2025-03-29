import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:collection/collection.dart';

part 'model.g.dart';

@JsonSerializable(createToJson: false)
class RealearnEvent {
  final RealearnEventType type;
  final String path;
  final Map<String, dynamic>? body;

  RealearnEvent({RealearnEventType? type, required this.path, this.body})
      : type = type ?? RealearnEventType.put;

  factory RealearnEvent.fromJson(Map<String, dynamic> json) =>
      _$RealearnEventFromJson(json);
}

enum RealearnEventType { put, patch }

class ControllerRoutingModel extends ChangeNotifier {
  ControllerRouting _controllerRouting = ControllerRouting.empty();

  ControllerRoutingModel();

  ControllerRouting get controllerRouting {
    return _controllerRouting;
  }

  void set controllerRouting(ControllerRouting controllerRouting) {
    _controllerRouting = controllerRouting;
    notifyListeners();
  }
}

class ControlValuesModel extends ChangeNotifier {
  Map<String, double> _values = {};

  ControlValuesModel();

  void set values(Map<String, double> values) {
    this._values = values;
    notifyListeners();
  }

  void updateValues(Map<String, double> values) {
    _values.addAll(values);
    notifyListeners();
  }

  double? getValue(String controlId) {
    return _values[controlId];
  }

  Map<String, double?> getValues(List<String> controlIds) {
    return Map.fromEntries(
      controlIds.map((id) => MapEntry(id, this._values[id])),
    );
  }
}

class ControllerModel extends ChangeNotifier {
  Controller? _controller = null;
  bool _controllerHasEdits = false;

  ControllerModel();

  Controller? get controller {
    return _controller;
  }

  bool get controllerHasEdits {
    return _controllerHasEdits;
  }

  void set controller(Controller? controller) {
    this._controller = controller;
    this._controllerHasEdits = false;
    notifyListeners();
  }

  void increaseGridSize() {
    _controller!.increaseGridSize();
    _notifyAndMarkDirty();
  }

  void decreaseGridSize() {
    _controller!.decreaseGridSize();
    _notifyAndMarkDirty();
  }

  void increaseControlWidth(Iterable<String> controlIds) {
    changeControls(controlIds, (c) {
      _controller!.increaseControlWidth(c);
    });
    _notifyAndMarkDirty();
  }

  void decreaseControlWidth(Iterable<String> controlIds) {
    changeControls(controlIds, (c) {
      _controller!.decreaseControlWidth(c);
    });
    _notifyAndMarkDirty();
  }

  void increaseControlHeight(Iterable<String> controlIds) {
    changeControls(controlIds, (c) {
      _controller!.increaseControlHeight(c);
    });
    _notifyAndMarkDirty();
  }

  void decreaseControlHeight(Iterable<String> controlIds) {
    changeControls(controlIds, (c) {
      _controller!.decreaseControlHeight(c);
    });
    _notifyAndMarkDirty();
  }

  void alignControlPositionsToGrid() {
    _controller!.alignControlPositionsToGrid();
    _notifyAndMarkDirty();
  }

  void addControl(ControlData control) {
    _controller!.addControl(control);
    _notifyAndMarkDirty();
  }

  void removeControl(String controlId) {
    _controller!.removeControl(controlId);
    _notifyAndMarkDirty();
  }

  void uniteControls(ControlData survivor, ControlData donator) {
    _controller!.uniteControls(survivor, donator);
    _notifyAndMarkDirty();
  }

  void moveControlsBy(Iterable<String> controlIds, int x, int y) {
    changeControls(controlIds, (c) {
      _controller!.moveControlBy(c, x, y);
    });
    _notifyAndMarkDirty();
  }

  void changeControl(String controlId, Function(ControlData control) op) {
    final control = findControlById(controlId);
    op(control!);
    _notifyAndMarkDirty();
  }

  void changeControls(
      Iterable<String> controlIds, Function(ControlData control) op) {
    final controls = this.findControlsByIds(controlIds);
    for (final control in controls) {
      op(control);
    }
    _notifyAndMarkDirty();
  }

  Iterable<ControlData> findControlsByIds(Iterable<String> controlIds) {
    return controlIds.map(findControlById).whereNotNull();
  }

  ControlData? findControlById(String controlId) {
    return _controller!.customData.companion.findById(controlId);
  }

  void _notifyAndMarkDirty() {
    _controllerHasEdits = true;
    notifyListeners();
  }
}

@JsonSerializable(createToJson: false)
class MainPreset {
  final String id;
  final String name;

  factory MainPreset.fromJson(Map<String, dynamic> json) =>
      _$MainPresetFromJson(json);

  MainPreset({required this.id, required this.name});
}

@JsonSerializable(createToJson: false)
class Controller {
  final String id;
  final String name;
  final List<Mapping> mappings;
  CustomControllerData customData;

  factory Controller.fromJson(Map<String, dynamic> json) =>
      _$ControllerFromJson(json);

  Controller({
    required this.id,
    required this.name,
    List<Mapping>? mappings,
    CustomControllerData? customData,
  })  : mappings = mappings ?? [],
        customData = customData ?? CustomControllerData();

  List<ControlData> get controls {
    return customData.companion.controls;
  }

  Mapping? findMappingById(String mappingId) {
    return mappings.firstWhereOrNull((m) => m.id == mappingId);
  }

  Size calcTotalSize() {
    return customData.companion.calcTotalSize();
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

  void increaseControlWidth(ControlData control) {
    customData.companion.increaseControlWidth(control);
  }

  void decreaseControlWidth(ControlData control) {
    customData.companion.decreaseControlWidth(control);
  }

  void increaseControlHeight(ControlData control) {
    customData.companion.increaseControlHeight(control);
  }

  void decreaseControlHeight(ControlData control) {
    customData.companion.decreaseControlHeight(control);
  }

  void addControl(ControlData control) {
    customData.companion.addControl(control);
  }

  // TODO-low Refactor other methods to take IDs as well
  void removeControl(String controlId) {
    customData.companion.removeControl(controlId);
  }

  void uniteControls(ControlData survivor, ControlData donator) {
    customData.companion.uniteControls(survivor, donator);
  }

  void moveControlBy(ControlData control, int x, int y) {
    customData.companion.moveControlBy(control, x, y);
  }
}

@JsonSerializable(createToJson: false)
class Mapping {
  final String id;
  final String name;

  Mapping({required this.id, required this.name});

  factory Mapping.fromJson(Map<String, dynamic> json) =>
      _$MappingFromJson(json);
}

@JsonSerializable(createToJson: false)
class CustomControllerData {
  CompanionControllerData companion;

  factory CustomControllerData.fromJson(Map<String, dynamic> json) =>
      _$CustomControllerDataFromJson(json);

  CustomControllerData({CompanionControllerData? companion})
      : companion = companion ?? CompanionControllerData();
}

@JsonSerializable(createToJson: true)
class CompanionControllerData {
  int gridSize;
  int gridDivisionCount;
  List<ControlData> controls;

  factory CompanionControllerData.fromJson(Map<String, dynamic> json) =>
      _$CompanionControllerDataFromJson(json);

  CompanionControllerData({
    int? gridSize,
    int? gridDivisionCount,
    List<ControlData>? controls,
  })  : gridSize = math.max(minGridSize, gridSize ?? defaultGridSize),
        gridDivisionCount =
            math.min(maxGridDivisionCount, gridDivisionCount ?? 2),
        controls = controls ?? [];

  void addControl(ControlData control) {
    control.alignPositionToGrid(gridSize);
    controls.add(control);
  }

  void removeControl(String controlId) {
    controls.removeWhere((control) => control.id == controlId);
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
    gridSize += minGridSize;
  }

  void decreaseGridSize() {
    int nextSize = gridSize - minGridSize;
    gridSize = math.max(minGridSize, nextSize);
  }

  void increaseControlWidth(ControlData control) {
    control.adjustControlWidth(_dimensionIncrement);
  }

  void decreaseControlWidth(ControlData control) {
    control.adjustControlWidth(-_dimensionIncrement);
  }

  void increaseControlHeight(ControlData control) {
    control.adjustControlHeight(_dimensionIncrement);
  }

  void decreaseControlHeight(ControlData control) {
    control.adjustControlHeight(-_dimensionIncrement);
  }

  int get _dimensionIncrement {
    return minControlSize;
  }

  void alignControlPositionsToGrid() {
    for (var c in controls) {
      c.alignPositionToGrid(gridSize);
    }
  }

  void uniteControls(ControlData survivor, ControlData donator) {
    survivor.addMapping(donator.mappings.first);
    removeControl(donator.id);
  }

  void moveControlBy(ControlData control, int x, int y) {
    control.moveBy(x, y);
    control.alignPositionToGrid(gridSize);
  }

  ControlData? findById(String controlId) {
    return controls.firstWhereOrNull((c) => c.id == controlId);
  }

  Map<String, dynamic> toJson() => _$CompanionControllerDataToJson(this);
}

enum ControlShape { rectangle, circle }

@JsonSerializable(createToJson: true)
class ControlData {
  final String id;
  List<String> mappings;
  ControlShape shape;
  int x;
  int y;

  // In case of a circle shape this is used as diameter.
  int width;
  int height;
  LabelSettings labelOne;
  LabelSettings labelTwo;

  factory ControlData.fromJson(Map<String, dynamic> json) =>
      _$ControlDataFromJson(json);

  ControlData({
    required this.id,
    List<String>? mappings,
    ControlShape? shape,
    num? x,
    num? y,
    num? width,
    num? height,
    LabelSettings? labelOne,
    LabelSettings? labelTwo,
  })  : mappings = mappings ?? [],
        shape = shape ?? ControlShape.circle,
        x = math.max(0, x?.toInt() ?? 0),
        y = math.max(0, y?.toInt() ?? 0),
        width = math.max(minControlSize, width?.toInt() ?? defaultControlSize),
        height =
            math.max(minControlSize, height?.toInt() ?? defaultControlSize),
        labelOne =
            labelOne ?? LabelSettings(position: ControlLabelPosition.aboveTop),
        labelTwo = labelTwo ??
            LabelSettings(position: ControlLabelPosition.belowBottom);

  int get right => x + width;

  int get bottom => y + height;

  void addMapping(String mappingId) {
    mappings.add(mappingId);
  }

  void alignPositionToGrid(int gridSize) {
    x = roundNumberToGridSize(x, gridSize);
    y = roundNumberToGridSize(y, gridSize);
  }

  void adjustControlWidth(int amount) {
    width = math.max(minControlSize, width + amount);
  }

  void adjustControlHeight(int amount) {
    height = math.max(minControlSize, height + amount);
  }

  void moveBy(int x, int y) {
    this.x = math.max(0, this.x + x);
    this.y = math.max(0, this.y + y);
  }

  void switchShape() {
    shape = getNextControlShape(shape);
  }

  Map<String, dynamic> toJson() => _$ControlDataToJson(this);
}

// We choose a proper minimum size here starting from a typical font size.
const atomicSize = 8;
const minGridSize = atomicSize * 4;
const defaultGridSize = minGridSize;
const minControlSize = atomicSize * 2;
const defaultControlSize = minGridSize;
const maxGridDivisionCount = 8;

ControlShape getNextControlShape(ControlShape value) {
  return ControlShape.values[(value.index + 1) % ControlShape.values.length];
}

int roundNumberToGridSize(int number, int gridSize) {
  return (number.toDouble() / gridSize).round() * gridSize;
}

@JsonSerializable(createToJson: false)
class ControllerRouting {
  final MainPreset? mainPreset;
  final Map<String, List<TargetDescriptor>> routes;

  const ControllerRouting({
    this.mainPreset,
    Map<String, List<TargetDescriptor>>? routes,
  }) : routes = routes ?? const {};

  const factory ControllerRouting.empty() = ControllerRouting;

  factory ControllerRouting.fromJson(Map<String, dynamic> json) =>
      _$ControllerRoutingFromJson(json);
}

@JsonSerializable(createToJson: false)
class TargetDescriptor {
  final String label;

  TargetDescriptor({required this.label});

  factory TargetDescriptor.fromJson(Map<String, dynamic> json) =>
      _$TargetDescriptorFromJson(json);
}

enum ControlLabelPosition {
  aboveTop,
  belowTop,
  center,
  aboveBottom,
  belowBottom,
  leftOfLeft,
  rightOfLeft,
  leftOfRight,
  rightOfRight,
}

@JsonSerializable(createToJson: true)
class LabelSettings {
  ControlLabelPosition position;
  bool sizeConstrained;
  int angle;

  LabelSettings({
    ControlLabelPosition? position,
    bool? sizeConstrained,
    int? angle,
  })  : position = position ?? ControlLabelPosition.aboveTop,
        sizeConstrained = sizeConstrained ?? true,
        angle = angle ?? 0;

  factory LabelSettings.fromJson(Map<String, dynamic> json) =>
      _$LabelSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$LabelSettingsToJson(this);
}
