import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../Design/AppRadius.dart';
import '../Dialog/SnackBarDialog.dart';
import '../Motion/AppHaptic.dart';
import '../Text/StandardText.dart';
import '../../Util/AppAnalytics.dart';

/// 이미지를 전체 화면으로 크게 보는 화면이다.
///
/// 전에는 이미지 하나만 받아서, 여러 장을 올린 오답노트에서 두 번째 장을 보려면
/// 뒤로 나갔다가 다시 눌러야 했다. 이제 한 문제에 달린 이미지 목록을 통째로
/// 받고 [initialIndex] 에서 시작해, 좌우로 밀어 그 자리에서 앞뒤로 넘긴다.
///
/// 바탕도 순검정에서 위아래로 옅게 기운 짙은 회색으로 바꿨다. 사진이 화면
/// 끝까지 붙어 있고 배경이 새까매서 답답해 보이던 것을, 여백을 주고 모서리를
/// 둥글려 한 장씩 얹힌 것처럼 보이게 했다.
class FullScreenImage extends StatefulWidget {
  /// 넘겨 볼 이미지 주소들. 빈 칸은 부르는 쪽에서 걸러 넘긴다.
  final List<String> imagePaths;

  /// 처음 보여 줄 이미지의 자리.
  final int initialIndex;

  const FullScreenImage({
    super.key,
    required this.imagePaths,
    this.initialIndex = 0,
  });

  /// 넘길 이미지가 한 장뿐인 자리에서 쓴다.
  FullScreenImage.single(String? imagePath, {super.key})
      : imagePaths = (imagePath == null || imagePath.trim().isEmpty)
            ? const <String>[]
            : <String>[imagePath],
        initialIndex = 0;

