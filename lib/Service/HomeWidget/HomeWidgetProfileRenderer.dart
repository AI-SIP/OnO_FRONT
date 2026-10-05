import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:home_widget/home_widget.dart';

import '../../Constants/ProfileImageDefaults.dart';
import '../../Model/Cosmetic/CosmeticLoadoutModel.dart';
import '../../Module/User/ProfileAvatar.dart';
import '../../Screen/Cosmetic/Widget/CosmeticArt.dart';

/// 위젯 프로필 그림을 찍는 데 드는 재료. 마이페이지 `ProfileEditCard` 가
/// [ProfileAvatar] 에 넘기는 것과 같다.
class HomeWidgetProfileInput {
  /// 사용자가 올린 프로필 사진. 없으면 null.
  final String? photoUrl;

  /// 사진이 없을 때 세울 개구리 층들. `CosmeticProvider.layers` 그대로다.
  final List<CosmeticLayerModel> layers;

  /// 치장 테두리. 안 걸쳤으면 null.
  final String? frameUrl;

  HomeWidgetProfileInput({
    String? photoUrl,
    required this.layers,
    String? frameUrl,
  })  : photoUrl = _normalize(photoUrl),
        frameUrl = _normalize(frameUrl);

  static String? _normalize(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  /// 찍는 방법을 바꾸면 올린다. 입력이 같아도 다시 찍게 된다.
  static const int _renderRevision = 1;

  /// 사진, 층 그림 목록, 테두리를 이어 붙인 문자열.
  String get signature => [
        'r$_renderRevision',
        'photo=${photoUrl ?? ''}',
        'layers=${layers.map((layer) => layer.imageUrl).join(',')}',
        'frame=${frameUrl ?? ''}',
      ].join('|');

  /// [signature] 의 해시. 이전에 찍은 것과 같으면 다시 찍지 않는다.
  ///
  /// 보안용이 아니라 바뀌었는지만 보는 것이라 FNV-1a 32비트로 충분하다.
  String get hash {
    var value = 0x811c9dc5;
    for (final unit in signature.codeUnits) {
      value ^= unit;
      value = (value * 0x01000193) & 0xFFFFFFFF;
    }
    return value.toRadixString(16).padLeft(8, '0');
  }
}

/// 마이페이지 프로필과 똑같은 그림을 PNG 한 장으로 찍어 위젯에 넘긴다.
///
/// 위젯은 SwiftUI 와 Kotlin 이라 [ProfileAvatar] 를 그대로 쓸 수 없다. 치장
/// 겹치는 규칙을 세 군데에 두지 않으려고 앱이 찍어서 넘긴다.
///
/// **화면 밖에서 한 번에 찍기 때문에 그림이 전부 미리 준비돼 있어야 한다.**
/// [HomeWidget.renderFlutterWidget] 은 위젯 트리를 한 번 빌드하고 바로 찍는다.
/// 그 사이에 비동기로 받는 그림은 빈 자리로 찍힌다.
///
/// - 비트맵(사진, 개구리 층 PNG)은 이미지 캐시에 미리 올려 두고, 찍는 동안
///   캐시에서 빠지지 않게 붙잡아 둔다. 그러면 [Image] 가 첫 빌드에서 바로
///   그림을 받는다.
/// - 벡터(프로필 테두리 SVG)는 이미지 캐시를 쓰지 않는다. `vector_graphics` 는
///   **지금 떠 있는 같은 그림**이 있을 때만 첫 빌드에서 바로 그리고, 없으면 다음
///   프레임에 그린다. 그래서 찍기 전에 같은 조건(화면 밖, 왼쪽에서 오른쪽, 언어
///   정보 없음)의 트리에 같은 SVG 를 먼저 띄워 두고, 다 그려지면 그때 찍는다.
///
/// 하나라도 준비에 실패하면 이번에는 찍지 않는다. 위젯은 이전 그림을 그대로
/// 쓴다.
class HomeWidgetProfileRenderer {
  const HomeWidgetProfileRenderer._();

  /// 계약서의 프로필 PNG 키. `renderFlutterWidget` 이 파일 경로를 이 키에 쓴다.
  static const String storageKey = 'ono_widget_profile';

  /// 논리 크기. 위젯에서는 46~50 으로 줄여 붙인다.
  static const double logicalSize = 88;

