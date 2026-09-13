import 'package:camera/camera.dart';

/// 촬영 화면이 들고 나온 사진이다.
///
/// 파일만 돌려주면 부르는 쪽이 이걸 잘라야 하는지 알 수 없다. 문서 모드로 찍은
/// 것은 OS 스캐너가 이미 종이 테두리를 찾아 반듯하게 잘라 놓은 것이라, 크롭
/// 화면을 한 번 더 띄우면 사용자가 같은 일을 두 번 하게 된다.
class CameraCapture {
  final XFile file;

  /// 이미 반듯하게 잘려 나온 것인지. 문서 모드로 찍으면 true 다.
  final bool alreadyCropped;

  const CameraCapture({required this.file, this.alreadyCropped = false});
}
