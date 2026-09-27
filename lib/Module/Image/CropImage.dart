import 'package:camera/camera.dart' show XFile;
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

/// 안드로이드 크롭 화면의 비율 칸에 우리가 쓴 이름을 그대로 띄우려고 만든 것.
class _AspectRatioOption implements CropAspectRatioPresetData {
  @override
  final String name;

  @override
  final (int ratioX, int ratioY)? data;

  const _AspectRatioOption(this.name, this.data);
}

/// 오답노트에서 실제로 쓸 만한 비율만 남긴다.
///
/// 예전에는 다섯 개(원본, 정사각, 3:2, 4:3, 16:9)를 늘어놨는데, 안드로이드의
/// uCrop 은 비율 칸을 화면 폭으로 균등 분할하고 그 안의 글자는 줄이지 않는다.
/// 기기 설정에서 글자를 키우면 다섯 칸에서 `원본` 자리의 글자가 칸을 넘쳐
/// 잘리고 선택 점과 겹친다. 세 개로 줄이면 칸이 넓어져서 넘치지 않는다.
///
/// 문제와 풀이 사진에 16:9 나 3:2 를 쓸 일도 거의 없다. 대개는 원본 그대로
/// 두거나 손으로 끌어서 맞춘다.
///
/// 목록을 두 벌 두는 이유가 있다. 안드로이드는 넘긴 이름을 그대로 라벨로 쓰기
/// 때문에(ImageCropperDelegate.java:256) 기본 enum 을 주면 `square`, `4x3` 같은
/// 영어 소문자가 `원본` 옆에 붙는다. iOS 는 반대로 이름으로 자기 프리셋을 찾아
/// 번역된 라벨을 붙이므로(FLTImageCropperPlugin.m:253) 이름을 바꾸면 그 자리를
/// 못 찾는다.
const _androidAspectRatios = [
  // 이건 이름을 그대로 둔다. 안드로이드 쪽이 `original` 을 특별히 알아보고
  // uCrop 의 번역된 문구(한국어면 '원본')를 쓴다. 첫 자리도 지켜야 한다.
  // initAspectRatio 가 번역된 라벨과 안 맞아 defaultIndex 가 0 이 된다.
  CropAspectRatioPreset.original,
  _AspectRatioOption('정사각형', (1, 1)),
  _AspectRatioOption('4:3', (4, 3)),
];

const _iosAspectRatios = [
  CropAspectRatioPreset.original,
  CropAspectRatioPreset.square,
  CropAspectRatioPreset.ratio4x3,
];

/// 이미지 자르기 화면을 띄우고 잘린 파일을 돌려준다.
///
/// 취소하거나 실패하면 null 이다. 부르는 쪽에서 원본을 그대로 쓸지 말지 정한다.
///
/// [accent] 는 사용자가 테마에서 고른 색이다. 안 넘기면 안드로이드 쪽 강조색이
/// uCrop 기본 주황색으로 남아서 앱 어디에도 없는 색이 여기서만 튄다.
///
/// 등록 화면과 촬영 화면이 같이 쓴다. 자르기 화면이 두 군데에서 서로 다르게
/// 생기면 안 되므로 설정을 한 곳에 둔다.
Future<XFile?> cropImageFile(XFile imageFile, {required Color accent}) async {
  try {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      compressFormat: ImageCompressFormat.jpg,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '이미지 자르기',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          // 이걸 안 주면 툴바만 검고 바탕과 상태바는 기본 회색이라 화면이
          // 두 조각으로 보인다.
          statusBarColor: Colors.black,
          backgroundColor: Colors.black,
          activeControlsWidgetColor: accent,
          lockAspectRatio: false,
          cropStyle: CropStyle.rectangle,
          aspectRatioPresets: _androidAspectRatios,
          // 이게 없으면 안드로이드에서 위 목록이 통째로 무시된다.
          // ImageCropperDelegate.java:76 이 `aspectRatioPresets != null &&
          // initAspectRatio != null` 일 때만 setAspectRatioOptions 를 부르고,
          // 그렇지 않으면 uCrop 이 자기 기본 다섯 개(1:1, 3:4, ORIGINAL, 3:2,
          // 16:9)를 쓴다. 글자를 키웠을 때 ORIGINAL 이 잘리던 게 이 목록이다.
          initAspectRatio: CropAspectRatioPreset.original,
        ),
        IOSUiSettings(
          title: '이미지 자르기',
          // iOS 26 부터 TOCropViewController 가 확인과 취소를 아이콘 버튼으로
          // 그려서 이 글자는 화면에 안 나온다. 예전 iOS 를 쓰는 사용자를 위해
          // 남겨 둔다.
          cancelButtonTitle: '취소',
          doneButtonTitle: '완료',
          cropStyle: CropStyle.rectangle,
          aspectRatioPresets: _iosAspectRatios,
        ),
      ],
    );

    if (croppedFile != null) {
      return XFile(croppedFile.path);
    }
    return null;
  } catch (e) {
    debugPrint("Error cropping image: $e");
    return null;
  }
}
