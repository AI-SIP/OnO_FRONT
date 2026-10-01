import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// 포인터 하나가 무엇을 할지.
enum InkPointerRole {
  /// 필기하거나 지운다.
  draw,

  /// 화면을 옮기거나 확대한다.
  transform,

  /// 손바닥처럼 무시한다.
  ignore,
}

class InkPointerDecision {
  final InkPointerRole role;

  /// 손가락으로 쓰던 획을 버려야 하는지. 손가락 하나로 쓰다가 두 번째 손가락이
  /// 닿으면 확대로 바뀌는데, 그때까지 그은 짧은 선은 남기지 않는다.
  final bool cancelLiveStroke;

  const InkPointerDecision(this.role, {this.cancelLiveStroke = false});
}

/// 포인터마다 필기할지, 화면을 움직일지, 무시할지를 가른다.
///
/// - 이번 풀이에서 펜이 한 번이라도 닿으면, 그 뒤로 손가락은 필기하지 않고
///   화면 이동과 확대에만 쓴다. 손바닥 자국을 막기 위해서다.
/// - 펜으로 쓰는 중에 닿는 손가락은 모두 무시한다. 고치기 전에는 손가락 수가
///   둘이 되는 순간 쓰던 획을 끝내서, 손바닥이 닿으면 획이 끊겼다.
/// - 펜을 안 쓰는 사람은 손가락 하나로 쓰고, 두 손가락으로 이동과 확대를 한다.
class InkInputRouter {
  bool _stylusSeen = false;
  bool _palmRejected = false;
  int? _drawingPointer;
  PointerDeviceKind? _drawingKind;
  final Map<int, PointerDeviceKind> _down = {};
  final Set<int> _transformPointers = {};

  /// 펜이 감지된 적이 있는지.
  bool get stylusSeen => _stylusSeen;

  /// 펜 감지 뒤 손가락 필기를 막은 적이 있는지. 애널리틱스와 안내에 쓴다.
  bool get palmRejected => _palmRejected;

  int? get drawingPointer => _drawingPointer;

  Set<int> get transformPointers => Set.unmodifiable(_transformPointers);

  InkPointerDecision onDown(int pointer, PointerDeviceKind kind) {
    _down[pointer] = kind;
    final isStylus = kind == PointerDeviceKind.stylus ||
        kind == PointerDeviceKind.invertedStylus;

    if (isStylus) {
      _stylusSeen = true;
      // 펜은 늘 쓴다. 손가락이 쓰고 있었으면 그 획은 버리고 펜으로 넘긴다.
      final cancel = _drawingPointer != null && _drawingKind != kind;
      _drawingPointer = pointer;
      _drawingKind = kind;
      _transformPointers.clear();
      return InkPointerDecision(InkPointerRole.draw, cancelLiveStroke: cancel);
    }

    if (_stylusSeen) {
      // 펜으로 쓰는 중이면 손바닥이다.
      if (_drawingPointer != null) {
        _palmRejected = true;
        return const InkPointerDecision(InkPointerRole.ignore);
      }
      if (_transformPointers.isEmpty) _palmRejected = true;
      _transformPointers.add(pointer);
      return const InkPointerDecision(InkPointerRole.transform);
    }

    // 펜을 안 쓰는 사람. 첫 손가락은 쓰고, 둘째부터는 확대와 이동이다.
    if (_drawingPointer == null && _transformPointers.isEmpty) {
      _drawingPointer = pointer;
      _drawingKind = kind;
      return const InkPointerDecision(InkPointerRole.draw);
    }
    final cancel = _drawingPointer != null;
    if (_drawingPointer != null) {
      _transformPointers.add(_drawingPointer!);
      _drawingPointer = null;
      _drawingKind = null;
    }
    _transformPointers.add(pointer);
    return InkPointerDecision(InkPointerRole.transform,
        cancelLiveStroke: cancel);
  }

