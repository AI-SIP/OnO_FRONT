import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../Module/Dialog/SnackBarDialog.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import 'ProblemSolveRegisterScreen.dart';

class ProblemSolveCanvasScreen extends StatefulWidget {
  final int problemId;
  final String problemImageUrl;
  final VoidCallback onRefresh;

  const ProblemSolveCanvasScreen({
    super.key,
    required this.problemId,
    required this.problemImageUrl,
    required this.onRefresh,
  });

  @override
  State<ProblemSolveCanvasScreen> createState() =>
      _ProblemSolveCanvasScreenState();
}

enum _CanvasTool {
  pen,
  pixelEraser,
  strokeEraser,
  move,
}

class _ProblemSolveCanvasScreenState extends State<ProblemSolveCanvasScreen> {
  final GlobalKey _captureKey = GlobalKey();
  final TransformationController _transformationController =
      TransformationController();
  final List<_DrawStroke> _strokes = [];
  _DrawStroke? _currentStroke;
  Timer? _timer;
  int _activePointers = 0;
  int _elapsedSeconds = 0;
  bool _isSubmitting = false;
  bool _isImageReady = false;
  Size _canvasSize = Size.zero;
  Size? _imageNaturalSize;
  Color _penColor = Colors.black87;
  double _penWidth = 4.0;
  double _eraserWidth = 18.0;
  _CanvasTool _selectedTool = _CanvasTool.pen;
  _CanvasTool _previousTool = _CanvasTool.pen;
  Offset? _cursorPosition; // canvas-space position for eraser cursor overlay

  static const _pencilChannel = MethodChannel('com.aisip.ono/pencil_events');

