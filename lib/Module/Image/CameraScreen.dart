import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../Design/AppColors.dart';
import '../Design/AppRadius.dart';
import '../Design/AppSpacing.dart';
import '../Motion/AppHaptic.dart';
import '../Motion/AppMotion.dart';
import '../Motion/PressableScale.dart';
import '../Text/StandardText.dart';
import '../Theme/ThemeHandler.dart';

/// 오답노트에 넣을 사진을 찍는 화면이다.
///
/// 예전에는 검은 바탕에 안내 배너 하나와 촬영 버튼 하나뿐이었고, 셔터를
/// 누르면 확인할 틈도 없이 이전 화면으로 돌아갔다. 문제와 풀이를 찍는 앱이라
/// 흔들리거나 잘린 사진이 그대로 등록되기 쉬웠다.
///
/// 이 화면은 세 가지를 다르게 한다.
///
/// 첫째, 미리보기를 화면 크기만큼 늘려서 잘라 보여 주지 않는다. [CameraPreview]
/// 가 스스로 정하는 비율 그대로 화면 안에 넣는다. 늘려서 보여 주면 화면 밖으로
/// 밀려난 가장자리가 실제로는 사진에 찍히기 때문에, 보이는 것과 찍히는 것이
/// 달라진다. 종이 테두리를 맞춰 찍는 화면에서는 이게 특히 문제라 안내선보다
/// 이것을 먼저 맞췄다.
///
/// 둘째, 찍은 뒤 확인 단계를 둔다. 다시 찍기와 이걸로 쓰기 중에 고르게 한다.
/// 확인 단계는 화면을 새로 띄우지 않고 같은 화면 위에 덮는다. 카메라를 살려
/// 둬야 다시 찍기가 바로 되기 때문이다.
///
/// 셋째, 요즘 카메라 화면이면 있을 것들을 채운다. 플래시, 전후면 전환,
/// 탭해서 초점, 오므려서 확대, 갤러리에서 고르기, 방금 찍은 것.
class CameraScreen extends StatefulWidget {
  /// 기기가 가진 카메라 전부. 전후면 전환에 쓴다.
  final List<CameraDescription> cameras;

  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  /// 지금 쓰는 카메라. 전후면 전환이 이걸 바꾼다.
  late CameraDescription _description;

  FlashMode _flashMode = FlashMode.off;

  /// 셔터를 연달아 눌러 `takePicture was called before the previous capture
  /// returned` 로 터지는 것을 막는다.
  bool _isCapturing = false;
  bool _isSwitchingLens = false;

  /// 확인 단계에 올라와 있는 사진. null 이면 촬영 화면이다.
  XFile? _reviewing;

  /// 방금 찍은 것. 다시 찍기를 눌러도 남겨 둬서 되돌아갈 수 있게 한다.
  XFile? _lastShot;

  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _zoom = 1.0;
  double _zoomAtScaleStart = 1.0;

  /// setZoomLevel 이 아직 안 끝났는데 다음 것을 밀어 넣지 않게 한다.
  bool _zoomInFlight = false;
  bool _showZoomLabel = false;
  Timer? _zoomLabelTimer;

  /// 초점을 맞춘 자리. 미리보기 안에서의 좌표다.
  Offset? _focusPoint;
  Timer? _focusTimer;

  /// 셔터를 누른 순간 화면이 한 번 하얘지는 것.
  late final AnimationController _shutterFlash;

  @override
  void initState() {
    super.initState();

    // 화면 방향을 세로로 고정
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    _shutterFlash = AnimationController(
      vsync: this,
      duration: AppMotion.press,
      reverseDuration: AppMotion.fast,
    );

    _description = _initialDescription();
    _initializeControllerFuture = _setUpController(_description);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _zoomLabelTimer?.cancel();
    _focusTimer?.cancel();
    _shutterFlash.dispose();
    _controller?.dispose();
    super.dispose();
  }

  // ── 카메라 ───────────────────────────────────────────────