  /// 대형 위젯에서도 흐려지지 않게 3배로 찍는다.
  static const double pixelRatio = 3;

  /// 테마 색 없는 기본 테두리. 테마 색을 구워 넣으면 테마를 바꿀 때마다 다시
  /// 찍어야 한다.
  static const Color _borderColor = Color(0xFFE0E0E0);

  /// 벡터 그림이 다 그려지기를 기다리는 한도.
  static const Duration _vectorTimeout = Duration(seconds: 5);
  static const Duration _vectorPollInterval = Duration(milliseconds: 50);

  /// 찍어서 저장했으면 true.
  static Future<bool> render(HomeWidgetProfileInput input) async {
    final photoUrl = input.photoUrl;
    final frameUrl = input.frameUrl;

    // 사진을 올렸으면 개구리는 사진이 안 뜰 때의 대신 그림일 뿐이라 필요 없다.
    final artUrls = <String>[
      if (photoUrl == null)
        for (final layer in _layersToDraw(input.layers))
          if (layer.imageUrl.isNotEmpty) layer.imageUrl,
      if (frameUrl != null) frameUrl,
    ];

    final rasters = <ImageProvider<Object>>[
      if (photoUrl != null) CachedNetworkImageProvider(photoUrl),
      for (final url in artUrls)
        if (!CosmeticArt.isVector(url))
          url.startsWith('http')
              ? NetworkImage(url) as ImageProvider<Object>
              : AssetImage(url),
    ];
    final vectors = [
      for (final url in artUrls)
        if (CosmeticArt.isVector(url)) url,
    ];

    final held = <_HeldImage>[];
    _VectorHolder? vectorHolder;
    try {
      for (final provider in rasters) {
        final image = await _HeldImage.load(provider);
        if (image == null) return false;
        held.add(image);
      }

      if (vectors.isNotEmpty) {
        vectorHolder = await _VectorHolder.hold(vectors);
        if (vectorHolder == null) return false;
      }

      await HomeWidget.renderFlutterWidget(
        ProfileAvatar(
          imageUrl: photoUrl,
          size: logicalSize,
          borderColor: _borderColor,
          borderWidth: 1.2,
          backgroundColor: Colors.white,
          frogLayers: input.layers,
          frameUrl: frameUrl,
        ),
        key: storageKey,
        logicalSize: const Size(logicalSize, logicalSize),
        pixelRatio: pixelRatio,
      );
      return true;
    } catch (error) {
      debugPrint('HomeWidgetProfileRenderer render failed: $error');
      return false;
    } finally {
      vectorHolder?.dispose();
      for (final image in held) {
        image.release();
      }
    }
  }

  /// [ProfileAvatar] 가 사진이 없을 때 실제로 그리는 층들.
  ///
  /// 넘긴 층이 비어 있으면 `FrogLayerStack` 이 개구리 본체 한 장으로 메운다.
  static List<CosmeticLayerModel> _layersToDraw(
    List<CosmeticLayerModel> layers,
  ) {
    if (layers.isNotEmpty) return layers;
    return const [
      CosmeticLayerModel(
          imageUrl: ProfileImageDefaults.assetPath, layerOrder: 0),
    ];
  }
}

/// 이미지 캐시에 올려 두고 찍을 때까지 붙잡아 두는 그림 한 장.
///
/// `precacheImage` 는 다음 프레임에 붙잡은 것을 놓는데, 앱이 가만히 있으면
/// 프레임이 안 돌 수도 있고 캐시가 꽉 차면 그 사이에 빠질 수도 있다. 찍고 나서
/// 직접 놓는다.
class _HeldImage {
  final ImageStream _stream;
  final ImageStreamListener _listener;

  _HeldImage._(this._stream, this._listener);

