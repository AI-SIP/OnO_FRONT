import 'InkStroke.dart';

/// 되돌리기 한 번에 해당하는 작업이다.
sealed class _InkOp {}

class _AddOp extends _InkOp {
  final InkStroke stroke;
  _AddOp(this.stroke);
}

/// 획 지우개로 한 번 문지르는 동안 지운 획들. 원래 자리(순서)도 같이 둔다.
class _EraseOp extends _InkOp {
  final List<(int, InkStroke)> removed;
  _EraseOp(this.removed);
}

class _ClearOp extends _InkOp {
  final List<InkStroke> strokes;
  _ClearOp(this.strokes);
}

/// 필기 한 페이지(문제 이미지 한 장 또는 연습장 한 장)의 확정된 획과 되돌리기
/// 기록이다.
///
/// 고치기 전에는 되돌리기가 목록의 마지막 획을 지우기만 해서, 획 지우개로 지운
/// 뒤 되돌리면 엉뚱한 획이 지워졌고 전체 지우기는 되돌릴 수 없었다. 이제는
/// 획 추가, 획 지우기, 전체 지우기가 각각 한 번의 되돌리기 단위다.
class InkPage {
  final List<InkStroke> _strokes = [];
  final List<_InkOp> _undo = [];
  final List<_InkOp> _redo = [];

  /// 획 지우개로 문지르는 중에 지운 것. 손을 떼면 한 작업으로 묶는다.
  final List<(int, InkStroke)> _pendingErase = [];

  /// 확정된 획이 바뀔 때마다 오른다. 그리기 층이 다시 녹화할지 판단한다.
  int version = 0;

  List<InkStroke> get strokes => List.unmodifiable(_strokes);

  bool get isEmpty => _strokes.isEmpty;

  /// 지우개 획을 빼고 실제로 쓴 획이 있는지.
  bool get hasInk => _strokes.any((s) => !s.isEraser);

  bool get hasEraserStroke => _strokes.any((s) => s.isEraser);

  bool get canUndo => _undo.isNotEmpty;

  bool get canRedo => _redo.isNotEmpty;

  void add(InkStroke stroke) {
    if (stroke.isEmpty) return;
    _strokes.add(stroke);
    _record(_AddOp(stroke));
  }

  /// [test] 에 맞는 획을 지운다. 손을 뗄 때 [commitErase] 로 한 작업이 된다.
  /// 지운 게 있으면 true.
  bool eraseWhere(bool Function(InkStroke stroke) test) {
    var removed = false;
    for (var i = _strokes.length - 1; i >= 0; i--) {
      if (test(_strokes[i])) {
        _pendingErase.add((i, _strokes.removeAt(i)));
        removed = true;
      }
    }
    if (removed) version++;
    return removed;
  }

  void commitErase() {
    if (_pendingErase.isEmpty) return;
    // 자리는 지울 그때의 목록 기준이다. 되살릴 때 지운 순서를 거꾸로 따라
    // 그 자리에 끼우면 원래 순서로 돌아온다.
    _record(_EraseOp(List.of(_pendingErase)));
    _pendingErase.clear();
  }

  void clear() {
    if (_strokes.isEmpty) return;
    final all = List.of(_strokes);
    _strokes.clear();
    _record(_ClearOp(all));
  }

  void undo() {
    if (_undo.isEmpty) return;
    final op = _undo.removeLast();
    switch (op) {
      case _AddOp(:final stroke):
        _strokes.remove(stroke);
      case _EraseOp(:final removed):
        for (final (index, stroke) in removed.reversed) {
          _strokes.insert(index.clamp(0, _strokes.length), stroke);
        }
      case _ClearOp(strokes: final all):
        _strokes
          ..clear()
          ..addAll(all);
    }
    _redo.add(op);
    version++;
  }

  void redo() {
    if (_redo.isEmpty) return;
    final op = _redo.removeLast();
    switch (op) {
      case _AddOp(:final stroke):
        _strokes.add(stroke);
      case _EraseOp(:final removed):
        for (final (_, stroke) in removed) {
          _strokes.remove(stroke);
        }
      case _ClearOp():
        _strokes.clear();
    }
    _undo.add(op);
    version++;
  }

  void _record(_InkOp op) {
    _undo.add(op);
    _redo.clear();
    version++;
  }
}
