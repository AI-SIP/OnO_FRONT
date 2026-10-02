import 'dart:math' as math;
import 'dart:ui';

/// 획 종류다.
enum InkKind {
  pen,

  /// 반투명하고 다른 획 아래에 깔린다.
  highlighter,

  /// 지나간 자리의 획을 지운다. 그릴 때 `BlendMode.clear` 를 쓴다.
  pixelEraser,
}

/// 필기 한 획이다.
///
/// 점은 문제 이미지 기준 0~1 좌표로 저장한다. 화면 크기나 방향이 바뀌어도 같은
/// 자리에 다시 그릴 수 있게 하려는 것이고, 고치기 전 필기 화면과 같은 규칙이다.
/// 굵기는 그릴 때의 캔버스 픽셀이다.
class InkStroke {
  final InkKind kind;
  final Color color;
  final double width;

  /// 펜으로 그려서 점마다 필압이 있으면 true. 손가락은 false 라 굵기가 일정하다.
  final bool hasPressure;

  final List<Offset> _points = [];
  final List<double> _pressures = [];

  double _minX = double.infinity;
  double _minY = double.infinity;
  double _maxX = -double.infinity;
  double _maxY = -double.infinity;

  InkStroke({
    required this.kind,
    required this.color,
    required this.width,
    this.hasPressure = false,
  });

  /// 화면 기준 이만큼보다 가까운 점은 버린다. 펜은 초당 240번까지 점을 보내서
  /// 그대로 다 쌓으면 그리는 비용만 늘고 모양은 같다.
  static const double minPointDistance = 0.75;

  /// 필압이 굵기에 주는 범위. 설정한 굵기의 0.6배에서 1.4배.
  static const double minPressureScale = 0.6;
  static const double maxPressureScale = 1.4;

  List<Offset> get points => List.unmodifiable(_points);

  int get length => _points.length;

  bool get isEmpty => _points.isEmpty;

  bool get isEraser => kind == InkKind.pixelEraser;

  /// 이미지 기준 좌표의 경계 상자. 획 지우개가 먼 획을 바로 건너뛰는 데 쓴다.
  Rect get normalizedBounds =>
      _points.isEmpty ? Rect.zero : Rect.fromLTRB(_minX, _minY, _maxX, _maxY);

  /// 점을 더한다. [imageRect] 는 지금 화면에서 문제 이미지가 놓인 자리로,
  /// 가까운 점을 버릴지 화면 픽셀로 판단하는 데만 쓴다. 더했으면 true.
  bool addPoint(Offset normalized, double pressure, Rect imageRect,
      {bool force = false}) {
    if (_points.isNotEmpty && !force) {
      final last = _points.last;
      final dx = (normalized.dx - last.dx) * imageRect.width;
      final dy = (normalized.dy - last.dy) * imageRect.height;
      if (dx * dx + dy * dy < minPointDistance * minPointDistance) {
        return false;
      }
    }
    _points.add(normalized);
    _pressures.add(pressure.clamp(0.0, 1.0));
    _minX = math.min(_minX, normalized.dx);
    _minY = math.min(_minY, normalized.dy);
    _maxX = math.max(_maxX, normalized.dx);
    _maxY = math.max(_maxY, normalized.dy);
    return true;
  }

  /// 시작점과 끝점만 남겨 곧은 선으로 바꾼다. 직선 보정에 쓴다.
  void straighten() {
    if (_points.length < 2) return;
    final first = _points.first;
    final last = _points.last;
    final firstPressure = _pressures.first;
    final lastPressure = _pressures.last;
    _points
      ..clear()
      ..addAll([first, last]);
    _pressures
      ..clear()
      ..addAll([firstPressure, lastPressure]);
    _minX = math.min(first.dx, last.dx);
    _minY = math.min(first.dy, last.dy);
    _maxX = math.max(first.dx, last.dx);
    _maxY = math.max(first.dy, last.dy);
  }

  /// 직선 보정 뒤 손을 움직이면 끝점만 옮긴다.
  void moveEnd(Offset normalized) {
    if (_points.length < 2) return;
    _points[_points.length - 1] = normalized;
    final first = _points.first;
    _minX = math.min(first.dx, normalized.dx);
    _minY = math.min(first.dy, normalized.dy);
    _maxX = math.max(first.dx, normalized.dx);
    _maxY = math.max(first.dy, normalized.dy);
  }

  /// 시작점과 끝점을 잇는 선에서 크게 벗어나지 않았는지. 직선 보정은 이미
  /// 거의 곧게 그은 획에만 한다. 글씨를 쓰다가 잠깐 멈췄다고 '2' 같은 획이
  /// 곧은 선으로 바뀌면 안 되기 때문이다.
  bool isRoughlyStraight(Rect imageRect) {
    if (_points.length < 2) return false;
    Offset at(int i) => Offset(
          imageRect.left + _points[i].dx * imageRect.width,
          imageRect.top + _points[i].dy * imageRect.height,
        );
    final start = at(0);
    final end = at(_points.length - 1);
    final length = (end - start).distance;
    if (length == 0) return false;
    final tolerance = math.max(8.0, length * 0.12);
    for (var i = 1; i < _points.length - 1; i++) {
      if (_distanceToSegment(at(i), start, end) > tolerance) return false;
    }
    return true;
  }

