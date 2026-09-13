import 'package:camera/camera.dart';

/// 촬영 화면이 들고 나온 사진이다.
///
/// 한 장만 찍는 자리에서도 목록으로 들고 온다. 부르는 쪽이 한 장짜리와 여러
/// 장짜리를 다르게 받아야 하면 결국 양쪽 다 같은 분기를 쓰게 된다.
///
/// 파일만 돌려주지 않는 이유는 [alreadyCropped] 때문이다. 문서 모드로 찍은 것은
/// OS 스캐너가 이미 종이 테두리를 찾아 반듯하게 잘라 놓은 것이라, 크롭 화면을
/// 한 번 더 띄우면 사용자가 같은 일을 두 번 하게 된다.
class CameraCapture {
  final List<XFile> files;

  /// 이미 반듯하게 잘려 나온 것인지. 문서 모드로 찍으면 true 다.
  ///
  /// 여러 장 모드에서는 어차피 크롭 화면을 안 거치므로 보지 않는다.
  final bool alreadyCropped;

  const CameraCapture({required this.files, this.alreadyCropped = false});

  CameraCapture.one(XFile file, {this.alreadyCropped = false}) : files = [file];
}