  static const List<Color> _paletteColors = [
    Colors.black87,
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFEAB308),
    Color(0xFF22C55E),
    Color(0xFF14B8A6),
    Color(0xFF3B82F6),
    Color(0xFF6366F1),
    Color(0xFFA855F7),
    Color(0xFFEC4899),
    Color(0xFF64748B),
    Color(0xFF8B5E34),
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
    _loadImageNaturalSize();
    _subscribeToPencilEvents();
  }

  void _subscribeToPencilEvents() {
    if (!Platform.isIOS) return;
    _pencilChannel.setMethodCallHandler((call) async {
      if (call.method == 'doubleTap' && mounted) {
        setState(() => _toggleToLastTool());
      }
    });
  }

  void _loadImageNaturalSize() {
    final stream = NetworkImage(widget.problemImageUrl)
        .resolve(ImageConfiguration.empty);
    stream.addListener(ImageStreamListener((info, _) {
      if (mounted) {
        setState(() {
          _imageNaturalSize = Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          );
        });
      }
    }));
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  @override
  void dispose() {
    if (Platform.isIOS) _pencilChannel.setMethodCallHandler(null);
    _timer?.cancel();
    _transformationController.dispose();
    super.dispose();
  }

  // Computes the actual displayed rect of the image within the canvas
  // (accounting for BoxFit.contain letterboxing/pillarboxing).
  Rect _computeImageRect(Size canvasSize) {
    final imgSize = _imageNaturalSize;
    if (imgSize == null || canvasSize == Size.zero) {
      return Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height);
    }
    final imageRatio = imgSize.width / imgSize.height;
    final canvasRatio = canvasSize.width / canvasSize.height;

    double imageW, imageH;
    if (canvasRatio > imageRatio) {
      imageH = canvasSize.height;
      imageW = imageH * imageRatio;
    } else {
      imageW = canvasSize.width;
      imageH = imageW / imageRatio;
    }

    return Rect.fromLTWH(
      (canvasSize.width - imageW) / 2,
      (canvasSize.height - imageH) / 2,
      imageW,
      imageH,
    );
  }

  // Converts a canvas-space point to image-normalized [0,1] coordinates.
  Offset _toNormalized(Offset canvasPoint, Rect imageRect) {
    return Offset(
      (canvasPoint.dx - imageRect.left) / imageRect.width,
      (canvasPoint.dy - imageRect.top) / imageRect.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: StandardText(
          text: _formatElapsedTime(_elapsedSeconds),
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: themeProvider.primaryColor,
        ),
        actions: [
          IconButton(
            tooltip: '확대 초기화',
            onPressed: _resetZoom,
            icon: Icon(Icons.center_focus_strong,
                color: themeProvider.primaryColor),
          ),
          IconButton(
            tooltip: '되돌리기',
            onPressed: _strokes.isEmpty ? null : _undoLastStroke,
            icon: Icon(Icons.undo, color: themeProvider.primaryColor),
          ),
          IconButton(
            tooltip: '전체 지우기',
            onPressed: _strokes.isEmpty ? null : _clearStrokes,
            icon: Icon(Icons.delete_outline, color: themeProvider.primaryColor),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final newSize =
                      Size(constraints.maxWidth, constraints.maxHeight);
                  if (newSize != _canvasSize) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() => _onCanvasSizeChanged(newSize));
                      }
                    });
                  }
                  final imageRect = _computeImageRect(newSize);
                  return InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 1,
                    maxScale: 4,
                    panEnabled: _selectedTool == _CanvasTool.move,
                    scaleEnabled: true,
                    boundaryMargin: const EdgeInsets.all(80),
                    child: Listener(
                      onPointerDown: (event) {
                        // Apple Pencil 2 flat-side tap / S Pen side button
                        if (event.kind == PointerDeviceKind.stylus &&
                            event.buttons & kSecondaryStylusButton != 0) {
                          setState(() => _toggleToLastTool());
                          return;
                        }
                        _handlePointerDown(event.localPosition, imageRect);
                      },
                      onPointerMove: (event) =>
                          _handlePointerMove(event.localPosition, imageRect),
                      onPointerHover: (event) {
                        if (_isEraserTool) {
                          setState(() =>
                              _cursorPosition = event.localPosition);
                        }
                      },
                      onPointerUp: (_) => _handlePointerEnd(),
                      onPointerCancel: (_) => _handlePointerEnd(),
                      child: Stack(
                        children: [
                          RepaintBoundary(
                        key: _captureKey,
                        child: Container(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          color: Colors.white,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                widget.problemImageUrl,
                                fit: BoxFit.contain,
                                frameBuilder: (
                                  context,
                                  child,
                                  frame,
                                  wasSynchronouslyLoaded,
                                ) {
                                  if (wasSynchronouslyLoaded || frame != null) {
                                    _markImageReady();
                                  }
                                  return child;
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: themeProvider.primaryColor,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: StandardText(
                                      text: '문제 이미지를 불러오지 못했습니다.',
                                      fontSize: 14,
                                      color: themeProvider.primaryColor,
                                    ),
                                  );
                                },
                              ),
                              CustomPaint(
                                size: Size(
                                  constraints.maxWidth,
                                  constraints.maxHeight,
                                ),
                                painter: _DrawingPainter(
                                  strokes: _strokes,
                                  imageRect: imageRect,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                          // Eraser cursor overlay — outside RepaintBoundary so
                          // it does not appear in the captured screenshot.
                          if (_isEraserTool && _cursorPosition != null)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _EraserCursorPainter(
                                    position: _cursorPosition!,
                                    radius: math.max(
                                        14.0, _eraserWidth + 8),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          _buildToolbar(themeProvider),
          _buildSubmitButton(themeProvider),
        ],
      ),
    );
  }

  Widget _buildToolbar(ThemeHandler themeProvider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildToolModeButton(
                        icon: Icons.open_with,
                        label: '이동',
                        isSelected: _selectedTool == _CanvasTool.move,
                        themeProvider: themeProvider,
                        onTap: () =>
                            setState(() => _setTool(_CanvasTool.move)),
                      ),
                      const SizedBox(width: 8),
                      _buildToolModeButton(
                        icon: Icons.edit,
                        label: '펜',
                        isSelected: _selectedTool == _CanvasTool.pen,
                        themeProvider: themeProvider,
                        onTap: () =>
                            setState(() => _setTool(_CanvasTool.pen)),
                      ),
                      const SizedBox(width: 8),
                      _buildToolModeButton(
                        icon: Icons.cleaning_services_outlined,
                        label: '부분 지우개',
                        isSelected: _selectedTool == _CanvasTool.pixelEraser,
                        themeProvider: themeProvider,
                        onTap: () => setState(
                          () => _setTool(_CanvasTool.pixelEraser),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildToolModeButton(
                        icon: Icons.auto_fix_off,
                        label: '획 지우개',
                        isSelected: _selectedTool == _CanvasTool.strokeEraser,
                        themeProvider: themeProvider,
                        onTap: () => setState(
                          () => _setTool(_CanvasTool.strokeEraser),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _paletteColors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 9),
              itemBuilder: (context, index) {
                return _buildColorButton(_paletteColors[index]);
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const StandardText(
                text: '굵기',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 10),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 18),
                  ),
                  child: Slider(
                    value: _currentStrokeWidth,
                    min: _isEraserTool ? 2.0 : 0.5,
                    max: _isEraserTool ? 48.0 : 18.0,
                    divisions: _isEraserTool ? 46 : 35,
                    activeColor: themeProvider.primaryColor,
                    inactiveColor: Colors.grey[200],
                    label: _widthLabel(_currentStrokeWidth),
                    onChanged: _selectedTool == _CanvasTool.move
                        ? null
                        : (value) => setState(() {
                              if (_isEraserTool) {
                                _eraserWidth = value;
                              } else {
                                _penWidth = value;
                              }
                            }),
                  ),
                ),
              ),
              SizedBox(
                width: 34,
                child: StandardText(
                  text: _widthLabel(_currentStrokeWidth),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.primaryColor,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolModeButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required ThemeHandler themeProvider,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? themeProvider.primaryColor : Colors.grey[600]!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? themeProvider.primaryColor.withOpacity(0.12)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? themeProvider.primaryColor.withOpacity(0.35)
                : Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            StandardText(
              text: label,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    final isSelected = _selectedTool == _CanvasTool.pen && _penColor == color;

    return InkWell(
      onTap: () => setState(() {
        _penColor = color;
        _setTool(_CanvasTool.pen);
      }),
      borderRadius: BorderRadius.circular(19),
      child: Container(
        width: 38,
        height: 38,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black87 : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ThemeHandler themeProvider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isSubmitting || !_isImageReady
              ? null
              : () => _submit(themeProvider),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeProvider.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: StandardText(
            text: _isSubmitting
                ? '풀이 이미지 저장 중...'
                : _isImageReady
                    ? '풀이 제출하기'
                    : '문제 이미지 불러오는 중...',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  bool get _isEraserTool =>
      _selectedTool == _CanvasTool.pixelEraser ||
      _selectedTool == _CanvasTool.strokeEraser;

  double get _currentStrokeWidth =>
      _isEraserTool ? _eraserWidth : _penWidth;

  String _widthLabel(double width) {
    return width < 1 ? width.toStringAsFixed(1) : width.round().toString();
  }

  void _setTool(_CanvasTool tool) {
    if (tool != _selectedTool) {
      _previousTool = _selectedTool;
      _selectedTool = tool;
    }
    _cursorPosition = null;
  }

  void _toggleToLastTool() {
    final temp = _previousTool;
    _previousTool = _selectedTool;
    _selectedTool = temp;
  }

  void _handlePointerDown(Offset point, Rect imageRect) {
    _activePointers++;

    if (_selectedTool == _CanvasTool.move) return;
    if (_activePointers > 1) {
      _finishStroke();
      return;
    }

    if (_isEraserTool) _cursorPosition = point;

    final normalized = _toNormalized(point, imageRect);

    if (_selectedTool == _CanvasTool.strokeEraser) {
      _eraseStrokeAt(normalized, imageRect);
      return;
    }

    _startStroke(normalized);
  }

  void _handlePointerMove(Offset point, Rect imageRect) {
    if (_selectedTool == _CanvasTool.move || _activePointers > 1) return;

    if (_isEraserTool) _cursorPosition = point;

    final normalized = _toNormalized(point, imageRect);

    if (_selectedTool == _CanvasTool.strokeEraser) {
      _eraseStrokeAt(normalized, imageRect);
      return;
    }

    _appendStroke(normalized);
  }

  void _handlePointerEnd() {
    _activePointers = math.max(0, _activePointers - 1);
    setState(() => _cursorPosition = null);
    _finishStroke();
  }

  void _startStroke(Offset normalizedPoint) {
    setState(() {
      _currentStroke = _DrawStroke(
        points: [normalizedPoint],
        color: _penColor,
        width: _currentStrokeWidth,
        isEraser: _selectedTool == _CanvasTool.pixelEraser,
      );
      _strokes.add(_currentStroke!);
    });
  }

  void _appendStroke(Offset normalizedPoint) {
    if (_currentStroke == null) return;

    setState(() {
      _currentStroke!.points.add(normalizedPoint);
    });
  }

  void _finishStroke() {
    _currentStroke = null;
  }

  // normalizedPoint and stroke points are both in image-normalized [0,1] space.
  // eraseRadius is passed in canvas pixels and converted to normalized units for comparison.
  void _eraseStrokeAt(Offset normalizedPoint, Rect imageRect) {
    final eraseRadiusCanvas = math.max(14.0, _eraserWidth + 8);
    // Use the shorter image dimension to convert radius to normalized space.
    final imageShortSide = math.min(imageRect.width, imageRect.height);
    final eraseRadiusNorm = eraseRadiusCanvas / imageShortSide;

    setState(() {
      _strokes.removeWhere((stroke) {
        if (stroke.isEraser) return false;
        // stroke.width is in canvas pixels; convert to normalized for comparison.
        final strokeWidthNorm = stroke.width / imageShortSide;
        return _isPointNearStroke(
            normalizedPoint, stroke, eraseRadiusNorm + strokeWidthNorm / 2);
      });
    });
  }

  bool _isPointNearStroke(
    Offset point,
    _DrawStroke stroke,
    double radius,
  ) {
    if (stroke.points.isEmpty) return false;

    if (stroke.points.length == 1) {
      return (point - stroke.points.first).distance <= radius;
    }

    for (var i = 0; i < stroke.points.length - 1; i++) {
      final distance = _distanceToSegment(
        point,
        stroke.points[i],
        stroke.points[i + 1],
      );
      if (distance <= radius) return true;
    }

    return false;
  }

  double _distanceToSegment(Offset point, Offset start, Offset end) {
    final segment = end - start;
    final lengthSquared = segment.dx * segment.dx + segment.dy * segment.dy;

    if (lengthSquared == 0) {
      return (point - start).distance;
    }

    final t = (((point.dx - start.dx) * segment.dx +
                (point.dy - start.dy) * segment.dy) /
            lengthSquared)
        .clamp(0.0, 1.0);
    final projection = Offset(
      start.dx + segment.dx * t,
      start.dy + segment.dy * t,
    );

    return (point - projection).distance;
  }

  void _undoLastStroke() {
    setState(() {
      if (_strokes.isNotEmpty) {
        _strokes.removeLast();
      }
    });
  }

  void _clearStrokes() {
    setState(_strokes.clear);
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  // Points are stored in image-normalized coordinates, so no re-scaling needed
  // on orientation change — just update canvas size and reset zoom.
  void _onCanvasSizeChanged(Size newSize) {
    if (newSize == _canvasSize || newSize == Size.zero) return;
    if (_canvasSize != Size.zero) {
      _resetZoom();
    }
    _canvasSize = newSize;
  }

  void _markImageReady() {
    if (_isImageReady) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isImageReady) {
        setState(() => _isImageReady = true);
      }
    });
  }

  Future<void> _submit(ThemeHandler themeProvider) async {
    if (!_isImageReady) return;

    setState(() => _isSubmitting = true);

    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;

      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError('capture boundary is not ready');
      }

      final image = await boundary.toImage(pixelRatio: 2);
      ByteData? byteData;
      try {
        byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      } finally {
        image.dispose();
      }
      if (byteData == null) {
        throw StateError('failed to create image data');
      }

      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/problem_solve_${widget.problemId}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

      _timer?.cancel();

      if (!mounted) return;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProblemSolveRegisterScreen(
            problemId: widget.problemId,
            onRefresh: widget.onRefresh,
            initialSolutionImages: [file],
            initialTimeSpentSeconds: _elapsedSeconds,
          ),
        ),
      );

      if (result == true && mounted) {
        Navigator.of(context).pop(true);
      } else if (mounted) {
        setState(() => _isSubmitting = false);
        _startTimer();
      }
    } catch (e) {
      if (!mounted) return;

      SnackBarDialog.showSnackBar(
        context: context,
        message: '풀이 이미지를 저장하지 못했습니다. 잠시 후 다시 시도해주세요.',
        backgroundColor: Colors.red,
      );
      setState(() => _isSubmitting = false);
    }
  }

  String _formatElapsedTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _DrawStroke {
  final List<Offset> points; // image-normalized [0,1] coordinates
  final Color color;
  final double width; // canvas pixels at time of drawing
  final bool isEraser;

  _DrawStroke({
    required this.points,
    required this.color,
    required this.width,
    required this.isEraser,
  });
}

class _DrawingPainter extends CustomPainter {
  final List<_DrawStroke> strokes;
  final Rect imageRect;

  _DrawingPainter({required this.strokes, required this.imageRect});

  Offset _denormalize(Offset normalized) {
    return Offset(
      imageRect.left + normalized.dx * imageRect.width,
      imageRect.top + normalized.dy * imageRect.height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Image boundary indicator
    canvas.drawRect(
      imageRect,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.saveLayer(Offset.zero & size, Paint());

    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final pts = stroke.points.map(_denormalize).toList();

      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..blendMode = stroke.isEraser ? BlendMode.clear : BlendMode.srcOver;

      if (pts.length == 1) {
        final dotPaint = Paint()
          ..color = stroke.color
          ..style = PaintingStyle.fill
          ..blendMode = stroke.isEraser ? BlendMode.clear : BlendMode.srcOver;
        canvas.drawCircle(pts.first, stroke.width / 2, dotPaint);
      } else {
        final path = Path()..moveTo(pts.first.dx, pts.first.dy);
        for (final point in pts.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
        canvas.drawPath(path, paint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) {
    return true;
  }
}

class _EraserCursorPainter extends CustomPainter {
  final Offset position;
  final double radius;

  _EraserCursorPainter({required this.position, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final circlePaint = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(position, radius, circlePaint);

    // Crosshair at center for precise positioning
    final crossPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 1.0;
    const crossSize = 4.0;
    canvas.drawLine(
      Offset(position.dx - crossSize, position.dy),
      Offset(position.dx + crossSize, position.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(position.dx, position.dy - crossSize),
      Offset(position.dx, position.dy + crossSize),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _EraserCursorPainter oldDelegate) {
    return position != oldDelegate.position || radius != oldDelegate.radius;
  }
}