  /// 화면 기준 경계 상자 대각선 길이. 직선 보정을 할 만큼 그었는지 본다.
  double screenExtent(Rect imageRect) {
    if (_points.isEmpty) return 0;
    final w = (_maxX - _minX) * imageRect.width;
    final h = (_maxY - _minY) * imageRect.height;
    return math.sqrt(w * w + h * h);
  }

  double _widthAt(int index) {
    if (!hasPressure) return width;
    final scale = minPressureScale +
        (maxPressureScale - minPressureScale) * _pressures[index];
    return width * scale;
  }

  Paint _paint({double? strokeWidth}) {
    final alpha = kind == InkKind.highlighter ? 0.35 : 1.0;
    return Paint()
      ..color = color.withValues(alpha: color.a * alpha)
      ..strokeWidth = strokeWidth ?? width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode = isEraser ? BlendMode.clear : BlendMode.srcOver;
  }

  /// [imageRect] 위에 이 획을 그린다.
  ///
  /// 점과 점 사이는 중간점을 기준으로 한 2차 곡선으로 이어서 빠르게 써도 꺾여
  /// 보이지 않게 한다. 필압이 있으면 구간마다 굵기를 달리해서 그린다.
  void paint(Canvas canvas, Rect imageRect) {
    if (_points.isEmpty) return;

    Offset at(int i) => Offset(
          imageRect.left + _points[i].dx * imageRect.width,
          imageRect.top + _points[i].dy * imageRect.height,
        );

    if (_points.length == 1) {
      canvas.drawCircle(
        at(0),
        _widthAt(0) / 2,
        _paint()..style = PaintingStyle.fill,
      );
      return;
    }

    if (!hasPressure) {
      canvas.drawPath(smoothPath(at), _paint());
      return;
    }

    // 필압이 있으면 한 구간씩 굵기를 바꿔 그린다. 끝이 둥글어서 이음매가
    // 보이지 않는다.
    var start = at(0);
    for (var i = 1; i < _points.length; i++) {
      final control = at(i);
      final end = i == _points.length - 1
          ? control
          : Offset.lerp(control, at(i + 1), 0.5)!;
      final segment = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
      canvas.drawPath(segment, _paint(strokeWidth: _widthAt(i)));
      start = end;
    }
  }

  /// 중간점 기준 2차 곡선으로 이은 경로. 테스트에서도 쓴다.
  Path smoothPath(Offset Function(int index) at) {
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    if (_points.length == 2) {
      return path..lineTo(at(1).dx, at(1).dy);
    }
    for (var i = 1; i < _points.length - 1; i++) {
      final control = at(i);
      final mid = Offset.lerp(control, at(i + 1), 0.5)!;
      path.quadraticBezierTo(control.dx, control.dy, mid.dx, mid.dy);
    }
    final last = at(_points.length - 1);
    return path..lineTo(last.dx, last.dy);
  }

  /// 화면 좌표 [point] 가 이 획에서 [radius] 안에 있는지. 획 지우개가 쓴다.
  bool hitTest(Offset point, double radius, Rect imageRect) {
    if (_points.isEmpty || isEraser) return false;

    final total = radius + width * maxPressureScale / 2;
    final bounds = Rect.fromLTRB(
      imageRect.left + _minX * imageRect.width,
      imageRect.top + _minY * imageRect.height,
      imageRect.left + _maxX * imageRect.width,
      imageRect.top + _maxY * imageRect.height,
    ).inflate(total);
    if (!bounds.contains(point)) return false;

    Offset at(int i) => Offset(
          imageRect.left + _points[i].dx * imageRect.width,
          imageRect.top + _points[i].dy * imageRect.height,
        );

    if (_points.length == 1) return (point - at(0)).distance <= total;
    for (var i = 0; i < _points.length - 1; i++) {
      if (_distanceToSegment(point, at(i), at(i + 1)) <= total) return true;
    }
    return false;
  }

  static double _distanceToSegment(Offset point, Offset start, Offset end) {
    final segment = end - start;
    final lengthSquared = segment.dx * segment.dx + segment.dy * segment.dy;
    if (lengthSquared == 0) return (point - start).distance;
    final t = (((point.dx - start.dx) * segment.dx +
                (point.dy - start.dy) * segment.dy) /
            lengthSquared)
        .clamp(0.0, 1.0);
    return (point - (start + segment * t)).distance;
  }
}
