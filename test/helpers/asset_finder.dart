import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 이 위젯이 그리는 에셋의 자리. 에셋이 아니면 null.
///
/// `Image.asset` 에 `cacheWidth` 를 주면 공급자가 [ResizeImage] 로 한 겹
/// 싸여서 `find.image` 로는 못 잡는다. 한 겹 벗겨 본다.
String? assetPathOf(ImageProvider<Object> provider) {
  if (provider is ResizeImage) return assetPathOf(provider.imageProvider);
  if (provider is AssetImage) return provider.assetName;
  return null;
}

/// 그 에셋을 그리는 [Image] 를 찾는다.
Finder findAssetImage(String path) => find.byWidgetPredicate(
      (widget) => widget is Image && assetPathOf(widget.image) == path,
      description: path,
    );
