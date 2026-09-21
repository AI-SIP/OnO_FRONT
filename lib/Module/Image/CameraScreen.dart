import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'CameraCapture.dart';
import 'CropImage.dart';
import '../Design/AppColors.dart';
import '../Design/AppToast.dart';
import '../Design/AppRadius.dart';
import '../Design/AppSpacing.dart';
import '../Motion/AppHaptic.dart';
import '../Motion/AppMotion.dart';
import '../Motion/PressableScale.dart';
import '../Motion/TossDialog.dart';
import '../Text/StandardText.dart';
import '../Theme/ThemeHandler.dart';
import '../../Util/AppAnalytics.dart';

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

  /// 여러 장을 담아 두고 계속 찍는 모드인지.
  ///
  /// 장수로 판단하면 안 된다. 스무 장 중 열아홉을 채운 뒤에는 남은 자리가
  /// 하나라 [maxShots] 가 1 이 되는데, 그렇다고 화면이 한 장짜리로 바뀌면
  /// "카메라로 여러 장 촬영" 을 골랐는데 담기도 완료도 없는 화면이 나온다.
  final bool multiple;

  /// 담을 수 있는 최대 장수. 다 채우면 완료를 안 눌러도 나간다.
  final int maxShots;

  const CameraScreen({
    super.key,
    required this.cameras,
    this.multiple = false,
    this.maxShots = 1,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  /// 지금 쓰는 카메라. 전후면 전환이 이걸 바꾼다.
  late CameraDescription _description;

  FlashMode _flashMode = FlashMode.off;

  /// 셔터를 연달아 눌러 `takePicture was called before the previous capture
  /// returned` 로 터지는 것을 막는다.
  bool _isCapturing = false;
  bool _isSwitchingLens = false;

  /// 문서 스캐너를 여는 중. 연달아 누르면 두 번 열린다.
  bool _isScanning = false;

  /// 확인 단계에 올라와 있는 사진. null 이면 촬영 화면이다.
  XFile? _reviewing;

  /// 방금 찍은 것. 다시 찍기를 눌러도 남겨 둬서 되돌아갈 수 있게 한다.
  XFile? _lastShot;

  /// 여러 장 모드에서 담아 둔 것들. 완료를 누르면 이걸 통째로 돌려준다.
  final List<XFile> _shots = [];

  /// 담은 것들을 펼쳐 보는 중인지.
  bool _showTray = false;

  /// 펼쳐 보는 중에 지금 보고 있는 사진.
  int _trayIndex = 0;
  PageController? _trayPager;
  final ScrollController _filmstrip = ScrollController();

  /// 확인 단계에 올라온 것을 자르기까지 마쳤는지.
  ///
  /// 잘라 놓고도 이걸 안 알려 주면 등록 화면이 자르기를 한 번 더 띄운다.
  bool _reviewCropped = false;

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

  /// 화면 밖으로 나가면서 내려놓는 중인 카메라.
  Future<void>? _releasing;

  /// 지금 잡는 중인 것. 여러 곳에서 동시에 잡으러 오는 것을 하나로 모은다.
  Future<void>? _acquiring;

  /// 결과를 들고 이미 나간 상태. 나가는 중에 카메라를 새로 잡으면 아무도
  /// 안 놓는 세션이 남는다.
  bool _leaving = false;

  /// 카메라를 놓아 둔 상태.
  ///
  /// 놓아 둔 것은 실패한 것이 아니라 기다리는 것이다. 이걸 구분하지 않으면,
  /// 놓은 뒤부터 다시 잡기 전까지 사이에 화면이 한 번이라도 다시 그려질 때
  /// "카메라를 열 수 없어요" 가 번쩍인다.
  bool _cameraReleased = false;

  @override
  void initState() {
    super.initState();
    AppAnalytics.logScreenView('CameraScreen');

    // 화면 방향을 세로로 고정
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    _shutterFlash = AnimationController(
      vsync: this,
      duration: AppMotion.press,
      reverseDuration: AppMotion.fast,
    );

    WidgetsBinding.instance.addObserver(this);
    _description = _initialDescription();
    _initializeControllerFuture = _setUpController(_description);
  }

  /// 화면이 정말로 밖으로 나갔을 때만 카메라를 놓는다.
  ///
  /// 안드로이드는 자르기와 문서 스캐너가 다른 액티비티라, 그리로 넘어가면
  /// 카메라를 내주고 돌아와도 알아서 되찾지 않는다. 미리보기가 검게 죽은 채로
  /// 남는다. 그래서 나갈 때 내려놓고 돌아올 때 다시 잡아야 한다.
  ///
  /// 다만 그 기준을 [AppLifecycleState.inactive] 로 잡으면 안 된다. iOS 는
  /// 자르기 화면을 이 화면 위에 얹기만 해도 inactive 를 보내는데, 앱은 여전히
  /// 앞에 있고 카메라도 그대로 쓸 수 있다. 거기서 카메라를 놓아 버리면 돌아올
  /// 때 아직 내려가는 중인 세션 위에 새로 잡으려다 실패해서, 자르기를 마치고
  /// 나온 사람에게 "카메라를 열 수 없어요" 가 뜬다.
  ///
  /// [AppLifecycleState.paused] 는 화면 밖으로 나갔을 때만 온다. 안드로이드가
  /// 다른 액티비티로 넘어가는 경우가 여기 들어오고, iOS 가 화면 위에 무언가를
  /// 얹는 경우는 안 들어온다. 양쪽 다 필요한 만큼만 하게 된다.
  ///
  /// 담아 둔 사진은 화면 상태라 그대로 남는다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final controller = _controller;
      if (controller == null) return;

      _controller = null;
      // 내려가는 것을 붙잡아 둔다. 다시 잡기 전에 이게 끝나야 한다.
      _releasing = controller.dispose();
      setState(() => _cameraReleased = true);
      return;
    }

    if (state == AppLifecycleState.resumed && _controller == null) {
      _acquire();
    }
  }

  /// 카메라가 아직 살아 있는지 보고, 죽었으면 다시 잡는다.
  ///
  /// 문서 스캐너는 자기가 카메라를 쓰는 화면이라 우리 세션을 끊고 간다. iOS 는
  /// 이걸 이 화면 위에 얹어서 열기 때문에 화면 밖으로 나갔다는 신호가 오지
  /// 않는다. 돌아왔을 때 알아서 살아 있기도 하고 아니기도 해서, 물어보고
  /// 죽었을 때만 다시 잡는다.
  void _ensureCameraAlive() {
    final controller = _controller;
    if (controller != null &&
        controller.value.isInitialized &&
        !controller.value.hasError) {
      return;
    }
    _acquire();
  }

  /// 카메라를 잡는 유일한 입구.
  ///
  /// 들어오는 길이 여럿이다. 화면에 처음 들어올 때, 화면 밖으로 나갔다 돌아올
  /// 때, 문서 스캐너에서 나올 때, 안내 화면에서 다시 시도를 누를 때.
  ///
  /// 안드로이드에서 문서 스캐너는 별도 액티비티라 스캐너가 끝나는 것과
  /// `resumed` 가 오는 것이 거의 동시에 일어난다. 둘이 각각 카메라를 잡으면
  /// 컨트롤러가 두 개가 되고, 하나는 하드웨어를 쥔 채 아무도 안 놓는 유령이
  /// 되고 다른 하나는 "쓰는 중" 이라며 실패한다. 그러면 다시 시도를 눌러도
  /// 유령이 카메라를 쥐고 있어서 화면을 나가기 전까지 안 풀린다.
  ///
  /// 그래서 잡는 일은 항상 이 함수 하나를 거치고, 이미 잡는 중이면 그것을
  /// 그대로 쓴다.
  void _acquire() {
    if (!mounted) return;

    final inFlight = _acquiring;
    if (inFlight != null) {
      // 이미 누가 잡고 있다. 화면은 그 결과를 같이 기다린다.
      setState(() {
        _cameraReleased = false;
        _initializeControllerFuture = inFlight;
      });
      return;
    }

    final acquiring = _acquireWithRetry();
    _acquiring = acquiring;
    acquiring.whenComplete(() {
      if (identical(_acquiring, acquiring)) _acquiring = null;
    });

    setState(() {
      _cameraReleased = false;
      _initializeControllerFuture = acquiring;
    });
  }

  /// 쓰던 것을 확실히 내려놓고 새로 잡는다.
  ///
  /// 앞의 것이 다 내려가기 전에 새로 잡으면 기기가 아직 쓰는 중이라며 거절한다.
  /// 끝나기를 기다리고, 그래도 안 되면 한 박자 쉬고 다시 해 본다.
  Future<void> _acquireWithRetry() async {
    final previous = _controller;
    _controller = null;
    if (previous != null) await previous.dispose();

    await _releasing;
    _releasing = null;

    for (var attempt = 0;; attempt++) {
      try {
        await _setUpController(_description);
        return;
      } catch (e) {
        if (attempt >= 2) rethrow;
        debugPrint('카메라를 다시 잡지 못해 재시도합니다: $e');
        await Future<void>.delayed(const Duration(milliseconds: 250));
        if (!mounted) return;
      }
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    WidgetsBinding.instance.removeObserver(this);
    _trayPager?.dispose();
    _filmstrip.dispose();
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

    try {
      await controller.initialize();
    } catch (_) {
      // 여기서 안 놓으면 실패한 것이 네이티브 핸들을 쥔 채 남는다. 재시도가
      // 도는 경로라 흘릴수록 다음 시도가 더 안 된다.
      await controller.dispose();
      rethrow;
    }

    // 잡는 사이에 화면이 사라졌으면 쥐고 있을 이유가 없다.
    if (!mounted || _leaving) {
      await controller.dispose();
      return;
    }

    _controller = controller;
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

  void _retryInitialize() => _acquire();

  Future<void> _switchLens() async {
    final next = _oppositeLens;
    final controller = _controller;
    if (next == null ||
        controller == null ||
        _isSwitchingLens ||
        _isCapturing) {
      return;
    }

    setState(() => _isSwitchingLens = true);
    try {
      await controller.setDescription(next);
      _description = next;
      await _readZoomBounds(controller);
      await _applyFlashMode(controller);
    } catch (e) {
      debugPrint('카메라를 전환하지 못했습니다: $e');
      AppToast.error('카메라를 바꾸지 못했어요.');
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
    if (_isCapturing ||
        _isSwitchingLens ||
        _isScanning ||
        _showTray ||
        controller == null ||
        !controller.value.isInitialized) {
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
      // 일반 촬영과 문서 스캔 중 무엇을 쓰는지, 플래시를 켜는지 본다.
      AppAnalytics.logEvent('camera_capture', {
        'mode': 'photo',
        'flash': _flashMode.name,
        'multiple': _isMulti,
      });
      if (!mounted) return;
      setState(() {
        _lastShot = image;
        _reviewing = image;
      });
    } catch (e) {
      debugPrint('사진을 찍지 못했습니다: $e');
      // 셔터를 눌러 진동과 번쩍임까지 받았는데 아무 일도 안 일어나면
      // 사용자는 자기가 잘못 누른 줄 안다.
      AppToast.error('사진을 찍지 못했어요. 다시 눌러 보세요.');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isCapturing) return;
    try {
      final picker = ImagePicker();

      // 앨범에서 이미 눈으로 고른 것이라 확인 단계를 한 번 더 두지 않는다.
      if (!_isMulti) {
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked == null || !mounted) return;
        _leaving = true;
        Navigator.of(context).pop(CameraCapture.one(picked));
        return;
      }

      // limit 은 2 이상이어야 한다. 1 을 주면 세 플랫폼 구현이 모두
      // ArgumentError 를 던져서 버튼이 조용히 죽는다. 남은 자리가 하나면
      // 제한 없이 고르게 하고 _addShots 가 잘라 낸다.
      final picked = await picker.pickMultiImage(
        limit: _remainingShots >= 2 ? _remainingShots : null,
      );
      if (picked.isEmpty || !mounted) return;
      _addShots(picked);
    } catch (e) {
      debugPrint('갤러리에서 이미지를 고르지 못했습니다: $e');
      AppToast.error('앨범을 열지 못했어요.');
    }
  }

  /// 여러 장 모드인지. 담아 두고 계속 찍는다.
  bool get _isMulti => widget.multiple;

  /// 앞으로 몇 장 더 담을 수 있는지.
  int get _remainingShots => widget.maxShots - _shots.length;

  bool get _isFull => _remainingShots <= 0;

  /// 담고, 다 찼으면 바로 나간다.
  void _addShots(List<XFile> files) {
    // 같은 파일을 두 번 담지 않는다. 확인 단계를 다시 열어 담기를 또 누르면
    // 같은 사진이 두 장으로 늘어나던 일이 있었다.
    final fresh = files
        .where((file) => !_shots.any((shot) => shot.path == file.path))
        .take(_remainingShots)
        .toList();

    setState(() {
      _shots.addAll(fresh);
      _reviewing = null;
      _reviewCropped = false;
      if (_shots.isNotEmpty) _lastShot = _shots.last;
    });
    if (_isFull) _finishMulti();
  }

  // ── 담은 것 펼쳐 보기 ─────────────────────────────────────

  /// 썸네일 한 칸의 크기와 사이 간격. 스트립을 굴릴 자리를 계산하는 데 쓴다.
  static const double _thumbSize = 56;
  static const double _thumbGap = AppSpacing.sm;

  void _openTray() {
    if (_shots.isEmpty || _reviewing != null) return;

    // 방금 찍은 것부터 보는 게 자연스럽다. 썸네일이 보여 주던 것도 그것이다.
    final index = _shots.length - 1;
    _trayPager?.dispose();
    _trayPager = PageController(initialPage: index);

    setState(() {
      _trayIndex = index;
      _showTray = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealThumb(index));
  }

  void _closeTray() => setState(() => _showTray = false);

  /// 보고 있는 사진의 썸네일이 스트립 밖으로 밀려나 있으면 끌어온다.
  void _revealThumb(int index) {
    if (!_filmstrip.hasClients) return;

    final position = _filmstrip.position;
    final centered = index * (_thumbSize + _thumbGap) -
        (position.viewportDimension - _thumbSize) / 2;

    _filmstrip.animateTo(
      centered.clamp(0.0, position.maxScrollExtent),
      duration: AppMotion.normal,
      curve: AppMotion.standard,
    );
  }

  void _showShot(int index) {
    setState(() => _trayIndex = index);
    _trayPager?.animateToPage(
      index,
      duration: AppMotion.normal,
      curve: AppMotion.standard,
    );
    _revealThumb(index);
  }

  /// 뺄 건지 한 번 더 묻는다.
  ///
  /// 되돌릴 수 없다. 목록에서 빠진 사진은 촬영 화면으로 돌아가도 없고, 다시
  /// 찍는 수밖에 없다.
  Future<void> _confirmRemoveShot(int index) async {
    final confirmed = await showTossDialog<bool>(
      context: context,
      // 목록 바탕이 이미 거의 검다. 기본 가림막으로는 다이얼로그가 떠 보이지
      // 않아서 한 단계 더 어둡게 깐다.
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (context) => _RemoveShotDialog(order: index + 1),
    );

    if (confirmed != true || !mounted) return;
    _removeShot(index);
  }

  void _removeShot(int index) {
    // 뺀 사진은 다시 볼 일이 없다. 캐시에 남겨 두면 자리만 차지한다.
    _evictCached(_shots[index]);

    setState(() {
      _shots.removeAt(index);
      _lastShot = _shots.isEmpty ? null : _shots.last;
      if (_shots.isEmpty) {
        _showTray = false;
        return;
      }
      _trayIndex = index.clamp(0, _shots.length - 1);
    });

    if (_shots.isEmpty) return;
    // 목록이 한 칸 줄어든 뒤에 옮겨야 한다. 같은 프레임에 옮기면 아직 있는
    // 줄 아는 칸으로 뛴다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_showTray) return;
      final pager = _trayPager;
      if (pager != null && pager.hasClients) pager.jumpToPage(_trayIndex);
      _revealThumb(_trayIndex);
    });
  }

  /// 담아 둔 것 하나를 잘라서 그 자리에 도로 넣는다.
  Future<void> _cropShot(int index) async {
    final accent =
        Provider.of<ThemeHandler>(context, listen: false).primaryColor;
    final cropped = await cropImageFile(_shots[index], accent: accent);
    if (cropped == null || !mounted) return;

    setState(() {
      _shots[index] = cropped;
      _lastShot = _shots.last;
    });
  }

  void _evictCached(XFile file) {
    FileImage(File(file.path)).evict();
  }

  /// 확인 단계에 올라온 것을 자른다.
  Future<void> _cropReviewing() async {
    final file = _reviewing;
    if (file == null) return;

    final accent =
        Provider.of<ThemeHandler>(context, listen: false).primaryColor;
    final cropped = await cropImageFile(file, accent: accent);
    if (cropped == null || !mounted) return;

    setState(() {
      _reviewing = cropped;
      _reviewCropped = true;
    });
  }

  void _finishMulti() {
    if (_shots.isEmpty) return;
    _leaving = true;
    // 여러 장은 크롭 화면을 거치지 않으므로 alreadyCropped 를 보지 않는다.
    Navigator.of(context).pop(CameraCapture(files: List.of(_shots)));
  }

  /// 담아 둔 것을 버리고 나갈 건지 묻는다.
  ///
  /// 한 장을 뺄 때는 확인을 받으면서 전부 버릴 때는 안 묻고 있었다. 열 몇 장을
  /// 찍어 놓고 닫기를 잘못 누르면 안내도 없이 다 날아갔다.
  Future<bool> _confirmDiscard() async {
    if (_shots.isEmpty) return true;

    final discard = await showTossDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (context) => _DiscardShotsDialog(count: _shots.length),
    );
    return discard == true;
  }

  /// 문서 모드. OS 가 가진 문서 스캐너를 띄운다.
  ///
  /// 두 가지를 해 준다. 첫째가 원근 보정이다. 종이의 네 귀퉁이를 찾아 비스듬히
  /// 찍힌 사각형을 반듯한 직사각형으로 편다. 둘째가 보정 필터다. 그림자와
  /// 얼룩을 걷어 내고 종이를 하얗게 만든다.
  ///
  /// 원근 보정은 끌 수 없는 기본 동작이고 필터는 사용자가 스캐너 화면에서
  /// 고른다. 안드로이드의 ML Kit 과 iOS 의 VisionKit 이 이미 아주 잘하는
  /// 일이라 우리가 직접 할 이유가 없다.
  ///
  /// 대신 이건 OS 가 그리는 화면이라 이 화면의 생김새를 물려받지 못한다. 그래서
  /// 기본 촬영을 이쪽으로 바꾸지 않고 따로 들어가는 길만 냈다.
  ///
  /// 안드로이드는 [AndroidScannerMode.full] 이라야 보정 필터가 붙는다.
  /// base 는 자르기만 하고 필터가 없다.
  ///
  /// iOS 는 여기서 필터를 정해 줄 수 없다. 카메라로 들어가면 애플의
  /// `VNDocumentCameraViewController` 가 통째로 화면을 맡고, 필터 종류와
  /// 기본값도 그쪽이 정한다. 패키지의 `iosScannerOptions` 는 앨범에서 가져올
  /// 때 쓰는 자체 크롭 화면에만 걸리는 값이라(CunningDocumentScannerPlugin
  /// .swift:292) 여기서는 넘겨도 아무 일이 없다.
  ///
  /// 필터가 신경 쓰이는 이유가 있다. 오답노트는 찍은 뒤에 색을 골라 필기를
  /// 지우는 기능([ImageColorPickerHandler])을 쓰는데, 사용자가 흑백 필터로
  /// 저장하면 고를 색이 남지 않는다. 양쪽 다 기본값은 색을 살리는 쪽이라
  /// 그대로 두면 문제가 없다.
  Future<void> _scanDocument() async {
    if (_isCapturing || _isScanning) return;

    setState(() => _isScanning = true);
    try {
      final paths = await CunningDocumentScanner.getPictures(
        // 스캐너도 여러 장을 지원한다. 남은 만큼만 받는다.
        noOfPages: _isMulti ? _remainingShots : 1,
        androidScannerMode: AndroidScannerMode.full,
      );

      if (paths == null || paths.isEmpty || !mounted) return;
      AppAnalytics.logEvent('camera_capture', {
        'mode': 'scan',
        'count': paths.length,
        'multiple': _isMulti,
      });

      // 여러 장 모드에서는 이미 담아 둔 것이 있을 수 있으니 합쳐서 들고 간다.
      if (_isMulti) {
        _addShots(paths.map(XFile.new).toList());
        return;
      }

      // 스캐너가 이미 반듯하게 잘라 준 것이라 크롭 화면으로 넘기지 않는다.
      _leaving = true;
      Navigator.of(context).pop(
        CameraCapture.one(XFile(paths.first), alreadyCropped: true),
      );
    } catch (e) {
      debugPrint('문서 스캔을 열지 못했습니다: $e');
      AppToast.error('문서 스캔을 열지 못했어요. 잠시 뒤 다시 시도해 주세요.');
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
        // 스캐너가 카메라를 가져갔다 돌려준다. 그대로 살아 있으면 아무것도
        // 안 하고, 끊겨 있으면 다시 잡는다. 이미 결과를 들고 나간 뒤라면
        // 잡을 이유가 없다. 나가는 중에 잡으면 아무도 안 놓는 세션이 남는다.
        if (!_leaving) _ensureCameraAlive();
      }
    }
  }

  void _openReview(XFile file) => setState(() {
        _reviewing = file;
        _reviewCropped = false;
      });

  void _retake() => setState(() {
        _reviewing = null;
        _reviewCropped = false;
      });

  void _useReviewed() {
    final file = _reviewing;
    if (file == null) return;

    if (_isMulti) {
      _addShots([file]);
      return;
    }
    // 여기서 이미 잘랐으면 등록 화면이 자르기를 또 띄우지 않게 알린다.
    _leaving = true;
    Navigator.of(context).pop(
      CameraCapture.one(file, alreadyCropped: _reviewCropped),
    );
  }

  Future<void> _close() async {
    if (!await _confirmDiscard() || !mounted) return;
    _leaving = true;
    Navigator.of(context).pop();
  }

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
        canPop: _reviewing == null && !_showTray && _shots.isEmpty,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          // 확인 단계가 먼저다. 목록 위에 확인 단계가 겹쳐 있을 수 있다.
          if (_reviewing != null) {
            _retake();
            return;
          }
          if (_showTray) {
            _closeTray();
            return;
          }
          await _close();
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              // ConnectionState.done 은 future 가 에러로 끝난 경우에도 done 이다.
              // 권한 거부나 다른 앱의 카메라 점유로 initialize() 가 실패하면
              // previewSize 가 null 이라 aspectRatio 접근에서 크래시가 난다.
              // 확인 단계와 담은 사진 목록은 카메라가 필요 없는 화면이다.
              // 카메라 상태로 먼저 갈라 버리면, 자르기를 하러 나갔다 돌아오는
              // 사이에 담아 둔 사진이 화면에서 사라지고, 재획득이 실패하면
              // 안내 화면에 갇혀 찍어 둔 것을 통째로 버리게 된다.
              final reviewing = _reviewing;
              if (reviewing != null) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: Colors.black),
                    _buildReview(reviewing, accent),
                  ],
                );
              }
              if (_showTray) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: Colors.black),
                    _buildTray(accent),
                  ],
                );
              }

              if (_cameraReleased ||
                  snapshot.connectionState != ConnectionState.done) {
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
                  _buildPreviewLayer(controller),
                  _buildTopControls(),
                  _buildBottomControls(accent),
                  _buildShutterFlash(),
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
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _DocumentModeBanner(
                    enabled: !_isScanning,
                    onTap: _scanDocument,
                  ),
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
                        enabled: !_isCapturing && !_isFull,
                        onTap: _capture,
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _LastShotThumbnail(
                            file: _lastShot,
                            // 여러 장 모드에서는 몇 장 담았는지가 여기서
                            // 보여야 한다. 한 장짜리에서는 셀 것이 없다.
                            count: _isMulti ? _shots.length : 0,
                            // 여러 장 모드에서 누르면 담은 것을 펼쳐 본다.
                            // 예전에는 마지막 것의 확인 단계를 다시 열었는데,
                            // 거기서 담기를 또 누르면 같은 사진이 두 장이 됐다.
                            onTap: _isMulti
                                ? (_shots.isEmpty ? null : _openTray)
                                : (_lastShot == null
                                    ? null
                                    : () => _openReview(_lastShot!)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isMulti && _shots.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: _WideButton(
                      label: '${_shots.length}장 담았어요 · 완료',
                      icon: Icons.check_rounded,
                      fill: accent,
                      haptic: HapticLevel.primary,
                      onTap: _finishMulti,
                    ),
                  ),
                ],
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Row(
                    children: [
                      if (_reviewCropped)
                        StandardText(
                          text: '잘라 뒀어요',
                          fontSize: 13,
                          height: 1.3,
                          fontFamily: 'PretendardLight',
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      const Spacer(),
                      _GlassIconButton(
                        icon: Icons.crop_rounded,
                        semanticLabel: '자르기',
                        onTap: _cropReviewing,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.large),
                      child: _ShotImage(file: file),
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
                              // 여러 장 모드에서는 이걸 눌러도 안 나가고
                              // 촬영 화면으로 돌아온다. 나가는 것처럼 읽히면
                              // 안 되므로 문구를 바꾼다.
                              label: _isMulti ? '담기' : '이걸로 쓰기',
                              icon: _isMulti
                                  ? Icons.add_rounded
                                  : Icons.check_rounded,
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

  /// 담아 둔 것을 펼쳐 보는 자리.
  ///
  /// 여러 장을 찍다 보면 뭘 담았는지 잊는다. 잘못 찍힌 것을 빼고, 삐뚤게
  /// 찍힌 것을 자를 수 있어야 한다. 예전에는 오른쪽 아래 썸네일이 마지막 것을
  /// 다시 보여 주기만 해서 둘 다 못 했다.
  ///
  /// 사진 앱과 같은 모양으로 둔다. 큰 사진을 좌우로 넘기고, 아래 띠에서 지금
  /// 어디쯤인지 보고 건너뛴다. 편집과 제거는 지금 보고 있는 한 장에 대한
  /// 것이라 사진 바로 아래에 둔다.
  Widget _buildTray(Color accent) {
    final total = _shots.length;

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.96),
          child: SafeArea(
            child: Column(
              children: [
                _buildTrayHeader(accent, total),
                Expanded(
                  child: PageView.builder(
                    controller: _trayPager,
                    itemCount: total,
                    onPageChanged: (index) {
                      setState(() => _trayIndex = index);
                      _revealThumb(index);
                    },
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.large),
                        child: _ShotImage(file: _shots[index]),
                      ),
                    ),
                  ),
                ),
                _buildTrayActions(),
                _buildFilmstrip(accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrayHeader(Color accent, int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          _GlassIconButton(
            icon: Icons.close_rounded,
            semanticLabel: '촬영 화면으로 돌아가기',
            onTap: _closeTray,
          ),
          Expanded(
            child: Center(
              child: StandardText(
                text: '${_trayIndex + 1} / $total',
                fontSize: 15,
                height: 1.2,
                color: Colors.white,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // 완료는 어느 사진을 보고 있든 눌릴 수 있어야 해서 머리에 둔다.
          _TrayDoneButton(accent: accent, count: total, onTap: _finishMulti),
        ],
      ),
    );
  }

  /// 지금 보고 있는 한 장에 대한 것.
  Widget _buildTrayActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Row(
            children: [
              Expanded(
                child: _WideButton(
                  label: '편집하기',
                  icon: Icons.crop_rounded,
                  onTap: () => _cropShot(_trayIndex),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _WideButton(
                  label: '제거하기',
                  icon: Icons.delete_outline_rounded,
                  haptic: HapticLevel.selection,
                  onTap: () => _confirmRemoveShot(_trayIndex),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilmstrip(Color accent) {
    return SizedBox(
      height: _thumbSize + AppSpacing.lg,
      child: ListView.separated(
        controller: _filmstrip,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: _shots.length,
        separatorBuilder: (context, index) => const SizedBox(width: _thumbGap),
        itemBuilder: (context, index) => _FilmstripThumb(
          file: _shots[index],
          index: index,
          size: _thumbSize,
          selected: index == _trayIndex,
          accent: accent,
          onTap: () => _showShot(index),
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

/// 문서 모드로 들어가는 자리.
///
/// 아이콘 하나로 두면 눌러 보기 전에는 무슨 일이 일어나는지 알 수 없다. 이건
/// 다른 화면으로 넘어가는 데다 결과물까지 달라지는 것이라, 무엇을 해 주는지를
/// 글로 적어 둔다.
class _DocumentModeBanner extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _DocumentModeBanner({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // 글자를 키운 기기에서는 화살표가 차지하는 폭을 글자에 준다.
    final showChevron = MediaQuery.textScalerOf(context).scale(14) <= 19;

    return Semantics(
      label: '문서 모드로 찍기. 종이를 반듯하게 펴고 밝게 보정해요',
      child: PressableScale(
        onTap: onTap,
        enabled: enabled,
        child: AnimatedOpacity(
          duration: AppMotion.fast,
          opacity: enabled ? 1 : 0.5,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(AppRadius.large),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  child: const Icon(
                    Icons.auto_fix_high_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const StandardText(
                        text: '문서 모드로 찍기',
                        fontSize: 14,
                        height: 1.25,
                        color: Colors.white,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      StandardText(
                        text: '종이를 반듯하게 펴고 밝게 보정해요',
                        fontSize: 11,
                        height: 1.3,
                        fontFamily: 'PretendardLight',
                        color: Colors.white.withValues(alpha: 0.8),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (showChevron) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ],
              ],
            ),
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

  /// 담아 둔 장수. 0 이면 배지를 안 그린다.
  final int count;

  const _LastShotThumbnail({
    required this.file,
    required this.onTap,
    this.count = 0,
  });

  @override
  Widget build(BuildContext context) {
    final current = file;
    if (current == null) {
      // 셔터가 화면 가운데에 남아 있어야 해서 자리는 비워 두지 않는다.
      return const SizedBox(width: 48, height: 48);
    }

    return Semantics(
      label: count > 0 ? '담은 사진 $count장' : '방금 찍은 사진 다시 보기',
      child: PressableScale(
        onTap: onTap,
        scale: 0.9,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
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
                  child: _ShotImage(
                    file: current,
                    fit: BoxFit.cover,
                    decodeWidth: 48,
                  ),
                ),
              ),
              if (count > 0)
                Positioned(
                  top: -6,
                  right: -6,
                  // 라벨이 이미 "담은 사진 N장"이라고 말한다. 배지의 숫자까지
                  // 읽히면 "담은 사진 1장 1"이 된다.
                  child: ExcludeSemantics(
                      child: Container(
                    constraints: const BoxConstraints(minWidth: 22),
                    height: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Center(
                      child: StandardText(
                        text: '$count',
                        fontSize: 12,
                        height: 1.0,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  )),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 파일에서 읽어 그리는 사진.
///
/// 그냥 [Image.file] 을 쓰면 두 가지가 걸린다. 첫째, 다 읽을 때까지 빈자리로
/// 남아서 화면이 잠깐 비어 보인다. 둘째, 자르기 도구가 파일을 막 쓰고 나온
/// 직후에는 아직 다 안 써진 것을 읽어 실패할 때가 있다. 그때 errorBuilder 가
/// 곧바로 "불러오지 못했어요" 를 띄우는데, 한 박자 뒤에 다시 읽으면 멀쩡히
/// 열리는 것이라 그 문구는 거짓말이 된다.
///
/// 읽는 동안에는 도는 표시를 보여 주고, 실패하면 몇 번 더 시도한 다음에야
/// 못 읽었다고 말한다.
class _ShotImage extends StatefulWidget {
  final XFile file;
  final BoxFit fit;

  /// 그려질 크기(논리 픽셀). 주면 그만큼만 디코딩한다.
  ///
  /// 안 주면 원본 해상도로 푼다. 12MP 사진 한 장이 46MB 라, 56px 짜리
  /// 썸네일 띠에 스무 장을 걸면 그대로 앉는다. 큰 화면과 썸네일이 같은
  /// 캐시 키를 쓰는 것도 문제였다. 크기를 주면 키가 갈린다.
  final double? decodeWidth;

  const _ShotImage({
    required this.file,
    this.fit = BoxFit.contain,
    this.decodeWidth,
  });

  @override
  State<_ShotImage> createState() => _ShotImageState();
}

class _ShotImageState extends State<_ShotImage> {
  /// 다시 읽어 본 횟수. 키에 섞어서 [Image] 를 새로 만들게 한다.
  int _attempt = 0;
  bool _giveUp = false;
  Timer? _retryTimer;

  static const int _maxAttempts = 3;
  static const Duration _retryDelay = Duration(milliseconds: 200);

  @override
  void didUpdateWidget(covariant _ShotImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path == widget.file.path) return;

    _retryTimer?.cancel();
    _attempt = 0;
    _giveUp = false;
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _scheduleRetry() {
    if (_retryTimer?.isActive ?? false) return;

    _retryTimer = Timer(_retryDelay, () {
      if (!mounted) return;
      setState(() {
        if (_attempt >= _maxAttempts) {
          _giveUp = true;
        } else {
          _attempt++;
          FileImage(File(widget.file.path)).evict();
        }
      });
    });
  }

  int? _cacheWidth(BuildContext context) {
    final width = widget.decodeWidth;
    if (width == null) return null;
    return (width * MediaQuery.devicePixelRatioOf(context)).round();
  }

  @override
  Widget build(BuildContext context) {
    if (_giveUp) {
      return Center(
        child: StandardText(
          text: '사진을 불러오지 못했어요',
          fontSize: 14,
          height: 1.3,
          color: Colors.white.withValues(alpha: 0.8),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Image.file(
      File(widget.file.path),
      key: ValueKey('${widget.file.path}#$_attempt'),
      fit: widget.fit,
      width: double.infinity,
      cacheWidth: _cacheWidth(context),
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return const _ShotImageLoading();
      },
      errorBuilder: (context, error, stackTrace) {
        // build 중이라 여기서 바로 setState 를 하면 안 된다.
        WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleRetry());
        return const _ShotImageLoading();
      },
    );
  }
}

class _ShotImageLoading extends StatelessWidget {
  const _ShotImageLoading();

  @override
  Widget build(BuildContext context) {
    // 동작 줄이기를 켠 기기에서는 도는 것 대신 자리만 잡아 둔다.
    if (AppMotion.isReduced(context)) {
      return ColoredBox(color: Colors.white.withValues(alpha: 0.08));
    }

    return Center(
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(
            Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

/// 담아 둔 것을 통째로 버리고 나갈 건지 묻는 것.
class _DiscardShotsDialog extends StatelessWidget {
  final int count;

  const _DiscardShotsDialog({required this.count});

  @override
  Widget build(BuildContext context) {
    return _CameraDialog(
      icon: Icons.exit_to_app_rounded,
      title: '담은 $count장을 버릴까요?',
      description: '지금 나가면 찍은 사진이 등록되지 않아요.',
      confirmLabel: '버리고 나가기',
      onCancel: () => Navigator.pop(context, false),
      onConfirm: () => Navigator.pop(context, true),
    );
  }
}

/// 담은 사진을 뺄 건지 묻는 것.
///
/// 앱의 다른 삭제 확인은 흰 카드인데 여기서는 안 맞는다. 이 다이얼로그가
/// 뜨는 자리가 검은 사진 목록 위라, 흰 카드가 튀어나오면 다른 앱에서 온
/// 것처럼 보인다. 목록과 같은 어두운 면에 같은 버튼을 쓴다.
class _RemoveShotDialog extends StatelessWidget {
  /// 몇 번째 사진인지. 목록에서 보고 있던 자리를 그대로 말해 준다.
  final int order;

  const _RemoveShotDialog({required this.order});

  @override
  Widget build(BuildContext context) {
    return _CameraDialog(
      icon: Icons.delete_outline_rounded,
      title: '이 사진을 뺄까요?',
      description: '$order번째 사진이에요. 빼면 다시 찍어야 해요.',
      confirmLabel: '빼기',
      onCancel: () => Navigator.pop(context, false),
      onConfirm: () => Navigator.pop(context, true),
    );
  }
}

/// 촬영 화면 위에 뜨는 확인 창.
///
/// 앱의 다른 확인 창은 흰 카드인데 여기서는 안 맞는다. 이게 뜨는 자리가 검은
/// 촬영 화면이나 사진 목록 위라, 흰 카드가 튀어나오면 다른 앱에서 온 것처럼
/// 보인다. 목록과 같은 어두운 면에 같은 버튼을 쓴다.
class _CameraDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _CameraDialog({
    required this.icon,
    required this.title,
    required this.description,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
  });

  /// 목록 바탕보다 한 겹 떠 보이는 면. 검은 바탕 위에 흰색을 옅게 얹은 값이다.
  static const Color _surface = Color(0xFF1C1D20);

  /// 되돌릴 수 없는 쪽.
  static const Color _danger = Color(0xFFE5484D);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xxl,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(AppRadius.xlarge),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _danger.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Icon(icon, color: const Color(0xFFFF6B6B), size: 20),
            ),
            const SizedBox(height: AppSpacing.md),
            StandardText(
              text: title,
              fontSize: 16,
              height: 1.3,
              color: Colors.white,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            StandardText(
              text: description,
              fontSize: 13,
              height: 1.5,
              fontFamily: 'PretendardLight',
              color: Colors.white.withValues(alpha: 0.7),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _WideButton(
                    label: '취소',
                    compact: true,
                    onTap: onCancel,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _WideButton(
                    label: confirmLabel,
                    fill: _danger,
                    haptic: HapticLevel.primary,
                    compact: true,
                    onTap: onConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 목록 머리의 완료 버튼.
///
/// 아래 두 버튼은 보고 있는 한 장에 대한 것이라, 전체를 끝내는 것과 같은
/// 줄에 두면 무엇에 대한 버튼인지 헷갈린다.
class _TrayDoneButton extends StatelessWidget {
  final Color accent;
  final int count;
  final VoidCallback onTap;

  const _TrayDoneButton({
    required this.accent,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground =
        ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
            ? Colors.white
            : AppColors.textPrimary;

    return Semantics(
      label: '$count장 담기를 끝내고 나가기',
      child: PressableScale(
        onTap: onTap,
        haptic: HapticLevel.primary,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Center(
            widthFactor: 1,
            // 라벨이 이미 무엇을 끝내는지 말한다. 글자까지 읽히면 뒤에
            // "완료"가 한 번 더 붙는다.
            child: ExcludeSemantics(
              child: StandardText(
                text: '완료',
                fontSize: 15,
                height: 1.2,
                color: foreground,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 목록 아래 띠의 썸네일 한 칸.
class _FilmstripThumb extends StatelessWidget {
  final XFile file;
  final int index;
  final double size;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _FilmstripThumb({
    required this.file,
    required this.index,
    required this.size,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${index + 1}번째 사진',
      selected: selected,
      child: PressableScale(
        onTap: onTap,
        haptic: HapticLevel.selection,
        scale: 0.92,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.small),
            border: Border.all(
              color: selected ? accent : Colors.white.withValues(alpha: 0.25),
              width: selected ? 2.5 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.small - 2),
            child: Opacity(
              opacity: selected ? 1 : 0.55,
              child: _ShotImage(
                file: file,
                fit: BoxFit.cover,
                decodeWidth: size,
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

  /// 다이얼로그 안처럼 좁은 자리에 들어갈 때. 화면 아래 컨트롤과 같은 크기로
  /// 두면 카드 절반을 버튼이 차지한다.
  final bool compact;

  const _WideButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.fill,
    this.haptic = HapticLevel.secondary,
    this.compact = false,
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
    final fontSize = compact ? 14.0 : 15.0;
    final showIcon =
        icon != null && MediaQuery.textScalerOf(context).scale(fontSize) <= 20;

    return PressableScale(
      onTap: onTap,
      haptic: haptic,
      child: Container(
        // 글자가 두 줄이 되면 버튼이 제 크기 그대로 커진다.
        constraints: BoxConstraints(minHeight: compact ? 44 : 54),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.sm : AppSpacing.md,
          vertical: compact ? AppSpacing.xs : AppSpacing.sm,
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
              Icon(icon, size: compact ? 16 : 18, color: foreground),
              const SizedBox(width: AppSpacing.sm),
            ],
            Flexible(
              child: StandardText(
                text: label,
                fontSize: fontSize,
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
    // 위아래를 넉넉히 띄운다. 아래쪽은 하단 컨트롤이 미리보기를 덮고 들어오는
    // 자리라, 여기를 좁게 잡으면 귀퉁이가 문서 모드 배너에 가린다.
    final rect = Rect.fromLTRB(
      size.width * 0.07,
      size.height * 0.18,
      size.width * 0.93,
      size.height * 0.82,
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
