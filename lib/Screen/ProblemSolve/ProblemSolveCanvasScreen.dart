import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

class _ProblemSolveCanvasScreenState extends State<ProblemSolveCanvasScreen> {
  final GlobalKey _captureKey = GlobalKey();
  final List<_DrawStroke> _strokes = [];
  _DrawStroke? _currentStroke;
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isSubmitting = false;
  bool _isImageReady = false;
  Color _penColor = Colors.black87;
  double _penWidth = 4.0;
  bool _isEraserMode = false;

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
    _timer?.cancel();
    super.dispose();
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
              child: RepaintBoundary(
                key: _captureKey,
                child: Container(
                  color: Colors.white,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onPanStart: (details) =>
                            _startStroke(details.localPosition),
                        onPanUpdate: (details) =>
                            _appendStroke(details.localPosition),
                        onPanEnd: (_) => _finishStroke(),
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
                              painter: _DrawingPainter(strokes: _strokes),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
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
              _buildToolModeButton(
                icon: Icons.edit,
                label: '펜',
                isSelected: !_isEraserMode,
                themeProvider: themeProvider,
                onTap: () => setState(() => _isEraserMode = false),
              ),
              const SizedBox(width: 8),
              _buildToolModeButton(
                icon: Icons.cleaning_services_outlined,
                label: '지우개',
                isSelected: _isEraserMode,
                themeProvider: themeProvider,
                onTap: () => setState(() => _isEraserMode = true),
              ),
              const Spacer(),
              _buildStrokePreview(themeProvider),
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
                    value: _penWidth,
                    min: 2,
                    max: 18,
                    divisions: 16,
                    activeColor: themeProvider.primaryColor,
                    inactiveColor: Colors.grey[200],
                    label: _penWidth.round().toString(),
                    onChanged: (value) => setState(() => _penWidth = value),
                  ),
                ),
              ),
              SizedBox(
                width: 34,
                child: StandardText(
                  text: _penWidth.round().toString(),
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
    final isSelected = !_isEraserMode && _penColor == color;

    return InkWell(
      onTap: () => setState(() {
        _penColor = color;
        _isEraserMode = false;
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

  Widget _buildStrokePreview(ThemeHandler themeProvider) {
    final previewColor = _isEraserMode ? Colors.white : _penColor;

    return Container(
      width: 52,
      height: 38,
      decoration: BoxDecoration(
        color: _isEraserMode ? Colors.grey[100] : previewColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Center(
        child: Container(
          width: _penWidth.clamp(2, 18),
          height: _penWidth.clamp(2, 18),
          decoration: BoxDecoration(
            color: previewColor,
            shape: BoxShape.circle,
            border: _isEraserMode
                ? Border.all(color: themeProvider.primaryColor, width: 1)
                : null,
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

  void _startStroke(Offset point) {
    setState(() {
      _currentStroke = _DrawStroke(
        points: [point],
        color: _penColor,
        width: _penWidth,
        isEraser: _isEraserMode,
      );
      _strokes.add(_currentStroke!);
    });
  }

  void _appendStroke(Offset point) {
    if (_currentStroke == null) return;

    setState(() {
      _currentStroke!.points.add(point);
    });
  }

  void _finishStroke() {
    _currentStroke = null;
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

      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError('capture boundary is not ready');
      }

      final image = await boundary.toImage(pixelRatio: 2);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
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
  final List<Offset> points;
  final Color color;
  final double width;
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

  _DrawingPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());

    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..blendMode = stroke.isEraser ? BlendMode.clear : BlendMode.srcOver;

      final path = Path()
        ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (final point in stroke.points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }

      if (stroke.points.length == 1) {
        final dotPaint = Paint()
          ..color = stroke.color
          ..style = PaintingStyle.fill
          ..blendMode = stroke.isEraser ? BlendMode.clear : BlendMode.srcOver;
        canvas.drawCircle(stroke.points.first, stroke.width / 2, dotPaint);
      } else {
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
