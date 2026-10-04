import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../Module/Dialog/UnsavedChangesScope.dart';
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
import 'Canvas/ScratchPaper.dart';
import 'ProblemSolveRegisterScreen.dart';
import '../../Module/Motion/AppHaptic.dart';
import '../../Module/Motion/PressableScale.dart';
import '../../Module/Motion/TossPageRoute.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppToast.dart';

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
  highlighter,
  pixelEraser,
  strokeEraser,
  move,
}

class _ProblemSolveCanvasScreenState extends State<ProblemSolveCanvasScreen>
    with WidgetsBindingObserver {
  // 문제 캔버스와 연습장 캔버스. 폰에서는 하나만 보이고, 태블릿 가로에서는
  // 둘을 나란히 둔다.
  final _InkSurface _problemSurface = _InkSurface(isScratch: false);
  final _InkSurface _scratchSurface = _InkSurface(isScratch: true);
  bool _showScratch = false;
  int _scratchIndex = 0;
  int _scratchPageCount = 1;
  static const int _maxScratchPages = 5;

  /// 앱바 양쪽 칸 폭. 같게 둬야 타이머가 가운데 온다. 오른쪽 버튼 셋이 들어간다.
  static const double _appBarSideWidth = 128;
  // 획과 되돌리기 기록. 펜이 움직일 때 setState 없이 그리기 층만 다시 그린다.
  late final InkController _ink;
  final InkInputRouter _router = InkInputRouter();
  late final List<bool> _imageReadyStates;
  late final List<bool> _imageErrorStates;
  late final List<Size?> _imageNaturalSizes;
  Timer? _timer;
  int _currentImageIndex = 0;

  // 타이머와 지우개 커서는 그 칸만 다시 그린다.
  final ValueNotifier<int> _elapsed = ValueNotifier(0);

  /// 타이머를 눌러 멈췄는지. 전에는 멈출 수 없어서 잠깐 자리를 비우면 그만큼
  /// 풀이 시간이 늘었다.
  final ValueNotifier<bool> _timerPaused = ValueNotifier(false);

  /// 앱이 화면에 떠 있는지. 다른 앱으로 넘어가 있는 동안은 세지 않는다.
  bool _appActive = true;

  // 펜이 감지돼 손가락 필기를 처음 막았을 때 한 번만 띄우는 안내.
  final ValueNotifier<bool> _palmNotice = ValueNotifier(false);
  bool _palmNoticeShown = false;
  Timer? _palmNoticeTimer;

  // 획 지우개로 문지르는 중인지. 손을 떼면 한 번의 되돌리기 단위로 묶는다.
  bool _erasing = false;

  // 포인터마다 마지막 위치. 손가락으로 쓰다가 두 손가락 확대로 바뀔 때 첫
  // 손가락의 위치가 필요하다.
  final Map<int, Offset> _pointerPositions = {};

  // 직선 보정. 긋다가 손을 떼지 않고 잠깐 멈추면 곧은 선으로 바꾼다.
  Timer? _holdTimer;
  Offset? _holdAnchor;
  bool _straightened = false;

  // 두 손가락 탭은 되돌리기, 세 손가락 탭은 다시 실행. 손가락을 댄 동안 얼마나
  // 움직였는지, 몇 개까지 닿았는지 본다.
  DateTime? _tapStart;
  int _tapFingers = 0;
  double _tapTravel = 0;
  Matrix4? _tapStartMatrix;
  bool _isSubmitting = false;
  Size _canvasSize = Size.zero;
  Color _penColor = Colors.black87;
  double _penWidth = 4.0;
  double _eraserWidth = 18.0;
  double _highlighterWidth = 14.0;
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
    _ink = InkController(
        pageCount: widget.problemImageUrls.length + _maxScratchPages);
    _imageReadyStates =
        List.generate(widget.problemImageUrls.length, (_) => false);
    _imageErrorStates =
        List.generate(widget.problemImageUrls.length, (_) => false);
    _imageNaturalSizes =
        List.generate(widget.problemImageUrls.length, (_) => null);
    WidgetsBinding.instance.addObserver(this);
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
      if (!mounted || _timerPaused.value || !_appActive) return;
      _elapsed.value++;
    });
  }

  void _toggleTimerPause() {
    _timerPaused.value = !_timerPaused.value;
    AppAnalytics.logEvent('canvas_timer_pause', {
      'paused': _timerPaused.value,
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    // 풀다가 제출하지 않고 나간 것. 어디까지 쓰다 그만두는지 본다.
    if (!_submitted) _logCanvasSession('canvas_abandon');
    if (Platform.isIOS) _pencilChannel.setMethodCallHandler(null);
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _palmNoticeTimer?.cancel();
    _holdTimer?.cancel();
    _problemSurface.dispose();
    _scratchSurface.dispose();
    _ink.dispose();
    _elapsed.dispose();
    _timerPaused.dispose();
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

    // 필기는 화면을 다시 그리지 않고 쌓여서 나가려는 순간에 확인한다. 캔버스
    // 왼쪽 끝에서 쓰다가 밀어서 뒤로가기가 걸리는 일도 함께 막힌다.
    return UnsavedChangesScope.check(
      checkChanges: () => _ink.pages.any((page) => page.hasInk),
      source: 'problem_solve_canvas',
      title: '풀이를 그만둘까요?',
      description: '지금 나가면 쓴 풀이가 저장되지 않아요.',
      child: _buildScaffold(themeProvider),
    );
  }

  Widget _buildScaffold(ThemeHandler themeProvider) {
    return Scaffold(
      backgroundColor: Colors.white,
      // 왼쪽 뒤로가기 칸과 오른쪽 되돌리기, 다시 실행, 전체 지우기 칸의 폭을
      // 같게 맞춰 타이머가 정확히 가운데 온다. 확대 초기화는 확대했을 때만
      // 캔버스 위에 뜨는 버튼으로 옮겼다.
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leadingWidth: _appBarSideWidth,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: BackButton(color: AppColors.textPrimary),
        ),
        // 타이머는 매초 바뀌어서 이 칸만 다시 그린다. 고치기 전에는 1초마다
        // 화면 전체를 다시 만들었다.
        // 눌러서 멈추고 다시 누르면 이어서 센다.
        title: ValueListenableBuilder<bool>(
          valueListenable: _timerPaused,
          builder: (context, paused, _) => Semantics(
            button: true,
            label: paused ? '풀이 시간 이어서 세기' : '풀이 시간 멈추기',
            child: InkWell(
              onTap: _toggleTimerPause,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: ValueListenableBuilder<int>(
                  valueListenable: _elapsed,
                  // 큰 글씨에서도 가운데 칸을 넘치지 않게 줄인다.
                  builder: (context, seconds, _) => FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                            paused
                                ? Icons.play_circle_outline
                                : Icons.pause_circle_outline,
                            size: 20,
                            color: paused
                                ? AppColors.textSecondary
                                : themeProvider.primaryColor),
                        const SizedBox(width: 6),
                        StandardText(
                          text: _formatElapsedTime(seconds),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: paused
                              ? AppColors.textSecondary
                              : themeProvider.primaryColor,
                          height: 1.2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: _appBarSideWidth,
            child: ListenableBuilder(
              listenable: _ink.committed,
              builder: (context, _) => Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: '되돌리기',
                    visualDensity: VisualDensity.compact,
                    onPressed: _ink.page.canUndo ? _undo : null,
                    color: themeProvider.primaryColor,
                    disabledColor: AppColors.textDisabled,
                    icon: const Icon(Icons.undo),
                  ),
                  IconButton(
                    tooltip: '다시 실행',
                    visualDensity: VisualDensity.compact,
                    onPressed: _ink.page.canRedo ? _redo : null,
                    color: themeProvider.primaryColor,
                    disabledColor: AppColors.textDisabled,
                    icon: const Icon(Icons.redo),
                  ),
                  // 이제 되돌릴 수 있어서 되돌리기 옆에 둔다.
                  IconButton(
                    // 지금 보는 페이지만 지운다. 전에는 '전체 지우기' 라고 해서
                    // 다른 페이지 필기까지 사라지는 줄 알았다.
                    tooltip: '이 페이지 지우기',
                    visualDensity: VisualDensity.compact,
                    onPressed: _ink.page.isEmpty ? null : _clearStrokes,
                    color: themeProvider.primaryColor,
                    disabledColor: AppColors.textDisabled,
                    icon: const Icon(Icons.delete_outline),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isSplit(context)) _buildPageBar(themeProvider),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: _isSplit(context)
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child:
                                    _buildPanel(_problemSurface, themeProvider),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child:
                                    _buildPanel(_scratchSurface, themeProvider),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                          child: _buildSurface(
                            _showScratch ? _scratchSurface : _problemSurface,
                            themeProvider,
                          ),
                        ),
                ),
                _buildPalmNotice(),
              ],
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
                        icon: Icons.border_color,
                        label: '형광펜',
                        isSelected: _selectedTool == _CanvasTool.highlighter,
                        themeProvider: themeProvider,
                        onTap: () => setState(
                          () => _setTool(_CanvasTool.highlighter),
                        ),
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
                    min: _widthRange.$1,
                    max: _widthRange.$2,
                    divisions: _widthRange.$3,
                    activeColor: themeProvider.primaryColor,
                    inactiveColor: Colors.grey[200],
                    label: _widthLabel(_currentStrokeWidth),
                    onChanged: _selectedTool == _CanvasTool.move
                        ? null
                        : (value) => setState(() {
                              _changedWidth = true;
                              if (_isEraserTool) {
                                _eraserWidth = value;
                              } else if (_selectedTool ==
                                  _CanvasTool.highlighter) {
                                _highlighterWidth = value;
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

  int get _imageCount => widget.problemImageUrls.length;

  /// 태블릿 가로에서는 문제와 연습장을 나란히 펼친다.
  bool _isSplit(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width >= 900 && size.width > size.height;
  }

  /// [surface] 가 지금 보여 주는 페이지 번호. 문제 이미지 다음에 연습장이 온다.
  int _pageOf(_InkSurface surface) =>
      surface.isScratch ? _imageCount + _scratchIndex : _currentImageIndex;

  /// 연습장 페이지에 필기가 있는지.
  int get _scratchPagesWithInk => [
        for (var i = 0; i < _maxScratchPages; i++)
          if (_ink.pages[_imageCount + i].hasInk) i,
      ].length;

  /// 폰에서 캔버스 위에 두는 줄. 왼쪽 `문제 | 연습장` 전환, 오른쪽 페이지 넘기기.
  Widget _buildPageBar(ThemeHandler themeProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSegment(
                    '문제', !_showScratch, () => _setShowScratch(false)),
                _buildSegment('연습장', _showScratch, () => _setShowScratch(true)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 큰 글씨나 좁은 폰에서도 넘치지 않게 남는 폭에 맞춰 줄인다.
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _buildPageNav(themeProvider, scratch: _showScratch),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(String label, bool selected, VoidCallback onTap) {
    return Semantics(
      button: true,
      selected: selected,
      child: PressableScale(
        haptic: HapticLevel.selection,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: StandardText(
            text: label,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            height: 1.2,
          ),
        ),
      ),
    );
  }

  /// `‹ 1 / 2 ›`. 연습장이면 오른쪽에 `+` 가 붙는다. 문제인지 연습장인지는
  /// 옆의 전환 버튼이나 패널 이름이 이미 말해 줘서 숫자만 둔다.
  Widget _buildPageNav(ThemeHandler themeProvider, {required bool scratch}) {
    final index = scratch ? _scratchIndex : _currentImageIndex;
    final count = scratch ? _scratchPageCount : _imageCount;
    final enabled = !_isSubmitting;

    void go(int next) => scratch ? _moveToScratch(next) : _moveToImage(next);

    Widget arrow(IconData icon, String tooltip, bool canGo, int next) {
      return IconButton(
        tooltip: tooltip,
        onPressed: enabled && canGo ? () => go(next) : null,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon,
            color: enabled && canGo
                ? themeProvider.primaryColor
                : Colors.grey[400]),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        arrow(Icons.chevron_left, scratch ? '이전 연습장' : '이전 문제 이미지', index > 0,
            index - 1),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: themeProvider.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: themeProvider.primaryColor.withValues(alpha: 0.18),
            ),
          ),
          child: StandardText(
            text: '${index + 1} / $count',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: themeProvider.primaryColor,
            height: 1.2,
          ),
        ),
        arrow(Icons.chevron_right, scratch ? '다음 연습장' : '다음 문제 이미지',
            index < count - 1, index + 1),
        if (scratch)
          IconButton(
            tooltip: '연습장 추가',
            onPressed: enabled && _scratchPageCount < _maxScratchPages
                ? _addScratchPage
                : null,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.add_box_outlined,
              color: enabled && _scratchPageCount < _maxScratchPages
                  ? themeProvider.primaryColor
                  : Colors.grey[400],
            ),
          ),
      ],
    );
  }

  /// 태블릿 가로에서 나란히 놓는 한쪽. 위에 이름과 페이지 넘기기, 아래 캔버스.
  /// 마지막으로 쓴 쪽 테두리를 테마 색으로 둔다.
  Widget _buildPanel(_InkSurface surface, ThemeHandler themeProvider) {
    final active = _ink.pageIndex == _pageOf(surface);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 44,
          child: Row(
            children: [
              StandardText(
                text: surface.isScratch ? '연습장' : '문제',
                fontSize: MobileFontSize.reduced(context, 14),
                fontWeight: FontWeight.w600,
                color: active
                    ? themeProvider.primaryColor
                    : AppColors.textSecondary,
              ),
              const Spacer(),
              _buildPageNav(themeProvider, scratch: surface.isScratch),
            ],
          ),
        ),
        Expanded(
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: Border.all(
                color: active ? themeProvider.primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: _buildSurface(surface, themeProvider),
          ),
        ),
      ],
    );
  }

  /// 캔버스 하나. 문제 이미지 또는 연습장 종이 위에 확정된 획 층과 지금 획 층을
  /// 겹친다. 포인터는 확대 뷰 바깥에서 받아 화면 좌표로 두 손가락 확대를
  /// 계산하고, 필기 좌표는 toScene 으로 바꾼다.
  Widget _buildSurface(_InkSurface surface, ThemeHandler themeProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (!surface.isScratch && size != _canvasSize) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _onCanvasSizeChanged(size));
          });
        }
        final imageIndex = _currentImageIndex;
        final imageRect =
            surface.isScratch ? Offset.zero & size : _computeImageRect(size);
        final page = _ink.pages[_pageOf(surface)];

        return Stack(
          children: [
            Positioned.fill(
              child: Listener(
                onPointerDown: (event) =>
                    _onPointerDown(surface, event, imageRect, size),
                onPointerMove: (event) =>
                    _onPointerMove(surface, event, imageRect, size),
                onPointerUp: (event) => _onPointerEnd(surface, event),
                onPointerCancel: (event) => _onPointerEnd(surface, event),
                onPointerHover: (event) {
                  final forceErase = event.kind == PointerDeviceKind.stylus &&
                      event.buttons & kPrimaryStylusButton != 0;
                  if (_isEraserTool || forceErase) {
                    surface.cursor.value =
                        surface.transform.toScene(event.localPosition);
                  }
                },
                child: InteractiveViewer(
                  transformationController: surface.transform,
                  minScale: 1,
                  maxScale: 4,
                  // 펜 도구일 때는 확대와 이동을 직접 계산한다. 이동 도구일 때만
                  // InteractiveViewer 에 맡긴다.
                  panEnabled: _selectedTool == _CanvasTool.move,
                  scaleEnabled: _selectedTool == _CanvasTool.move,
                  boundaryMargin: const EdgeInsets.all(80),
                  child: Stack(
                    children: [
                      RepaintBoundary(
                        key: surface.captureKey,
                        child: Container(
                          width: size.width,
                          height: size.height,
                          color: Colors.white,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (surface.isScratch)
                                const ScratchPaper()
                              else
                                Image.network(
                                  _currentImageUrl,
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
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        color: themeProvider.primaryColor,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
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
                              // 확정된 획과 지금 긋는 획을 따로 그린다. 펜이 움직일
                              // 때는 아래 층만 다시 그린다.
                              RepaintBoundary(
                                child: CustomPaint(
                                  size: size,
                                  painter: CommittedInkPainter(
                                    controller: _ink,
                                    page: page,
                                    imageRect: imageRect,
                                  ),
                                ),
                              ),
                              RepaintBoundary(
                                child: CustomPaint(
                                  size: size,
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
                            valueListenable: surface.cursor,
                            builder: (context, position, _) => position == null
                                ? const SizedBox.shrink()
                                : CustomPaint(
                                    painter: _EraserCursorPainter(
                                      position: position,
                                      radius: math.max(7.0, _eraserWidth / 2),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 확대했을 때만 뜬다. 원래 크기로 돌린다.
            Positioned(
              top: 8,
              right: 8,
              child: ValueListenableBuilder<Matrix4>(
                valueListenable: surface.transform,
                builder: (context, matrix, _) {
                  final zoomed = matrix != Matrix4.identity();
                  return IgnorePointer(
                    ignoring: !zoomed,
                    child: AnimatedOpacity(
                      opacity: zoomed ? 1 : 0,
                      duration: const Duration(milliseconds: 160),
                      child: Material(
                        color: Colors.white,
                        elevation: 2,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          onTap: () =>
                              surface.transform.value = Matrix4.identity(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.zoom_out_map,
                                    size: 16,
                                    color: themeProvider.primaryColor),
                                const SizedBox(width: 6),
                                StandardText(
                                  text: '원래 크기',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  height: 1.2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
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
    final isSelected = (_selectedTool == _CanvasTool.pen ||
            _selectedTool == _CanvasTool.highlighter) &&
        _penColor == color;

    return PressableScale(
      haptic: HapticLevel.selection,
      onTap: () => setState(() {
        if (color != _penColor) _changedColor = true;
        _penColor = color;
        // 형광펜을 들고 있으면 형광펜 색만 바꾼다.
        if (_selectedTool != _CanvasTool.highlighter) {
          _setTool(_CanvasTool.pen);
        }
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

  double get _currentStrokeWidth => _isEraserTool
      ? _eraserWidth
      : _selectedTool == _CanvasTool.highlighter
          ? _highlighterWidth
          : _penWidth;

  /// 굵기 막대의 (최소, 최대, 눈금 수).
  (double, double, int) get _widthRange => _isEraserTool
      ? (2.0, 48.0, 46)
      : _selectedTool == _CanvasTool.highlighter
          ? (4.0, 40.0, 36)
          : (0.5, 18.0, 35);

  String _widthLabel(double width) {
    return width < 1 ? width.toStringAsFixed(1) : width.round().toString();
  }

  void _setTool(_CanvasTool tool) {
    _usedTools.add(tool.name);
    if (tool != _selectedTool) {
      _previousTool = _selectedTool;
      _selectedTool = tool;
    }
    _problemSurface.cursor.value = null;
    _scratchSurface.cursor.value = null;
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

  /// 펜을 댄 캔버스의 페이지를 지금 페이지로 둔다. 태블릿 가로에서 마지막으로
  /// 쓴 쪽이 되돌리기 대상이 된다.
  void _activate(_InkSurface surface) {
    final index = _pageOf(surface);
    if (_ink.pageIndex == index) return;
    _ink.pageIndex = index;
    setState(() {});
  }

  void _onPointerDown(_InkSurface surface, PointerDownEvent event,
      Rect imageRect, Size viewport) {
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
    if (decision.cancelLiveStroke) _cancelLiveStroke();

    switch (decision.role) {
      case InkPointerRole.ignore:
        _maybeShowPalmNotice();
        return;
      case InkPointerRole.transform:
        _maybeShowPalmNotice();
        if (!surface.tracker.isActive) {
          _tapStart = DateTime.now();
          _tapFingers = 0;
          _tapTravel = 0;
          _tapStartMatrix = surface.transform.value.clone();
        }
        // 쓰던 손가락이 확대로 넘어왔으면 그 손가락도 같이 기준에 넣는다.
        for (final pointer in _router.transformPointers) {
          final position = _pointerPositions[pointer];
          if (position != null && !surface.tracker.tracks(pointer)) {
            surface.tracker.add(pointer, position, surface.transform.value);
          }
        }
        _tapFingers = math.max(_tapFingers, _router.transformPointers.length);
        return;
      case InkPointerRole.draw:
        break;
    }

    _activate(surface);

    // S펜 버튼을 누른 채 쓰면 획 지우개처럼 동작한다.
    final forceErase = isStylus && event.buttons & kPrimaryStylusButton != 0;
    if (forceErase) _usedStylusButton = true;
    final point = surface.transform.toScene(event.localPosition);
    if (_isEraserTool || forceErase) surface.cursor.value = point;

    if (forceErase || _selectedTool == _CanvasTool.strokeEraser) {
      _erasing = true;
      _ink.eraseAt(point, math.max(7.0, _eraserWidth / 2), imageRect);
      return;
    }

    final kind = switch (_selectedTool) {
      _CanvasTool.pixelEraser => InkKind.pixelEraser,
      _CanvasTool.highlighter => InkKind.highlighter,
      _ => InkKind.pen,
    };
    _ink.beginStroke(
      InkStroke(
        kind: kind,
        color: _penColor,
        width: _currentStrokeWidth,
        hasPressure: isStylus && kind == InkKind.pen,
      ),
      _toNormalized(point, imageRect),
      _pressureOf(event),
      imageRect,
    );
    _straightened = false;
    _restartHold(point, imageRect);
  }

  void _onPointerMove(_InkSurface surface, PointerMoveEvent event,
      Rect imageRect, Size viewport) {
    if (_pointerPositions.containsKey(event.pointer)) {
      _pointerPositions[event.pointer] = event.localPosition;
    }
    if (_router.isTransforming(event.pointer)) {
      _tapTravel += event.delta.distance;
      final next =
          surface.tracker.move(event.pointer, event.localPosition, viewport);
      if (next != null) surface.transform.value = next;
      return;
    }
    if (!_router.isDrawing(event.pointer)) return;

    final point = surface.transform.toScene(event.localPosition);
    final forceErase =
        _isStylus(event) && event.buttons & kPrimaryStylusButton != 0;
    if (_isEraserTool || forceErase) surface.cursor.value = point;

    if (_erasing) {
      _ink.eraseAt(point, math.max(7.0, _eraserWidth / 2), imageRect);
      return;
    }
    final normalized = _toNormalized(point, imageRect);
    if (_straightened) {
      _ink.moveLiveStrokeEnd(normalized);
      return;
    }
    _ink.extendStroke(normalized, _pressureOf(event), imageRect);
    if (_holdAnchor == null || (point - _holdAnchor!).distance > 4) {
      _restartHold(point, imageRect);
    }
  }

  void _onPointerEnd(_InkSurface surface, PointerEvent event) {
    _pointerPositions.remove(event.pointer);
    final wasTransforming = _router.isTransforming(event.pointer);
    surface.tracker.remove(event.pointer, surface.transform.value);
    final wasDrawing = _router.onUp(event.pointer);

    if (wasTransforming && _router.transformPointers.isEmpty) {
      _finishTapGesture(surface);
    }
    if (!wasDrawing) return;

    _holdTimer?.cancel();
    _holdAnchor = null;
    surface.cursor.value = null;
    if (_erasing) {
      _erasing = false;
      _ink.endErase();
    } else {
      _ink.endStroke();
    }
  }

  void _cancelLiveStroke() {
    _holdTimer?.cancel();
    _holdAnchor = null;
    _ink.cancelStroke();
  }

  /// 긋다가 [_holdDuration] 동안 4px 넘게 움직이지 않으면 곧은 선으로 바꾼다.
  static const Duration _holdDuration = Duration(milliseconds: 500);

  void _restartHold(Offset point, Rect imageRect) {
    _holdAnchor = point;
    _holdTimer?.cancel();
    if (_selectedTool != _CanvasTool.pen &&
        _selectedTool != _CanvasTool.highlighter) {
      return;
    }
    _holdTimer = Timer(_holdDuration, () {
      final stroke = _ink.liveStroke;
      if (!mounted || stroke == null || stroke.isEraser) return;
      // 점만 찍고 멈춘 것은 직선으로 바꾸지 않는다.
      if (stroke.length < 3 || stroke.screenExtent(imageRect) < 24) return;
      // 구불구불한 획은 멈춰도 그대로 둔다.
      if (!stroke.isRoughlyStraight(imageRect)) return;
      _ink.straightenLiveStroke();
      _straightened = true;
      _usedTools.add('straight_line');
      HapticFeedback.selectionClick();
    });
  }

  /// 손가락을 모두 뗐을 때 짧게 거의 안 움직였으면 탭으로 본다. 두 손가락은
  /// 되돌리기, 세 손가락은 다시 실행. 탭하는 동안 살짝 움직인 화면은 되돌린다.
  void _finishTapGesture(_InkSurface surface) {
    final start = _tapStart;
    final fingers = _tapFingers;
    final startMatrix = _tapStartMatrix;
    _tapStart = null;
    _tapFingers = 0;
    _tapStartMatrix = null;
    if (start == null || fingers < 2) return;
    final quick =
        DateTime.now().difference(start) < const Duration(milliseconds: 300);
    if (!quick || _tapTravel > 20) return;

    if (startMatrix != null) surface.transform.value = startMatrix;
    if (fingers == 2 && _ink.page.canUndo) {
      _usedTools.add('two_finger_undo');
      _undo();
    } else if (fingers >= 3 && _ink.page.canRedo) {
      _usedTools.add('three_finger_redo');
      _redo();
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
    final pageIndex = _ink.pageIndex;
    _ink.clear();
    // 되돌리기 버튼으로도 되살릴 수 있지만, 지운 직후 바로 알 수 있게 한다.
    AppToast.show(
      message: '이 페이지의 필기를 지웠어요',
      type: ToastType.info,
      actionLabel: '되돌리기',
      onAction: () {
        if (!mounted || _ink.pageIndex != pageIndex) return;
        _undo();
      },
    );
  }

  void _resetZoom() {
    _problemSurface.transform.value = Matrix4.identity();
    _scratchSurface.transform.value = Matrix4.identity();
  }

  void _moveToImage(int imageIndex) {
    if (imageIndex < 0 || imageIndex >= _imageCount) return;
    if (imageIndex == _currentImageIndex && _ink.pageIndex == imageIndex) {
      return;
    }

    _ink.pageIndex = imageIndex;
    _problemSurface.tracker.clear();
    _loadImageNaturalSize(imageIndex);
    setState(() => _currentImageIndex = imageIndex);
    _problemSurface.cursor.value = null;
    _problemSurface.transform.value = Matrix4.identity();
  }

  void _moveToScratch(int scratchIndex) {
    if (scratchIndex < 0 || scratchIndex >= _scratchPageCount) return;
    _ink.pageIndex = _imageCount + scratchIndex;
    _scratchSurface.tracker.clear();
    setState(() => _scratchIndex = scratchIndex);
    _scratchSurface.cursor.value = null;
    _scratchSurface.transform.value = Matrix4.identity();
  }

  /// 폰에서 `문제 | 연습장` 을 바꾼다.
  void _setShowScratch(bool show) {
    if (show == _showScratch || _isSubmitting) return;
    if (show) _usedTools.add('scratch');
    setState(() => _showScratch = show);
    _ink.pageIndex = _pageOf(show ? _scratchSurface : _problemSurface);
  }

  void _addScratchPage() {
    if (_scratchPageCount >= _maxScratchPages) return;
    setState(() => _scratchPageCount++);
    _moveToScratch(_scratchPageCount - 1);
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
      'scratch_page_count': _scratchPagesWithInk,
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

  /// 문제 이미지를 모두 캡처하고, 필기가 있는 연습장만 그 뒤에 이어 캡처한다.
  /// 빈 연습장은 넣지 않는다. 모두 같은 풀이 이미지 목록으로 올라간다.
  Future<List<File>> _captureAllSolutionImages() async {
    final split = _isSplit(context);
    final originalImage = _currentImageIndex;
    final originalScratch = _scratchIndex;
    final originalShowScratch = _showScratch;
    final originalPage = _ink.pageIndex;
    final directory = await getTemporaryDirectory();
    final files = <File>[];

    final pages = _ink.pagesToCapture(
        imageCount: _imageCount, scratchCount: _scratchPageCount);
    for (final pageIndex in pages) {
      if (!mounted) throw StateError('canvas screen is not mounted');
      final isScratch = pageIndex >= _imageCount;
      if (!split && _showScratch != isScratch) {
        setState(() => _showScratch = isScratch);
      }
      if (isScratch) {
        _moveToScratch(pageIndex - _imageCount);
        await WidgetsBinding.instance.endOfFrame;
        files.add(await _captureCanvas(_scratchSurface.captureKey, directory,
            's${pageIndex - _imageCount}'));
      } else {
        _moveToImage(pageIndex);
        await _waitForImageReady(pageIndex);
        await WidgetsBinding.instance.endOfFrame;
        files.add(await _captureCanvas(
            _problemSurface.captureKey, directory, 'p$pageIndex'));
      }
    }

    if (mounted) {
      setState(() {
        _showScratch = originalShowScratch;
        _currentImageIndex = originalImage;
        _scratchIndex = originalScratch;
      });
      _ink.pageIndex = originalPage;
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

  Future<File> _captureCanvas(
      GlobalKey captureKey, Directory directory, String tag) async {
    final boundary =
        captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
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
      '${directory.path}/problem_solve_${widget.problemId}_${tag}_${DateTime.now().millisecondsSinceEpoch}.png',
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

/// 지우개가 지나가는 범위. 지워질 넓이만큼 반투명한 원으로 보인다.
class _EraserCursorPainter extends CustomPainter {
  final Offset position;
  final double radius;

  _EraserCursorPainter({required this.position, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      position,
      radius,
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
    canvas.drawCircle(
      position,
      radius,
      Paint()
        ..color = const Color(0xFF64748B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _EraserCursorPainter oldDelegate) {
    return position != oldDelegate.position || radius != oldDelegate.radius;
  }
}

/// 캔버스 하나에 딸린 것들. 확대 상태, 두 손가락 계산, 지우개 커서, 캡처 키.
class _InkSurface {
  final bool isScratch;
  final TransformationController transform = TransformationController();
  final InkTransformTracker tracker = InkTransformTracker();
  final ValueNotifier<Offset?> cursor = ValueNotifier(null);
  final GlobalKey captureKey = GlobalKey();

  _InkSurface({required this.isScratch});

  void dispose() {
    transform.dispose();
    cursor.dispose();
  }
}