  /// 손을 뗐다. 그 포인터가 쓰던 중이었으면 true.
  bool onUp(int pointer) {
    _down.remove(pointer);
    _transformPointers.remove(pointer);
    if (_drawingPointer == pointer) {
      _drawingPointer = null;
      _drawingKind = null;
      return true;
    }
    return false;
  }

  bool isDrawing(int pointer) => _drawingPointer == pointer;

  bool isTransforming(int pointer) => _transformPointers.contains(pointer);
}

/// 손가락 한두 개로 화면을 옮기고 확대하는 계산이다.
///
/// 손가락이 닿거나 떨어질 때마다 그때의 행렬과 위치를 새 기준으로 잡고,
/// 움직이면 기준에서 얼마나 옮기고 벌렸는지로 새 행렬을 만든다.
class InkTransformTracker {
  final double minScale;
  final double maxScale;

  /// 확대한 화면을 얼마나 바깥까지 끌 수 있는지. 고치기 전 InteractiveViewer 의
  /// boundaryMargin 과 같다.
  final double margin;

  InkTransformTracker({
    this.minScale = 1,
    this.maxScale = 4,
    this.margin = 80,
  });

  Matrix4 _start = Matrix4.identity();
  final Map<int, Offset> _startPositions = {};
  final Map<int, Offset> _positions = {};

  /// 화면을 움직이고 있는 손가락이 있는지.
  bool get isActive => _positions.isNotEmpty;

  bool tracks(int pointer) => _positions.containsKey(pointer);

  /// 손가락 [pointer] 를 기준에 더한다. [current] 는 지금 행렬.
  void add(int pointer, Offset position, Matrix4 current) {
    _positions[pointer] = position;
    _rebase(current);
  }

  void remove(int pointer, Matrix4 current) {
    if (_positions.remove(pointer) == null) return;
    _rebase(current);
  }

  void clear() {
    _positions.clear();
    _startPositions.clear();
  }

  void _rebase(Matrix4 current) {
    _start = current.clone();
    _startPositions
      ..clear()
      ..addAll(_positions);
  }

  /// [pointer] 가 [position] 으로 움직였을 때의 새 행렬. [viewport] 는 화면 크기.
  Matrix4? move(int pointer, Offset position, Size viewport) {
    if (!_positions.containsKey(pointer)) return null;
    _positions[pointer] = position;

    final ids = _startPositions.keys.where(_positions.containsKey).toList();
    if (ids.isEmpty) return null;

    final startScale = _start.getMaxScaleOnAxis();
    var focalStart = _startPositions[ids.first]!;
    var focalNow = _positions[ids.first]!;
    var factor = 1.0;

    if (ids.length >= 2) {
      final a0 = _startPositions[ids[0]]!, b0 = _startPositions[ids[1]]!;
      final a1 = _positions[ids[0]]!, b1 = _positions[ids[1]]!;
      focalStart = Offset.lerp(a0, b0, 0.5)!;
      focalNow = Offset.lerp(a1, b1, 0.5)!;
      final d0 = (a0 - b0).distance;
      if (d0 > 0) factor = (a1 - b1).distance / d0;
      factor = factor.clamp(minScale / startScale, maxScale / startScale);
    }

    final next = Matrix4.identity()
      ..translateByDouble(focalNow.dx, focalNow.dy, 0, 1)
      ..scaleByDouble(factor, factor, 1, 1)
      ..translateByDouble(-focalStart.dx, -focalStart.dy, 0, 1)
      ..multiply(_start);
    return _clamp(next, viewport);
  }

  Matrix4 _clamp(Matrix4 matrix, Size viewport) {
    final scale = matrix.getMaxScaleOnAxis();
    final t = matrix.getTranslation();
    final minX = viewport.width - viewport.width * scale - margin;
    final minY = viewport.height - viewport.height * scale - margin;
    final x = t.x.clamp(math.min(minX, margin), margin).toDouble();
    final y = t.y.clamp(math.min(minY, margin), margin).toDouble();
    return matrix..setTranslationRaw(x, y, t.z);
  }
}
