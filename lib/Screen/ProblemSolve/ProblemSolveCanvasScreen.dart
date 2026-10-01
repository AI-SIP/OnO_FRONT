import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../Module/Dialog/SnackBarDialog.dart';
import '../../Module/Text/mobile_font_size.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Util/AppAnalytics.dart';
import 'Canvas/InkController.dart';
import 'Canvas/InkInputRouter.dart';
import 'Canvas/InkPainters.dart';
import 'Canvas/InkStroke.dart';
import 'ProblemSolveRegisterScreen.dart';
import '../../Module/Motion/AppHaptic.dart';
import '../../Module/Motion/PressableScale.dart';
import '../../Module/Motion/TossPageRoute.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppColors.dart';

class ProblemSolveCanvasScreen extends StatefulWidget {
  final int problemId;
  final List<String> problemImageUrls;
  final VoidCallback onRefresh;

  const ProblemSolveCanvasScreen({
    super.key,
    required this.problemId,
    required this.problemImageUrls,
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
  // 획과 되돌리기 기록. 펜이 움직일 때 setState 없이 그리기 층만 다시 그린다.
  late final InkController _ink;
  final InkInputRouter _router = InkInputRouter();
  final InkTransformTracker _tracker = InkTransformTracker();
  late final List<bool> _imageReadyStates;
  late final List<bool> _imageErrorStates;
  late final List<Size?> _imageNaturalSizes;
  Timer? _timer;
  int _currentImageIndex = 0;

  // 타이머와 지우개 커서는 그 칸만 다시 그린다.
  final ValueNotifier<int> _elapsed = ValueNotifier(0);
  final ValueNotifier<Offset?> _cursor = ValueNotifier(null);

  // 펜이 감지돼 손가락 필기를 처음 막았을 때 한 번만 띄우는 안내.
  final ValueNotifier<bool> _palmNotice = ValueNotifier(false);
  bool _palmNoticeShown = false;
  Timer? _palmNoticeTimer;

  // 획 지우개로 문지르는 중인지. 손을 떼면 한 번의 되돌리기 단위로 묶는다.
  bool _erasing = false;

  // 포인터마다 마지막 위치. 손가락으로 쓰다가 두 손가락 확대로 바뀔 때 첫
  // 손가락의 위치가 필요하다.
  final Map<int, Offset> _pointerPositions = {};
  bool _isSubmitting = false;
  Size _canvasSize = Size.zero;
  Color _penColor = Colors.black87;
  double _penWidth = 4.0;
  double _eraserWidth = 18.0;
  _CanvasTool _selectedTool = _CanvasTool.pen;
  _CanvasTool _previousTool = _CanvasTool.pen;

  // Analytics 용. 도구를 바꿀 때마다 남기면 이벤트가 너무 많아서, 한 번 푸는
  // 동안 무엇을 썼는지 모아 두었다가 제출하거나 나갈 때 한 번에 남긴다.
  final Set<String> _usedTools = {_CanvasTool.pen.name};
  bool _usedStylus = false;
  bool _usedStylusButton = false;
  bool _changedColor = false;
  bool _changedWidth = false;
  int _undoCount = 0;
  int _redoCount = 0;
  bool _cleared = false;
  bool _submitted = false;

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
    AppAnalytics.logScreenView('ProblemSolveCanvasScreen');
    _ink = InkController(pageCount: widget.problemImageUrls.length);
    _imageReadyStates =
        List.generate(widget.problemImageUrls.length, (_) => false);
    _imageErrorStates =
        List.generate(widget.problemImageUrls.length, (_) => false);
    _imageNaturalSizes =
        List.generate(widget.problemImageUrls.length, (_) => null);
    _startTimer();
    _loadImageNaturalSize(_currentImageIndex);
    _subscribeToPencilEvents();
  }

  void _subscribeToPencilEvents() {
    if (!Platform.isIOS) return;
    _pencilChannel.setMethodCallHandler((call) async {
      if (call.method == 'doubleTap' && mounted) {
        _usedStylusButton = true;
        setState(() => _toggleToLastTool());
      }
    });
  }

  bool get _isCurrentImageReady => _imageReadyStates[_currentImageIndex];

  bool get _hasImageLoadError => _imageErrorStates.contains(true);

  String get _currentImageUrl => widget.problemImageUrls[_currentImageIndex];

  void _loadImageNaturalSize(int imageIndex) {
    if (_imageNaturalSizes[imageIndex] != null) return;

    final stream = NetworkImage(widget.problemImageUrls[imageIndex])
        .resolve(ImageConfiguration.empty);
    stream.addListener(ImageStreamListener((info, _) {
      if (mounted) {
        setState(() {
          _imageNaturalSizes[imageIndex] = Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          );
        });
      }
    }, onError: (_, __) {
      if (mounted) {
        setState(() => _imageErrorStates[imageIndex] = true);
      }
    }));
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _elapsed.value++;
    });
  }

  @override
  void dispose() {
    // 풀다가 제출하지 않고 나간 것. 어디까지 쓰다 그만두는지 본다.
    if (!_submitted) _logCanvasSession('canvas_abandon');
    if (Platform.isIOS) _pencilChannel.setMethodCallHandler(null);
    _timer?.cancel();
    _palmNoticeTimer?.cancel();
    _transformationController.dispose();
    _ink.dispose();
    _elapsed.dispose();
    _cursor.dispose();
    _palmNotice.dispose();
    super.dispose();
  }

  // Computes the actual displayed rect of the image within the canvas
  // (accounting for BoxFit.contain letterboxing/pillarboxing).
  Rect _computeImageRect(Size canvasSize) {
    final imgSize = _imageNaturalSizes[_currentImageIndex];
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
        // 타이머는 매초 바뀌어서 이 칸만 다시 그린다. 고치기 전에는 1초마다
        // 화면 전체를 다시 만들었다.
        title: ValueListenableBuilder<int>(
          valueListenable: _elapsed,
          builder: (context, seconds, _) => StandardText(
            text: _formatElapsedTime(seconds),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: themeProvider.primaryColor,
          ),
        ),
        actions: [
          IconButton(
            tooltip: '확대 초기화',
            onPressed: _resetZoom,
            icon: Icon(Icons.center_focus_strong,
                color: themeProvider.primaryColor),
          ),
          ListenableBuilder(
            listenable: _ink.committed,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: '되돌리기',
                  onPressed: _ink.page.canUndo ? _undo : null,
                  icon: Icon(Icons.undo, color: themeProvider.primaryColor),
                ),
                IconButton(
                  tooltip: '다시 실행',
                  onPressed: _ink.page.canRedo ? _redo : null,
                  icon: Icon(Icons.redo, color: themeProvider.primaryColor),
                ),
                IconButton(
                  tooltip: '전체 지우기',
                  onPressed: _ink.page.isEmpty ? null : _clearStrokes,
                  icon: Icon(Icons.delete_outline,
                      color: themeProvider.primaryColor),
                ),
              ],
            ),
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
                  final imageIndex = _currentImageIndex;
                  final imageUrl = _currentImageUrl;
                  final page = _ink.pages[imageIndex];
                  // 포인터는 확대 뷰 바깥에서 받는다. 그래야 화면 좌표로 두
                  // 손가락 확대를 계산할 수 있고, 필기 좌표는 toScene 으로 바꾼다.
                  return Listener(
                    onPointerDown: (event) =>
                        _onPointerDown(event, imageRect, newSize),
                    onPointerMove: (event) =>
                        _onPointerMove(event, imageRect, newSize),
                    onPointerUp: (event) => _onPointerEnd(event),
                    onPointerCancel: (event) => _onPointerEnd(event),
                    onPointerHover: (event) {
                      final forceErase =
                          event.kind == PointerDeviceKind.stylus &&
                              event.buttons & kPrimaryStylusButton != 0;
                      if (_isEraserTool || forceErase) {
                        _cursor.value = _transformationController
                            .toScene(event.localPosition);
                      }
                    },
                    child: Stack(
                      children: [
                        InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: 1,
                          maxScale: 4,
                          // 펜 도구일 때는 확대와 이동을 직접 계산한다. 이동
                          // 도구일 때만 InteractiveViewer 에 맡긴다.
                          panEnabled: _selectedTool == _CanvasTool.move,
                          scaleEnabled: _selectedTool == _CanvasTool.move,
                          boundaryMargin: const EdgeInsets.all(80),
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
                                        imageUrl,
                                        fit: BoxFit.contain,
                                        frameBuilder: (
                                          context,
                                          child,
                                          frame,
                                          wasSynchronouslyLoaded,
                                        ) {
                                          if (wasSynchronouslyLoaded ||
                                              frame != null) {
                                            _markImageReady(imageIndex);
                                          }
                                          return child;
                                        },
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return Center(
                                            child: CircularProgressIndicator(
                                              color: themeProvider.primaryColor,
                                            ),
                                          );
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          _markImageError(imageIndex);
                                          return Center(
                                            child: StandardText(
                                              text: '문제 이미지를 불러오지 못했습니다.',
                                              fontSize: 14,
                                              color: themeProvider.primaryColor,
                                            ),
                                          );
                                        },
                                      ),
                                      // 확정된 획과 지금 긋는 획을 따로 그린다.
                                      // 펜이 움직일 때는 아래 층만 다시 그린다.
                                      RepaintBoundary(
                                        child: CustomPaint(
                                          size: newSize,
                                          painter: CommittedInkPainter(
                                            controller: _ink,
                                            page: page,
                                            imageRect: imageRect,
                                          ),
                                        ),
                                      ),
                                      RepaintBoundary(
                                        child: CustomPaint(
                                          size: newSize,
                                          painter: LiveInkPainter(
                                            controller: _ink,
                                            page: page,
                                            imageRect: imageRect,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // 지우개 커서. 캡처 영역 밖이라 사진에는 안 찍힌다.
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: ValueListenableBuilder<Offset?>(
                                    valueListenable: _cursor,
                                    builder: (context, position, _) =>
                                        position == null
                                            ? const SizedBox.shrink()
                                            : CustomPaint(
                                                painter: _EraserCursorPainter(
                                                  position: position,
                                                  radius: math.max(
                                                      7.0, _eraserWidth / 2),
                                                ),
                                              ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildPalmNotice(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          _buildImageNavigation(themeProvider),
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
                        onTap: () => setState(() => _setTool(_CanvasTool.move)),
                      ),
                      const SizedBox(width: 8),
                      _buildToolModeButton(
                        icon: Icons.edit,
                        label: '펜',
                        isSelected: _selectedTool == _CanvasTool.pen,
                        themeProvider: themeProvider,
                        onTap: () => setState(() => _setTool(_CanvasTool.pen)),
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
              StandardText(
                text: '굵기',
                fontSize: MobileFontSize.reduced(context, 13),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
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
                              _changedWidth = true;
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

  Widget _buildImageNavigation(ThemeHandler themeProvider) {
    if (widget.problemImageUrls.length <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
      color: Colors.white,
      child: Row(
        children: [
          _buildImageMoveButton(
            icon: Icons.chevron_left,
            label: '이전',
            enabled: _currentImageIndex > 0 && !_isSubmitting,
            themeProvider: themeProvider,
            onTap: () => _moveToImage(_currentImageIndex - 1),
          ),
          Expanded(
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: themeProvider.primaryColor.withOpacity(0.18),
                    width: 1,
                  ),
                ),
                child: StandardText(
                  text:
                      '${_currentImageIndex + 1} / ${widget.problemImageUrls.length}',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.primaryColor,
                ),
              ),
            ),
          ),
          _buildImageMoveButton(
            icon: Icons.chevron_right,
            label: '다음',
            enabled: _currentImageIndex < widget.problemImageUrls.length - 1 &&
                !_isSubmitting,
            themeProvider: themeProvider,
            onTap: () => _moveToImage(_currentImageIndex + 1),
            isTrailingIcon: true,
          ),
        ],
      ),
    );
  }

  Widget _buildImageMoveButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required ThemeHandler themeProvider,
    required VoidCallback onTap,
    bool isTrailingIcon = false,
  }) {
    final color = enabled ? themeProvider.primaryColor : Colors.grey[400]!;
    final children = [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 3),
      StandardText(
        text: label,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    ];

    return TextButton(
      onPressed: enabled ? onTap : null,
      style: TextButton.styleFrom(
        minimumSize: const Size(72, 38),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: isTrailingIcon ? children.reversed.toList() : children,
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

    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? themeProvider.primaryColor.withOpacity(0.12)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(AppRadius.medium),
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

    return PressableScale(
      haptic: HapticLevel.selection,
      onTap: () => setState(() {
        if (color != _penColor) _changedColor = true;
        _penColor = color;
        _setTool(_CanvasTool.pen);
      }),
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
          onPressed:
              _isSubmitting || !_isCurrentImageReady || _hasImageLoadError
                  ? null
                  : () => _submit(themeProvider),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeProvider.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
            elevation: 0,
          ),
          child: StandardText(
            text: _isSubmitting
                ? '풀이 이미지 저장 중...'
                : _hasImageLoadError
                    ? '문제 이미지를 불러오지 못했습니다'
                    : _isCurrentImageReady
                        ? widget.problemImageUrls.length > 1
                            ? '전체 풀이 제출하기'
                            : '풀이 제출하기'
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

  double get _currentStrokeWidth => _isEraserTool ? _eraserWidth : _penWidth;

  String _widthLabel(double width) {
    return width < 1 ? width.toStringAsFixed(1) : width.round().toString();
  }

  void _setTool(_CanvasTool tool) {
    _usedTools.add(tool.name);
    if (tool != _selectedTool) {
      _previousTool = _selectedTool;
      _selectedTool = tool;
    }
    _cursor.value = null;
  }

  void _toggleToLastTool() {
    final temp = _previousTool;
    _previousTool = _selectedTool;
    _selectedTool = temp;
  }

  bool _isStylus(PointerEvent event) =>
      event.kind == PointerDeviceKind.stylus ||
      event.kind == PointerDeviceKind.invertedStylus;

  /// 필압을 0~1 로 맞춘다. 펜이 아니면 쓰지 않는다.
  double _pressureOf(PointerEvent event) {
    final range = event.pressureMax - event.pressureMin;
    if (range <= 0) return 0.5;
    return ((event.pressure - event.pressureMin) / range).clamp(0.0, 1.0);
  }

  void _onPointerDown(PointerDownEvent event, Rect imageRect, Size viewport) {
    // 이동 도구일 때는 InteractiveViewer 가 다 처리한다.
    if (_selectedTool == _CanvasTool.move) return;

    final isStylus = _isStylus(event);
    if (isStylus) _usedStylus = true;

    // 애플펜슬 2 옆면 탭, S펜 보조 버튼은 마지막 도구로 바꾼다.
    if (isStylus && event.buttons & kSecondaryStylusButton != 0) {
      _usedStylusButton = true;
      setState(_toggleToLastTool);
      return;
    }

    _pointerPositions[event.pointer] = event.localPosition;
    final decision = _router.onDown(event.pointer, event.kind);
    if (decision.cancelLiveStroke) _ink.cancelStroke();

    switch (decision.role) {
      case InkPointerRole.ignore:
        _maybeShowPalmNotice();
        return;
      case InkPointerRole.transform:
        _maybeShowPalmNotice();
        // 쓰던 손가락이 확대로 넘어왔으면 그 손가락도 같이 기준에 넣는다.
        for (final pointer in _router.transformPointers) {
          final position = _pointerPositions[pointer];
          if (position != null && !_tracker.tracks(pointer)) {
            _tracker.add(pointer, position, _transformationController.value);
          }
        }
        return;
      case InkPointerRole.draw:
        break;
    }

    // S펜 버튼을 누른 채 쓰면 획 지우개처럼 동작한다.
    final forceErase = isStylus && event.buttons & kPrimaryStylusButton != 0;
    if (forceErase) _usedStylusButton = true;
    final point = _transformationController.toScene(event.localPosition);
    if (_isEraserTool || forceErase) _cursor.value = point;

    if (forceErase || _selectedTool == _CanvasTool.strokeEraser) {
      _erasing = true;
      _ink.eraseAt(point, math.max(7.0, _eraserWidth / 2), imageRect);
      return;
    }

    _ink.beginStroke(
      InkStroke(
        kind: _selectedTool == _CanvasTool.pixelEraser
            ? InkKind.pixelEraser
            : InkKind.pen,
        color: _penColor,
        width: _currentStrokeWidth,
        hasPressure: isStylus && _selectedTool == _CanvasTool.pen,
      ),
      _toNormalized(point, imageRect),
      _pressureOf(event),
      imageRect,
    );
  }

  void _onPointerMove(PointerMoveEvent event, Rect imageRect, Size viewport) {
    if (_pointerPositions.containsKey(event.pointer)) {
      _pointerPositions[event.pointer] = event.localPosition;
    }
    if (_router.isTransforming(event.pointer)) {
      final next = _tracker.move(event.pointer, event.localPosition, viewport);
      if (next != null) _transformationController.value = next;
      return;
    }
    if (!_router.isDrawing(event.pointer)) return;

    final point = _transformationController.toScene(event.localPosition);
    final forceErase =
        _isStylus(event) && event.buttons & kPrimaryStylusButton != 0;
    if (_isEraserTool || forceErase) _cursor.value = point;

    if (_erasing) {
      _ink.eraseAt(point, math.max(7.0, _eraserWidth / 2), imageRect);
      return;
    }
    _ink.extendStroke(
        _toNormalized(point, imageRect), _pressureOf(event), imageRect);
  }

  void _onPointerEnd(PointerEvent event) {
    _pointerPositions.remove(event.pointer);
    _tracker.remove(event.pointer, _transformationController.value);
    if (!_router.onUp(event.pointer)) return;

    _cursor.value = null;
    if (_erasing) {
      _erasing = false;
      _ink.endErase();
    } else {
      _ink.endStroke();
    }
  }

  /// 펜이 감지돼 손가락 필기를 처음 막았을 때 한 번만 안내한다.
  void _maybeShowPalmNotice() {
    if (_palmNoticeShown || !_router.palmRejected) return;
    _palmNoticeShown = true;
    _palmNotice.value = true;
    _palmNoticeTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) _palmNotice.value = false;
    });
  }

  Widget _buildPalmNotice() {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: ValueListenableBuilder<bool>(
        valueListenable: _palmNotice,
        builder: (context, visible, _) => IgnorePointer(
          ignoring: !visible,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(AppRadius.large),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StandardText(
                        text: '펜이 감지돼서 손가락은 확대와 이동에만 써요',
                        fontSize: MobileFontSize.reduced(context, 13),
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _palmNotice.value = false,
                      child: const StandardText(
                        text: '알겠어요',
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _undo() {
    _undoCount++;
    _ink.undo();
  }

  void _redo() {
    _redoCount++;
    _ink.redo();
  }

  void _clearStrokes() {
    _cleared = true;
    _ink.clear();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _moveToImage(int imageIndex) {
    if (imageIndex < 0 ||
        imageIndex >= widget.problemImageUrls.length ||
        imageIndex == _currentImageIndex) {
      return;
    }

    _ink.pageIndex = imageIndex;
    _tracker.clear();
    _loadImageNaturalSize(imageIndex);
    setState(() => _currentImageIndex = imageIndex);
    _cursor.value = null;
    _resetZoom();
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

  void _markImageReady(int imageIndex) {
    if (_imageReadyStates[imageIndex]) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_imageReadyStates[imageIndex]) {
        setState(() {
          _imageReadyStates[imageIndex] = true;
          _imageErrorStates[imageIndex] = false;
        });
      }
    });
  }

  void _markImageError(int imageIndex) {
    if (_imageErrorStates[imageIndex]) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_imageErrorStates[imageIndex]) {
        setState(() => _imageErrorStates[imageIndex] = true);
      }
    });
  }

  /// 한 번 푼 동안 캔버스를 어떻게 썼는지 남긴다. 지우개 두 가지, 색, 굵기,
  /// 스타일러스 버튼 같은 기능이 실제로 쓰이는지를 여기서 본다.
  void _logCanvasSession(String name) {
    final strokes =
        _ink.pages.expand((p) => p.strokes).where((s) => !s.isEraser);
    AppAnalytics.logEvent(name, {
      'duration_sec': _elapsed.value,
      'image_count': widget.problemImageUrls.length,
      'stroke_count': strokes.length,
      'tools': (_usedTools.toList()..sort()).join(','),
      'used_stylus': _usedStylus,
      'stylus_button': _usedStylusButton,
      'color_changed': _changedColor,
      'width_changed': _changedWidth,
      'undo_count': _undoCount,
      'redo_count': _redoCount,
      'palm_rejected': _router.palmRejected,
      'cleared': _cleared,
    });
  }

  Future<void> _submit(ThemeHandler themeProvider) async {
    if (!_isCurrentImageReady || _hasImageLoadError) return;

    setState(() => _isSubmitting = true);

    try {
      _ink.endStroke();
      final files = await _captureAllSolutionImages();
      _timer?.cancel();

      if (!mounted) return;

      final result = await Navigator.push(
        context,
        TossPageRoute(
          builder: (context) => ProblemSolveRegisterScreen(
            problemId: widget.problemId,
            onRefresh: widget.onRefresh,
            initialSolutionImages: files,
            initialTimeSpentSeconds: _elapsed.value,
          ),
        ),
      );

      if (result == true) {
        _submitted = true;
        _logCanvasSession('canvas_submit');
      }
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

  Future<List<File>> _captureAllSolutionImages() async {
    final originalIndex = _currentImageIndex;
    final directory = await getTemporaryDirectory();
    final files = <File>[];

    for (var index = 0; index < widget.problemImageUrls.length; index++) {
      if (!mounted) throw StateError('canvas screen is not mounted');

      if (_currentImageIndex != index) {
        _moveToImage(index);
      }

      await _waitForImageReady(index);
      await WidgetsBinding.instance.endOfFrame;

      final file = await _captureCurrentCanvas(directory, index);
      files.add(file);
    }

    if (mounted && _currentImageIndex != originalIndex) {
      _moveToImage(originalIndex);
    }

    return files;
  }

  Future<void> _waitForImageReady(int imageIndex) async {
    for (var attempt = 0; attempt < 80; attempt++) {
      if (!mounted) throw StateError('canvas screen is not mounted');
      if (_imageErrorStates[imageIndex]) {
        throw StateError('problem image failed to load');
      }
      if (_imageReadyStates[imageIndex]) return;

      await Future<void>.delayed(const Duration(milliseconds: 100));
      await WidgetsBinding.instance.endOfFrame;
    }

    throw StateError('problem image load timed out');
  }

  Future<File> _captureCurrentCanvas(
      Directory directory, int imageIndex) async {
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

    final file = File(
      '${directory.path}/problem_solve_${widget.problemId}_${imageIndex}_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

    return file;
  }

  String _formatElapsedTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
