import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ono/Module/Image/CameraHandler.dart';
import 'package:provider/provider.dart';

import '../Text/mobile_font_size.dart';
import '../Text/StandardText.dart';
import '../Theme/ThemeHandler.dart';
import '../Motion/PressableScale.dart';
import '../Motion/AppMotion.dart';
import '../Design/AppColors.dart';
import '../Design/AppRadius.dart';

/// 안드로이드 크롭 화면의 비율 칸에 우리가 쓴 이름을 그대로 띄우려고 만든 것.
class _AspectRatioOption implements CropAspectRatioPresetData {
  @override
  final String name;

  @override
  final (int ratioX, int ratioY)? data;

  const _AspectRatioOption(this.name, this.data);
}

class ImagePickerHandler {
  final ImagePicker _picker = ImagePicker();
  final CameraHandler _cameraHandler = CameraHandler();

  Future<void> initializeCamera() async {
    await _cameraHandler.init();
  }

  /// [accent] 는 크롭 화면의 강조색이다. 사용자가 테마에서 고른 색을 쓴다.
  ///
  /// 여기서 직접 Provider 를 읽지 않고 받아 오는 이유가 있다. 이 메서드는
  /// [showImagePicker] 의 시트에서 `Navigator.pop` 을 부른 직후에 불린다. 그때
  /// 넘어오는 [context] 는 닫히는 중인 시트의 것이라, 읽는 시점에 따라 이미
  /// 트리에서 빠져 있을 수 있다.
  Future<XFile?> pickImageFromCamera(
    BuildContext context, {
    required Color accent,
  }) async {
    await initializeCamera(); // Ensure the camera is initialized

    final capture = await _cameraHandler.takePicture(context);
    if (capture == null) return null;

    // 문서 모드로 찍은 것은 스캐너가 이미 종이 테두리에 맞춰 잘라 놨다. 크롭
    // 화면을 한 번 더 띄우면 같은 일을 두 번 시키는 셈이다.
    if (capture.alreadyCropped) return capture.file;

    return _cropImage(capture.file, accent: accent);
  }

  Future<XFile?> pickImageFromGallery(
    BuildContext context, {
    required Color accent,
  }) async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        return _cropImage(pickedFile, accent: accent);
      }
      return null;
    } catch (e) {
      debugPrint("Error picking image from gallery: $e");
      return null;
    }
  }

  Future<List<XFile>> pickMultipleImagesFromGallery(
      BuildContext context) async {
    try {
      final pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        // 여러 이미지를 선택한 경우 자르기 없이 그대로 반환
        return pickedFiles;
      }
      return [];
    } catch (e) {
      debugPrint("Error picking multiple images from gallery: $e");
      return [];
    }
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
  /// 목록을 두 벌 두는 이유가 있다. 안드로이드는 넘긴 이름을 그대로 라벨로
  /// 쓰기 때문에(ImageCropperDelegate.java:256) 기본 enum 을 주면 `square`,
  /// `4x3` 같은 영어 소문자가 `원본` 옆에 붙는다. iOS 는 반대로 이름으로 자기
  /// 프리셋을 찾아 번역된 라벨을 붙이므로(FLTImageCropperPlugin.m:253) 이름을
  /// 바꾸면 그 자리를 못 찾는다.
  static const _androidAspectRatios = [
    // 이건 이름을 그대로 둔다. 안드로이드 쪽이 `original` 을 특별히 알아보고
    // uCrop 의 번역된 문구(한국어면 '원본')를 쓴다. 첫 자리도 지켜야 한다.
    // initAspectRatio 가 번역된 라벨과 안 맞아 defaultIndex 가 0 이 된다.
    CropAspectRatioPreset.original,
    _AspectRatioOption('정사각형', (1, 1)),
    _AspectRatioOption('4:3', (4, 3)),
  ];

  static const _iosAspectRatios = [
    CropAspectRatioPreset.original,
    CropAspectRatioPreset.square,
    CropAspectRatioPreset.ratio4x3,
  ];

  Future<XFile?> _cropImage(XFile imageFile, {required Color accent}) async {
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
            // 켜진 비율과 아래 아이콘의 강조색. 기본값이 uCrop 의 주황색이라
            // 앱 어디에도 없는 색이 여기서만 튀었다.
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

  void showImagePicker(BuildContext context, Function(XFile?) onImagePicked,
      {Function(List<XFile>)? onMultipleImagesPicked}) {
    final openTime = DateTime.now();
    // 시트가 닫힌 뒤에는 시트의 context 로 Provider 를 못 읽는다. 아직 살아
    // 있는 이 화면의 context 로 미리 읽어 둔다.
    final accent =
        Provider.of<ThemeHandler>(context, listen: false).primaryColor;
    showModalBottomSheet(
      sheetAnimationStyle: AppMotion.sheetStyle,
      backgroundColor: Colors.transparent,
      context: context,
      isDismissible: false,
      builder: (BuildContext context) {
        final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

        return TapRegion(
          onTapOutside: (_) {
            // Workaround for iPadOS 26.1 bug: https://github.com/flutter/flutter/issues/177992
            if (DateTime.now().difference(openTime) <
                const Duration(milliseconds: 500)) {
              return;
            }
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 24.0, horizontal: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Title with icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: themeProvider.primaryColor.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppRadius.small),
                          ),
                          child: Icon(
                            Icons.add_photo_alternate,
                            color: themeProvider.primaryColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        StandardText(
                          text: '이미지 업로드',
                          fontSize: MobileFontSize.reduced(context, 18),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Menu items
                    _buildActionItem(
                      context: context,
                      icon: Icons.camera_alt,
                      iconColor: themeProvider.primaryColor,
                      title: '카메라로 촬영',
                      onTap: () async {
                        FirebaseAnalytics.instance
                            .logEvent(name: 'image_select_camera');
                        Navigator.of(context).pop();
                        final pickedFile =
                            await pickImageFromCamera(context, accent: accent);
                        onImagePicked(pickedFile);
                      },
                      themeProvider: themeProvider,
                    ),
                    const SizedBox(height: 12),
                    _buildActionItem(
                      context: context,
                      icon: Icons.photo_library,
                      iconColor: themeProvider.primaryColor,
                      title: '갤러리에서 선택',
                      onTap: () async {
                        FirebaseAnalytics.instance.logEvent(
                            name: onMultipleImagesPicked != null
                                ? 'image_select_multiple_gallery'
                                : 'image_select_gallery');
                        Navigator.of(context).pop();

                        if (onMultipleImagesPicked != null) {
                          final pickedFiles =
                              await pickMultipleImagesFromGallery(context);
                          if (pickedFiles.isNotEmpty) {
                            onMultipleImagesPicked(pickedFiles);
                          }
                        } else {
                          final pickedFile = await pickImageFromGallery(context,
                              accent: accent);
                          onImagePicked(pickedFile);
                        }
                      },
                      themeProvider: themeProvider,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    required ThemeHandler themeProvider,
  }) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StandardText(
                text: title,
                fontSize: MobileFontSize.reduced(context, 16),
                color: AppColors.textPrimary,
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
