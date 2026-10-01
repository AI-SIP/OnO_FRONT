import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'InkPage.dart';
import 'InkStroke.dart';

class _Signal extends ChangeNotifier {
  void ping() => notifyListeners();
}

/// 필기 화면의 페이지들과 지금 긋고 있는 획을 가진다.
///
/// 알림을 셋으로 나눈다. 펜이 움직일 때는 [live] 만 울려서 지금 획 층만 다시
/// 그리고, 확정된 획이 바뀔 때만 [committed] 를 울린다. 고치기 전에는 펜이
/// 한 점 움직일 때마다 화면 전체를 다시 만들고 모든 획을 처음부터 다시 그려서,
/// 많이 쓸수록 필기가 따라오지 못했다.
class InkController {
  final List<InkPage> pages;
  int _pageIndex = 0;

  final _committed = _Signal();
  final _live = _Signal();
  final _liveEraser = _Signal();

  InkStroke? _liveStroke;

  // 확정된 획을 그림 한 장으로 녹화해 둔다. 페이지마다 하나.
  final Map<InkPage, _PictureCache> _pictures = {};

  InkController({required int pageCount})
      : pages = List.generate(pageCount, (_) => InkPage());

  /// 확정된 획이 바뀔 때. 되돌리기 버튼처럼 확정 상태를 보는 곳도 듣는다.
  Listenable get committed => _committed;

  /// 지금 긋는 펜이나 형광펜 획이 움직일 때.
  Listenable get live => _live;

  /// 지금 긋는 부분 지우개 획이 움직일 때. 확정 층이 같이 다시 그려야 한다.
  Listenable get liveEraser => _liveEraser;

  int get pageIndex => _pageIndex;

  InkPage get page => pages[_pageIndex];

  InkStroke? get liveStroke => _liveStroke;

  bool get isStroking => _liveStroke != null;

  set pageIndex(int index) {
    if (index == _pageIndex || index < 0 || index >= pages.length) return;
    endStroke();
    _pageIndex = index;
    _committed.ping();
  }

  void beginStroke(
      InkStroke stroke, Offset normalized, double pressure, Rect imageRect) {
    cancelStroke();
    stroke.addPoint(normalized, pressure, imageRect, force: true);
    _liveStroke = stroke;
    _pingLive(stroke);
  }

  void extendStroke(Offset normalized, double pressure, Rect imageRect) {
    final stroke = _liveStroke;
    if (stroke == null) return;
    if (stroke.addPoint(normalized, pressure, imageRect)) _pingLive(stroke);
  }

  /// 지금 획을 곧은 선으로 바꾼다. 직선 보정에 쓴다.
  void straightenLiveStroke() {
    final stroke = _liveStroke;
    if (stroke == null || stroke.isEraser) return;
    stroke.straighten();
    _pingLive(stroke);
  }

  void endStroke() {
    final stroke = _liveStroke;
    if (stroke == null) return;
    _liveStroke = null;
    page.add(stroke);
    _pingLive(stroke);
    _committed.ping();
  }

  /// 확정하지 않고 버린다. 손가락으로 쓰다가 두 손가락 확대로 바뀔 때 쓴다.
  void cancelStroke() {
    final stroke = _liveStroke;
    if (stroke == null) return;
    _liveStroke = null;
    _pingLive(stroke);
  }

  /// 화면 좌표 [point] 근처의 획을 지운다.
  void eraseAt(Offset point, double radius, Rect imageRect) {
    if (page.eraseWhere((s) => s.hitTest(point, radius, imageRect))) {
      _committed.ping();
    }
  }

  void endErase() {
    page.commitErase();
    _committed.ping();
  }

  void undo() {
    endStroke();
    page.undo();
    _committed.ping();
  }

  void redo() {
    endStroke();
    page.redo();
    _committed.ping();
  }

  void clear() {
    endStroke();
    page.clear();
    _committed.ping();
  }

  void _pingLive(InkStroke stroke) {
    if (stroke.isEraser) {
      _liveEraser.ping();
    } else {
      _live.ping();
    }
  }

  /// [page] 의 확정된 획을 녹화한 그림. 획이나 이미지 자리가 바뀌었을 때만
  /// 다시 녹화한다.
  ui.Picture pictureFor(InkPage page, Rect imageRect, Size size) {
    final cached = _pictures[page];
    if (cached != null &&
        cached.version == page.version &&
        cached.imageRect == imageRect &&
        cached.size == size) {
      return cached.picture;
    }
    cached?.picture.dispose();

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final strokes = page.strokes;
    final hasEraser = page.hasEraserStroke;
    // 부분 지우개는 BlendMode.clear 로 그려서, 레이어 없이 그리면 아래 문제
    // 이미지까지 뚫는다. 지우개 획이 있을 때만 레이어를 쓴다.
    if (hasEraser) canvas.saveLayer(Offset.zero & size, ui.Paint());
    if (hasEraser) {
      // 지우개가 있으면 그린 순서가 중요해서 순서대로 그린다.
      for (final stroke in strokes) {
        stroke.paint(canvas, imageRect);
      }
    } else {
      // 형광펜은 다른 획 아래에 깔리게 먼저 그린다.
      for (final stroke in strokes) {
        if (stroke.kind == InkKind.highlighter) stroke.paint(canvas, imageRect);
      }
      for (final stroke in strokes) {
        if (stroke.kind != InkKind.highlighter) stroke.paint(canvas, imageRect);
      }
    }
    if (hasEraser) canvas.restore();

    final picture = recorder.endRecording();
    _pictures[page] = _PictureCache(
      picture: picture,
      version: page.version,
      imageRect: imageRect,
      size: size,
    );
    return picture;
  }

  void dispose() {
    for (final cache in _pictures.values) {
      cache.picture.dispose();
    }
    _pictures.clear();
    _committed.dispose();
    _live.dispose();
    _liveEraser.dispose();
  }
}

class _PictureCache {
  final ui.Picture picture;
  final int version;
  final Rect imageRect;
  final Size size;

  _PictureCache({
    required this.picture,
    required this.version,
    required this.imageRect,
    required this.size,
  });
}