  @override
  State<FullScreenImage> createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<FullScreenImage> {
  static const String _defaultImagePath = 'assets/Icon/noImage.svg';

  /// 아래로 이만큼 끌어 내리면 닫는다.
  static const double _dismissDistance = 120;

  late final PageController _pageController;
  late final ScrollController _thumbnailController;

  /// 장마다 확대 상태를 따로 들고 있어야 한 장을 키워 둔 채 넘겨도
  /// 다음 장이 잘린 채로 나오지 않는다.
  late final List<TransformationController> _zoomControllers;

  late int _current;

  /// 확대해 둔 동안에는 페이지를 넘기지 않는다. 손가락을 끄는 동작이
  /// 이미지 안에서 움직이는 것인지 다음 장으로 가는 것인지 갈리지 않는다.
  bool _zoomed = false;

  /// 화면을 한 번 누르면 위아래 버튼을 감춘다. 사진만 보고 싶을 때가 있다.
  bool _chromeVisible = true;

  bool _downloading = false;

  /// 아래로 끌어 내린 거리. 배경이 옅어지면서 따라 내려간다.
  double _dragOffset = 0;

  bool get _hasImages => widget.imagePaths.isNotEmpty;

  bool get _isGallery => widget.imagePaths.length > 1;

  // Analytics 용. 넘겨 볼 때마다 남기지 않고 닫을 때 한 번에 남긴다.
  final Set<int> _viewedIndexes = {};
  bool _everZoomed = false;

  @override
  void initState() {
    super.initState();
    _current = _hasImages
        ? widget.initialIndex.clamp(0, widget.imagePaths.length - 1)
        : 0;
    _pageController = PageController(initialPage: _current);
    _viewedIndexes.add(_current);
    AppAnalytics.logScreenView('FullScreenImage');
    _thumbnailController = ScrollController();
    _zoomControllers = List.generate(
      widget.imagePaths.length,
      (_) => TransformationController()..addListener(_handleZoomChanged),
    );
  }

  @override
  void dispose() {
    // 여러 장을 넘겨 보는지, 확대해서 보는지. 이미지 보기를 손볼 때 기준이다.
    AppAnalytics.logEvent('image_viewer_close', {
      'image_count': widget.imagePaths.length,
      'viewed_count': _viewedIndexes.length,
      'zoomed': _everZoomed,
    });
    _pageController.dispose();
    _thumbnailController.dispose();
    for (final controller in _zoomControllers) {
      controller.removeListener(_handleZoomChanged);
      controller.dispose();
    }
    super.dispose();
  }

  void _handleZoomChanged() {
    if (_zoomControllers.isEmpty) return;
    final scale = _zoomControllers[_current].value.getMaxScaleOnAxis();
    final zoomed = scale > 1.01;
    if (zoomed) _everZoomed = true;
    if (zoomed != _zoomed) {
      setState(() => _zoomed = zoomed);
    }
  }

  void _handlePageChanged(int index) {
    AppHaptic.selection();
    // 떠나는 장의 확대를 풀어 둔다. 되돌아왔을 때 키워 둔 채로 있으면
    // 어디를 보고 있었는지 알 수 없다.
    _zoomControllers[_current].value = Matrix4.identity();
    _viewedIndexes.add(index);
    setState(() {
      _current = index;
      _zoomed = false;
    });
    _revealThumbnail(index);
  }

  /// 썸네일 줄에서 지금 보는 장이 화면 밖으로 나가지 않게 따라 옮긴다.
  void _revealThumbnail(int index) {
    if (!_isGallery || !_thumbnailController.hasClients) return;
    final viewport = _thumbnailController.position.viewportDimension;
    final extent = _thumbnailExtent(context);
    final target = (index * extent) - (viewport / 2) + (extent / 2);
    _thumbnailController.animateTo(
      target.clamp(0.0, _thumbnailController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  void _goToPage(int index) {
    if (index == _current) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _toggleChrome() {
    setState(() => _chromeVisible = !_chromeVisible);
  }

  TapDownDetails? _doubleTapDetails;

  void _handleDoubleTap() {
    if (!_hasImages) return;
    final controller = _zoomControllers[_current];
    if (controller.value != Matrix4.identity()) {
      controller.value = Matrix4.identity();
      return;
    }
    final position = _doubleTapDetails?.localPosition;
    if (position == null) return;
    const double scale = 2.5;
    controller.value = Matrix4.identity()
      ..translateByDouble(
          -position.dx * (scale - 1), -position.dy * (scale - 1), 0, 1)
      ..scaleByDouble(scale, scale, scale, 1);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() => _dragOffset += details.delta.dy);
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy;
    if (_dragOffset.abs() > _dismissDistance || velocity.abs() > 800) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _dragOffset = 0);
  }

  /// 갤러리에 저장해도 되는지 확인한다.
  /// Android 10(API 29) 이상은 image_gallery_saver_plus 가 MediaStore 로 저장해서 권한이 필요 없다.
  /// Android 13(API 33) 부터는 storage 권한이 없어져 요청하면 대화상자 없이 항상 거부로 온다.
  /// Android 9 이하만 WRITE_EXTERNAL_STORAGE 가 필요해 기존처럼 요청한다.
  /// iOS 는 permission_handler 가 storage 를 항상 허용으로 돌려주므로 기존 동작 그대로다.
  Future<bool> _canSaveToGallery() async {
    if (Platform.isAndroid) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 29) return true;
      } catch (_) {
        // 버전을 못 읽으면 권한 요청 대신 저장을 시도한다.
        // 기기 대부분이 Android 10 이상이고, 저장이 실패하면 실패 안내가 뜬다.
        return true;
      }
    }

    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<void> _downloadImage() async {
    if (_downloading) return;

    final imagePath = _hasImages ? widget.imagePaths[_current] : null;
    if (imagePath == null) {
      SnackBarDialog.showSnackBar(
          context: context, message: '이미지가 없습니다!', backgroundColor: Colors.red);
      return;
    }

    FirebaseAnalytics.instance.logEvent(name: 'image_download_button_click');
    setState(() => _downloading = true);

    try {
      if (!await _canSaveToGallery()) {
        if (!mounted) return;
        SnackBarDialog.showSnackBar(
            context: context,
            message: '저장 권한이 필요합니다.',
            backgroundColor: Colors.red);
        return;
      }

      final response = await http.get(Uri.parse(imagePath));
      if (response.statusCode != 200) {
        if (!mounted) return;
        SnackBarDialog.showSnackBar(
            context: context,
            message: '다운로드에 실패했습니다.',
            backgroundColor: Colors.red);
        return;
      }

      final result = await ImageGallerySaverPlus.saveImage(
        Uint8List.fromList(response.bodyBytes),
        quality: 80,
        name: 'downloaded_image',
      );
      if (!mounted) return;

      AppAnalytics.logEvent('image_download', {
        'result': result['isSuccess'] == true ? 'success' : 'fail',
      });
      if (result['isSuccess'] == true) {
        AppHaptic.primary();
        SnackBarDialog.showSnackBar(
            context: context,
            message: '이미지가 다운로드 되었습니다.',
            backgroundColor: Colors.green);
      } else {
        SnackBarDialog.showSnackBar(
            context: context,
            message: '다운로드에 실패했습니다.',
            backgroundColor: Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      SnackBarDialog.showSnackBar(
          context: context,
          message: '다운로드에 실패했습니다.',
          backgroundColor: Colors.red);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  // ── 크기 ─────────────────────────────────────────────────

  bool _isTablet(BuildContext context) =>
      MediaQuery.of(context).size.shortestSide >= 600;

  double _thumbnailSize(BuildContext context) => _isTablet(context) ? 72 : 56;

  double _thumbnailGap(BuildContext context) => _isTablet(context) ? 12 : 8;

  double _thumbnailExtent(BuildContext context) =>
      _thumbnailSize(context) + _thumbnailGap(context);

  double _buttonSize(BuildContext context) => _isTablet(context) ? 48 : 42;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final dragProgress = (_dragOffset.abs() / 260).clamp(0.0, 1.0);

    // 위쪽 버튼 줄과 아래쪽 썸네일 줄이 차지하는 높이. 이미지가 그 밑으로
    // 깔리지 않도록 여백으로 빼 둔다.
    final topInset = media.padding.top + _buttonSize(context) + 24;
    final bottomInset =
        media.padding.bottom + (_isGallery ? _thumbnailSize(context) + 36 : 24);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 바탕. 순검정 대신 위가 조금 밝은 짙은 회색으로 기울여 두었다.
          Positioned.fill(
            child: Opacity(
              opacity: 1 - dragProgress * 0.55,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF2C313A), Color(0xFF15171B)],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(0, _dragOffset),
              child: Opacity(
                opacity: 1 - dragProgress * 0.4,
                child: _buildViewer(topInset, bottomInset),
              ),
            ),
          ),
          _buildTopBar(media.padding.top),
          if (_isGallery) _buildThumbnailStrip(media.padding.bottom),
        ],
      ),
    );
  }

  Widget _buildViewer(double topInset, double bottomInset) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleChrome,
      onDoubleTapDown: (details) => _doubleTapDetails = details,
      onDoubleTap: _handleDoubleTap,
      // 확대한 동안에는 끌어서 닫지 않는다. 그때의 손짓은 이미지 안에서
      // 움직이려는 것이기 때문이다.
      onVerticalDragUpdate: _zoomed ? null : _handleDragUpdate,
      onVerticalDragEnd: _zoomed ? null : _handleDragEnd,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        // 버튼을 감추면 그만큼 이미지가 커진다.
        padding: _chromeVisible
            ? EdgeInsets.only(
                top: topInset, bottom: bottomInset, left: 16, right: 16)
            : const EdgeInsets.all(12),
        child: _hasImages ? _buildPageView() : _buildEmpty(),
      ),
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.imagePaths.length,
      onPageChanged: _handlePageChanged,
      physics: _zoomed
          ? const NeverScrollableScrollPhysics()
          : const PageScrollPhysics(),
      itemBuilder: (context, index) {
        return InteractiveViewer(
          transformationController: _zoomControllers[index],
          // 확대하기 전에는 끌어 옮기지 못하게 해서, 아래로 끌어 닫는
          // 손짓과 부딪히지 않게 한다.
          panEnabled: _zoomed,
          minScale: 1.0,
          maxScale: 4.0,
          child: Center(child: _buildImage(widget.imagePaths[index])),
        );
      },
    );
  }

  Widget _buildImage(String imagePath) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.contain,
        placeholder: (context, url) => const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
          ),
        ),
        errorWidget: (context, url, error) => _buildEmpty(),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(_defaultImagePath, width: 140, height: 140),
          const SizedBox(height: 16),
          StandardText(
            text: '이미지를 불러오지 못했습니다',
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.6),
            height: 1.2,
          ),
        ],
      ),
    );
  }

  // ── 위아래 껍데기 ────────────────────────────────────────

  Widget _buildTopBar(double topPadding) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: _chrome(
        child: Container(
          padding: EdgeInsets.only(
              top: topPadding + 8, left: 12, right: 12, bottom: 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x59000000), Color(0x00000000)],
            ),
          ),
          child: Row(
            children: [
              _glassButton(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
              const Spacer(),
              if (_isGallery) _buildCounter(),
              const Spacer(),
              _glassButton(
                onTap: _downloading ? null : _downloadImage,
                child: _downloading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.file_download_outlined,
                        color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: StandardText(
        text: '${_current + 1} / ${widget.imagePaths.length}',
        fontSize: 13,
        color: Colors.white,
        height: 1.2,
      ),
    );
  }

  Widget _buildThumbnailStrip(double bottomPadding) {
    final size = _thumbnailSize(context);
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: _chrome(
        child: Container(
          padding: EdgeInsets.only(top: 28, bottom: bottomPadding + 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0x73000000), Color(0x00000000)],
            ),
          ),
          child: SizedBox(
            height: size,
            child: ListView.separated(
              controller: _thumbnailController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.imagePaths.length,
              separatorBuilder: (_, __) =>
                  SizedBox(width: _thumbnailGap(context)),
              itemBuilder: (context, index) {
                final selected = index == _current;
                return GestureDetector(
                  onTap: () => _goToPage(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: size,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.small),
                      border: Border.all(
                        color: selected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.24),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.small - 2),
                      child: Opacity(
                        opacity: selected ? 1 : 0.5,
                        child: CachedNetworkImage(
                          imageUrl: widget.imagePaths[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => ColoredBox(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                          errorWidget: (context, url, error) => ColoredBox(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// 위아래 버튼 줄을 같은 방식으로 감췄다 보였다 한다.
  Widget _chrome({required Widget child}) {
    return IgnorePointer(
      ignoring: !_chromeVisible,
      child: AnimatedOpacity(
        opacity: _chromeVisible ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: child,
      ),
    );
  }

  Widget _glassButton({required Widget child, required VoidCallback? onTap}) {
    final size = _buttonSize(context);
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(width: size, height: size, child: Center(child: child)),
      ),
    );
  }
}