  /// 문제를 찍는 화면이라 후면이 기본이다.
  CameraDescription _initialDescription() {
    return widget.cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => widget.cameras.first,
    );
  }

  /// 지금 쓰는 것과 반대편 카메라. 없으면 null 이고 전환 버튼도 숨는다.
  CameraDescription? get _oppositeLens {
    for (final camera in widget.cameras) {
      if (camera.lensDirection != _description.lensDirection) return camera;
    }
    return null;
  }

  bool get _canUseFlash =>
      _description.lensDirection == CameraLensDirection.back;

  Future<void> _setUpController(CameraDescription description) async {
    final controller = CameraController(
      description,
      ResolutionPreset.high,
      // 사진만 찍는 화면이라 마이크 권한까지 물을 이유가 없다.
      enableAudio: false,
    );
    _controller = controller;

    await controller.initialize();
    await _readZoomBounds(controller);
    await _applyFlashMode(controller);
  }

  Future<void> _readZoomBounds(CameraController controller) async {
    // 확대 범위를 못 읽는 기기가 있다. 그때는 확대를 안 쓰면 그만이라
    // 초기화 전체를 실패로 만들지 않는다.
    try {
      _minZoom = await controller.getMinZoomLevel();
      _maxZoom = await controller.getMaxZoomLevel();
    } catch (e) {
      debugPrint('확대 범위를 읽지 못했습니다: $e');
      _minZoom = 1.0;
      _maxZoom = 1.0;
    }
    _zoom = _minZoom;
  }

  Future<void> _applyFlashMode(CameraController controller) async {
    try {
      await controller.setFlashMode(_canUseFlash ? _flashMode : FlashMode.off);
    } catch (e) {
      debugPrint('플래시를 설정하지 못했습니다: $e');
    }
  }

  Future<void> _retryInitialize() async {
    final previous = _controller;
    _controller = null;
    await previous?.dispose();

    if (!mounted) return;
    setState(() {
      _initializeControllerFuture = _setUpController(_description);
    });
  }

  Future<void> _switchLens() async {
    final next = _oppositeLens;
    final controller = _controller;
    if (next == null || controller == null || _isSwitchingLens) return;

    setState(() => _isSwitchingLens = true);
    try {
      await controller.setDescription(next);
      _description = next;
      await _readZoomBounds(controller);
      await _applyFlashMode(controller);
    } catch (e) {
      debugPrint('카메라를 전환하지 못했습니다: $e');
    } finally {
      if (mounted) setState(() => _isSwitchingLens = false);
    }
  }

  Future<void> _cycleFlashMode() async {
    const order = [FlashMode.off, FlashMode.auto, FlashMode.always];
    final next = order[(order.indexOf(_flashMode) + 1) % order.length];

    setState(() => _flashMode = next);

    final controller = _controller;
    if (controller != null) await _applyFlashMode(controller);
  }

  // ── 촬영 ─────────────────────────────────────────────────

  Future<void> _capture() async {
    final controller = _controller;
    if (_isCapturing || controller == null || !controller.value.isInitialized) {
      return;
    }

    setState(() => _isCapturing = true);
    if (!AppMotion.isReduced(context)) {
      _shutterFlash.forward(from: 0).whenComplete(() {
        if (mounted) _shutterFlash.reverse();
      });
    }

    try {
      final image = await controller.takePicture();
      if (!mounted) return;
      setState(() {
        _lastShot = image;
        _reviewing = image;
      });
    } catch (e) {
      debugPrint('사진을 찍지 못했습니다: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isCapturing) return;
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null || !mounted) return;
      // 앨범에서 이미 눈으로 고른 것이라 확인 단계를 한 번 더 두지 않는다.
      Navigator.of(context).pop(picked);
    } catch (e) {
      debugPrint('갤러리에서 이미지를 고르지 못했습니다: $e');
    }
  }

  void _openReview(XFile file) => setState(() => _reviewing = file);

  void _retake() => setState(() => _reviewing = null);

  void _useReviewed() {
    final file = _reviewing;
    if (file == null) return;
    Navigator.of(context).pop(file);
  }

  void _close() => Navigator.of(context).pop();

  // ── 초점과 확대 ───────────────────────────────────────────

  Future<void> _focusAt(Offset localPosition, Size previewSize) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    setState(() => _focusPoint = localPosition);
    _focusTimer?.cancel();
    _focusTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _focusPoint = null);
    });

    AppHaptic.selection();

    final normalized = Offset(
      (localPosition.dx / previewSize.width).clamp(0.0, 1.0),
      (localPosition.dy / previewSize.height).clamp(0.0, 1.0),
    );

    try {
      if (controller.value.focusPointSupported) {
        await controller.setFocusPoint(normalized);
        await controller.setFocusMode(FocusMode.auto);
      }
      if (controller.value.exposurePointSupported) {
        await controller.setExposurePoint(normalized);
      }
    } catch (e) {
      debugPrint('초점을 맞추지 못했습니다: $e');
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    _zoomAtScaleStart = _zoom;
  }

  Future<void> _onScaleUpdate(ScaleUpdateDetails details) async {
    final controller = _controller;
    if (controller == null || details.pointerCount < 2) return;
    if (_maxZoom <= _minZoom || _zoomInFlight) return;

    final next = (_zoomAtScaleStart * details.scale).clamp(_minZoom, _maxZoom);
    if ((next - _zoom).abs() < 0.01) return;

    _zoomInFlight = true;
    try {
      await controller.setZoomLevel(next);
      if (!mounted) return;
      setState(() {
        _zoom = next;
        _showZoomLabel = true;
      });
    } catch (e) {
      debugPrint('확대하지 못했습니다: $e');
    } finally {
      _zoomInFlight = false;
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _zoomLabelTimer?.cancel();
    _zoomLabelTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _showZoomLabel = false);
    });
  }

  // ── 그리기 ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final accent = themeProvider.primaryColor;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        // 확인 단계에서 뒤로가기는 화면을 닫는 게 아니라 다시 찍기다.
        canPop: _reviewing == null,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _retake();
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              // ConnectionState.done 은 future 가 에러로 끝난 경우에도 done 이다.
              // 권한 거부나 다른 앱의 카메라 점유로 initialize() 가 실패하면
              // previewSize 가 null 이라 aspectRatio 접근에서 크래시가 난다.
              if (snapshot.connectionState != ConnectionState.done) {
                return const _CameraLoading();
              }

              final controller = _controller;
              if (snapshot.hasError ||
                  controller == null ||
                  !controller.value.isInitialized) {
                return _buildUnavailable(snapshot.error);
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  IgnorePointer(
                    ignoring: _reviewing != null,
                    child: _buildPreviewLayer(controller),
                  ),
                  if (_reviewing == null) ...[
                    _buildTopControls(),
                    _buildBottomControls(accent),
                  ],
                  _buildShutterFlash(),
                  if (_reviewing != null) _buildReview(_reviewing!, accent),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// 미리보기와 그 위에 얹히는 것들.
  ///
  /// [CameraPreview] 가 안에서 세로 비율로 [AspectRatio] 를 한 번 두른다. 같은
  /// 비율을 밖에서 한 번 더 두르는 이유는 미리보기가 실제로 차지하는 크기를
  /// 알아야 탭한 자리를 0~1 좌표로 바꿀 수 있기 때문이다.
  Widget _buildPreviewLayer(CameraController controller) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1 / controller.value.aspectRatio,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final previewSize = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) =>
                  _focusAt(details.localPosition, previewSize),
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              onScaleEnd: _onScaleEnd,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(controller),
                  const IgnorePointer(child: _GuideFrame()),
                  if (_focusPoint != null)
                    _FocusRing(
                      key: ValueKey(_focusPoint),
                      center: _focusPoint!,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        // 미리보기가 밝으면 흰 아이콘이 묻힌다. 위쪽만 살짝 어둡게 깐다.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.45),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: Row(
              children: [
                _GlassIconButton(
                  icon: Icons.close_rounded,
                  semanticLabel: '닫기',
                  onTap: _close,
                ),
                const Spacer(),
                if (_canUseFlash)
                  _GlassIconButton(
                    icon: _flashIcon,
                    semanticLabel: _flashLabel,
                    active: _flashMode != FlashMode.off,
                    onTap: _cycleFlashMode,
                    haptic: HapticLevel.selection,
                  ),
                if (_canUseFlash && _oppositeLens != null)
                  const SizedBox(width: AppSpacing.sm),
                if (_oppositeLens != null)
                  _GlassIconButton(
                    icon: Icons.flip_camera_ios_rounded,
                    semanticLabel: '전후면 전환',
                    onTap: _switchLens,
                    haptic: HapticLevel.selection,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData get _flashIcon {
    switch (_flashMode) {
      case FlashMode.always:
        return Icons.flash_on_rounded;
      case FlashMode.auto:
        return Icons.flash_auto_rounded;
      case FlashMode.off:
      case FlashMode.torch:
        return Icons.flash_off_rounded;
    }
  }

  String get _flashLabel {
    switch (_flashMode) {
      case FlashMode.always:
        return '플래시 켬';
      case FlashMode.auto:
        return '플래시 자동';
      case FlashMode.off:
      case FlashMode.torch:
        return '플래시 끔';
    }
  }

  Widget _buildBottomControls(Color accent) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.6),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.only(top: AppSpacing.xxxl),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_showZoomLabel) ...[
                  _ZoomLabel(zoom: _zoom),
                  const SizedBox(height: AppSpacing.md),
                ],
                StandardText(
                  text: '문제가 안내선 안에 들어오게 맞춰주세요',
                  fontSize: 13,
                  height: 1.3,
                  fontFamily: 'PretendardLight',
                  color: Colors.white.withValues(alpha: 0.85),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.lg),
                // 태블릿에서 갤러리 버튼과 셔터가 화면 양 끝까지 벌어지지 않게 한다.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _GlassIconButton(
                            icon: Icons.photo_library_rounded,
                            semanticLabel: '갤러리에서 고르기',
                            onTap: _pickFromGallery,
                          ),
                        ),
                      ),
                      _ShutterButton(
                        accent: accent,
                        enabled: !_isCapturing,
                        onTap: _capture,
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _LastShotThumbnail(
                            file: _lastShot,
                            onTap: _lastShot == null
                                ? null
                                : () => _openReview(_lastShot!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShutterFlash() {
    return Positioned.fill(
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _shutterFlash.drive(
            Tween<double>(begin: 0.0, end: 0.85)
                .chain(CurveTween(curve: AppMotion.standard)),
          ),
          child: const ColoredBox(color: Colors.white),
        ),
      ),
    );
  }

  /// 찍은 뒤 확인 단계.
  Widget _buildReview(XFile file, Color accent) {
    return Positioned.fill(
      child: GestureDetector(
        // 아래 미리보기로 탭이 새지 않게 막는다.
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: ColoredBox(
          color: Colors.black,
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.large),
                      child: Image.file(
                        File(file.path),
                        fit: BoxFit.contain,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: StandardText(
                            text: '사진을 불러오지 못했어요',
                            fontSize: 14,
                            height: 1.3,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.md,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Row(
                        children: [
                          Expanded(
                            child: _WideButton(
                              label: '다시 찍기',
                              icon: Icons.refresh_rounded,
                              onTap: _retake,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _WideButton(
                              label: '이걸로 쓰기',
                              icon: Icons.check_rounded,
                              fill: accent,
                              haptic: HapticLevel.primary,
                              onTap: _useReviewed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 권한 거부나 카메라 점유로 미리보기를 못 열었을 때.
  Widget _buildUnavailable(Object? error) {
    final denied = _isPermissionDenied(error);

    return SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: _GlassIconButton(
              icon: Icons.close_rounded,
              semanticLabel: '닫기',
              onTap: _close,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: AppSpacing.xxxl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      denied
                          ? Icons.lock_outline_rounded
                          : Icons.no_photography_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  StandardText(
                    text: denied ? '카메라 권한이 꺼져 있어요' : '카메라를 열 수 없어요',
                    fontSize: 18,
                    height: 1.3,
                    color: Colors.white,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  StandardText(
                    text: denied
                        ? '설정에서 카메라 권한을 켜면 바로 촬영할 수 있어요.'
                        : '다른 앱이 카메라를 쓰고 있는지 확인한 뒤 다시 시도해주세요.',
                    fontSize: 14,
                    height: 1.5,
                    fontFamily: 'PretendardLight',
                    color: Colors.white.withValues(alpha: 0.7),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Row(
                      children: [
                        Expanded(
                          child: _WideButton(
                            label: '닫기',
                            onTap: _close,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _WideButton(
                            label: denied ? '설정 열기' : '다시 시도',
                            fill: Colors.white,
                            haptic: HapticLevel.primary,
                            onTap: denied ? openAppSettings : _retryInitialize,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isPermissionDenied(Object? error) {
    if (error is! CameraException) return false;
    final code = error.code.toLowerCase();
    return code.contains('denied') || code.contains('permission');
  }
}

// ── 조각들 ─────────────────────────────────────────────────

class _CameraLoading extends StatelessWidget {
  const _CameraLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          StandardText(
            text: '카메라를 여는 중이에요',
            fontSize: 14,
            height: 1.3,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ],
      ),
    );
  }
}

/// 어두운 미리보기 위에 얹는 동그란 아이콘 버튼.
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;

  /// 켜진 상태. 플래시처럼 지금 값이 무엇인지 보여야 하는 것에 쓴다.
  final bool active;
  final HapticLevel haptic;

  const _GlassIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.active = false,
    this.haptic = HapticLevel.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: PressableScale(
        onTap: onTap,
        haptic: haptic,
        // 44 는 작아서 0.97 로는 눌린 게 안 보인다.
        scale: 0.9,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? Colors.white : Colors.black.withValues(alpha: 0.4),
          ),
          child: Icon(
            icon,
            size: 22,
            color: active ? AppColors.textPrimary : Colors.white,
          ),
        ),
      ),
    );
  }
}

/// 셔터.
class _ShutterButton extends StatelessWidget {
  final Color accent;
  final bool enabled;
  final VoidCallback onTap;

  const _ShutterButton({
    required this.accent,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '촬영',
      child: PressableScale(
        onTap: onTap,
        enabled: enabled,
        // 이 화면에 들어온 이유 그 자체라 가장 센 진동을 준다.
        haptic: HapticLevel.primary,
        scale: 0.92,
        child: Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.95),
              width: 3,
            ),
          ),
          child: Center(
            // 찍는 동안 안쪽 원이 줄어들어 지금 처리 중인 것이 보이게 한다.
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              width: enabled ? 58 : 46,
              height: enabled ? 58 : 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: enabled ? accent : accent.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 방금 찍은 것. 다시 찍기를 눌러도 남아 있어서 되돌아갈 수 있다.
class _LastShotThumbnail extends StatelessWidget {
  final XFile? file;
  final VoidCallback? onTap;

  const _LastShotThumbnail({required this.file, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final current = file;
    if (current == null) {
      // 셔터가 화면 가운데에 남아 있어야 해서 자리는 비워 두지 않는다.
      return const SizedBox(width: 48, height: 48);
    }

    return Semantics(
      label: '방금 찍은 사진 다시 보기',
      child: PressableScale(
        onTap: onTap,
        scale: 0.9,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.medium - 2),
            child: Image.file(
              File(current.path),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => ColoredBox(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 확대 배율.
class _ZoomLabel extends StatelessWidget {
  final double zoom;

  const _ZoomLabel({required this.zoom});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: StandardText(
        text: '${zoom.toStringAsFixed(1)}x',
        fontSize: 13,
        height: 1.2,
        color: Colors.white,
      ),
    );
  }
}

/// 확인 단계와 안내 화면에서 쓰는 가로로 긴 버튼.
class _WideButton extends StatelessWidget {
  final String label;
  final IconData? icon;

  /// 채울 색. null 이면 테두리만 있는 버튼이 된다.
  final Color? fill;
  final HapticLevel haptic;
  final VoidCallback onTap;

  const _WideButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.fill,
    this.haptic = HapticLevel.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final background = fill;
    // 테마색 스물네 가지가 밝은 것부터 어두운 것까지 있다. 어느 것이 얹혀도
    // 글자가 읽히도록 채운 색의 밝기를 보고 글자색을 고른다.
    final foreground = background == null
        ? Colors.white
        : (ThemeData.estimateBrightnessForColor(background) == Brightness.dark
            ? Colors.white
            : AppColors.textPrimary);

    // 버튼 둘이 한 줄을 나눠 쓰는 자리라 글자를 키운 기기에서는 폭이 모자란다.
    // 아이콘은 글자 크기와 무관하게 제 자리를 차지하므로 그때는 뺀다. 글자를
    // 줄여 욱여넣는 것보다 아이콘을 포기하는 쪽이 낫다.
    final showIcon =
        icon != null && MediaQuery.textScalerOf(context).scale(15) <= 20;

    return PressableScale(
      onTap: onTap,
      haptic: haptic,
      child: Container(
        // 글자가 두 줄이 되면 버튼이 제 크기 그대로 커진다.
        constraints: const BoxConstraints(minHeight: 54),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: background ?? Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: background == null
              ? Border.all(color: Colors.white.withValues(alpha: 0.35))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showIcon) ...[
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: AppSpacing.sm),
            ],
            Flexible(
              child: StandardText(
                text: label,
                fontSize: 15,
                height: 1.2,
                color: foreground,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 종이 테두리를 맞추기 쉽게 네 귀퉁이만 그린다.
///
/// 사각형을 통째로 두르면 그 밖은 안 찍힌다는 뜻으로 읽힌다. 실제로는 미리보기
/// 전체가 그대로 찍히므로, 귀퉁이만 그려 "이 안에 맞추면 좋다" 정도로 둔다.
class _GuideFrame extends StatelessWidget {
  const _GuideFrame();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GuideFramePainter());
  }
}

class _GuideFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(
      size.width * 0.07,
      size.height * 0.13,
      size.width * 0.93,
      size.height * 0.87,
    );

    // 귀퉁이 한 변의 길이. 프레임이 작아져도 제 몫은 지키게 범위를 둔다.
    final arm = (rect.shortestSide * 0.09).clamp(20.0, 40.0);
    const radius = 12.0;

    final path = Path()
      // 왼쪽 위
      ..moveTo(rect.left, rect.top + arm)
      ..lineTo(rect.left, rect.top + radius)
      ..arcToPoint(
        Offset(rect.left + radius, rect.top),
        radius: const Radius.circular(radius),
      )
      ..lineTo(rect.left + arm, rect.top)
      // 오른쪽 위
      ..moveTo(rect.right - arm, rect.top)
      ..lineTo(rect.right - radius, rect.top)
      ..arcToPoint(
        Offset(rect.right, rect.top + radius),
        radius: const Radius.circular(radius),
      )
      ..lineTo(rect.right, rect.top + arm)
      // 오른쪽 아래
      ..moveTo(rect.right, rect.bottom - arm)
      ..lineTo(rect.right, rect.bottom - radius)
      ..arcToPoint(
        Offset(rect.right - radius, rect.bottom),
        radius: const Radius.circular(radius),
      )
      ..lineTo(rect.right - arm, rect.bottom)
      // 왼쪽 아래
      ..moveTo(rect.left + arm, rect.bottom)
      ..lineTo(rect.left + radius, rect.bottom)
      ..arcToPoint(
        Offset(rect.left, rect.bottom - radius),
        radius: const Radius.circular(radius),
      )
      ..lineTo(rect.left, rect.bottom - arm);

    // 흰 종이 위에서는 흰 선이 안 보인다. 아래에 옅은 그늘을 한 겹 깐다.
    canvas.drawPath(
      path.shift(const Offset(0, 1)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _GuideFramePainter oldDelegate) => false;
}

/// 탭한 자리에 잠깐 뜨는 초점 표시.
class _FocusRing extends StatelessWidget {
  final Offset center;

  const _FocusRing({super.key, required this.center});

  static const double _size = 76;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: center.dx - _size / 2,
      top: center.dy - _size / 2,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: AppMotion.normal,
          curve: AppMotion.emphasized,
          builder: (context, value, child) => Transform.scale(
            scale: 1.3 - 0.3 * value,
            child: Opacity(opacity: value, child: child),
          ),
          child: Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.small),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.9),
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