  /// 화면 밖 트리의 [Image] 가 그림을 찾을 때와 같은 설정으로 불러 둔다.
  ///
  /// `renderFlutterWidget` 트리에는 `MediaQuery` 와 `Localizations` 가 없어서
  /// [createLocalImageConfiguration] 이 배율 1.0, 언어 없음으로 찾는다. 에셋
  /// 이미지는 이 설정으로 캐시 키가 정해지므로 똑같이 맞춘다.
  static Future<_HeldImage?> load(ImageProvider<Object> provider) async {
    final completer = Completer<bool>();
    final stream = provider.resolve(
      ImageConfiguration(
        bundle: rootBundle,
        devicePixelRatio: 1.0,
        textDirection: TextDirection.ltr,
        platform: defaultTargetPlatform,
      ),
    );
    final listener = ImageStreamListener(
      (ImageInfo image, bool synchronousCall) {
        image.dispose();
        if (!completer.isCompleted) completer.complete(true);
      },
      onError: (Object error, StackTrace? stackTrace) {
        debugPrint('HomeWidgetProfileRenderer image failed: $error');
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    stream.addListener(listener);

    final loaded = await completer.future
        .timeout(const Duration(seconds: 20), onTimeout: () => false);
    final held = _HeldImage._(stream, listener);
    if (!loaded) {
      held.release();
      return null;
    }
    return held;
  }

  void release() => _stream.removeListener(_listener);
}

/// 벡터 그림을 화면 밖 트리에 먼저 띄워 두는 자리.
///
/// `renderFlutterWidget` 트리와 조건을 똑같이 맞춰야 같은 그림으로 알아본다.
/// [Directionality] 는 왼쪽에서 오른쪽, `Localizations` 와 `DefaultAssetBundle`
/// 은 두지 않는다. 그림은 [CosmeticArt] 로 띄워서 [ProfileAvatar] 가 쓰는 것과
/// 같은 로더를 쓰게 한다.
class _VectorHolder {
  final BuildOwner _buildOwner;
  final RenderObjectToWidgetElement<RenderBox> _root;
  final RenderRepaintBoundary _container;

  _VectorHolder._(this._buildOwner, this._root, this._container);

  static Future<_VectorHolder?> hold(List<String> urls) async {
    final view = ui.PlatformDispatcher.instance.implicitView;
    if (view == null) return null;

    final container = RenderRepaintBoundary();
    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());
    final renderView = RenderView(
      view: view,
      child: RenderPositionedBox(child: container),
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(
          const Size(
            HomeWidgetProfileRenderer.logicalSize,
            HomeWidgetProfileRenderer.logicalSize,
          ),
        ),
        devicePixelRatio: HomeWidgetProfileRenderer.pixelRatio,
      ),
    );
    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final root = RenderObjectToWidgetAdapter<RenderBox>(
      container: container,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            for (final url in urls)
              CosmeticArt(
                  url: url, size: HomeWidgetProfileRenderer.logicalSize),
          ],
        ),
      ),
    ).attachToRenderTree(buildOwner);
    final holder = _VectorHolder._(buildOwner, root, container);

    final deadline =
        DateTime.now().add(HomeWidgetProfileRenderer._vectorTimeout);
    while (DateTime.now().isBefore(deadline)) {
      buildOwner.buildScope(root);
      if (holder._allVectorsDrawn()) return holder;
      await Future<void>.delayed(HomeWidgetProfileRenderer._vectorPollInterval);
    }

    debugPrint('HomeWidgetProfileRenderer vector timed out: $urls');
    holder.dispose();
    return null;
  }

  /// 띄운 SVG 가 전부 그림으로 바뀌었는지.
  ///
  /// 다 그린 벡터 그림은 [FittedBox] 로 그림 크기를 맞춘다. 아직 못 받았거나
  /// 실패하면 [CosmeticArt] 가 넘긴 빈 자리만 있고 [FittedBox] 가 없다.
  bool _allVectorsDrawn() {
    var total = 0;
    var drawn = 0;

    void visit(Element element) {
      if (element.widget is SvgPicture) {
        total++;
        if (_hasDescendant<FittedBox>(element)) drawn++;
        return;
      }
      element.visitChildren(visit);
    }

    _root.visitChildren(visit);
    return total > 0 && total == drawn;
  }

  static bool _hasDescendant<T extends Widget>(Element element) {
    var found = false;
    void visit(Element child) {
      if (found) return;
      if (child.widget is T) {
        found = true;
        return;
      }
      child.visitChildren(visit);
    }

    element.visitChildren(visit);
    return found;
  }

  /// 띄운 트리를 내린다. 찍는 트리가 그림을 받아 간 뒤에 부른다.
  void dispose() {
    try {
      RenderObjectToWidgetAdapter<RenderBox>(container: _container)
          .attachToRenderTree(_buildOwner, _root);
      _buildOwner.buildScope(_root);
      _buildOwner.finalizeTree();
    } catch (error) {
      debugPrint('HomeWidgetProfileRenderer holder dispose failed: $error');
    }
  }
}
