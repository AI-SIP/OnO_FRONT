import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ono/Module/Image/CameraHandler.dart';
import 'package:ono/Module/Image/CropImage.dart';
import 'package:provider/provider.dart';

import '../Text/mobile_font_size.dart';
import '../Text/StandardText.dart';
import '../Theme/ThemeHandler.dart';
import '../Motion/PressableScale.dart';
import '../Motion/AppMotion.dart';
import '../Design/AppColors.dart';
import '../Design/AppRadius.dart';
import 'package:ono/Util/AppAnalytics.dart';

/// 이미지를 어디서 가져올지.
enum ImageSourceChoice { camera, gallery }

class ImagePickerHandler {
  /// 카메라를 한 번 열어서 담을 수 있는 최대 장수.
  ///
  /// 등록 화면 자체에는 장수 제한이 없지만, 한 번에 무한정 찍게 두면 담은
  /// 것을 되짚기도 어렵고 메모리도 그만큼 물고 있게 된다. 더 필요하면 카메라를
  /// 다시 열면 된다.
  static const int maxShotsPerSession = 20;

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
    if (capture == null || capture.files.isEmpty) return null;

    // 문서 모드로 찍은 것은 스캐너가 이미 종이 테두리에 맞춰 잘라 놨다. 크롭
    // 화면을 한 번 더 띄우면 같은 일을 두 번 시키는 셈이다.
    if (capture.alreadyCropped) return capture.files.first;

    return cropImageFile(capture.files.first, accent: accent);
  }

  /// 카메라로 여러 장을 이어서 찍는다.
  ///
  /// 자르기를 태우지 않는다. 앨범에서 여러 장 고르는 쪽도 그렇게 하고 있고,
  /// 열 장을 찍고 나서 자르기 화면을 열 번 지나가게 하는 것은 등록을 포기하게
  /// 만드는 길이다. 한 장씩 손보고 싶으면 등록 화면에서 하나씩 고르면 된다.
  Future<List<XFile>> pickImagesFromCamera(
    BuildContext context, {
    int maxShots = maxShotsPerSession,
  }) async {
    await initializeCamera();

    final capture = await _cameraHandler.takePicture(
      context,
      multiple: true,
      maxShots: maxShots,
    );
    return capture?.files ?? [];
  }

  Future<XFile?> pickImageFromGallery(
    BuildContext context, {
    required Color accent,
  }) async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        return cropImageFile(pickedFile, accent: accent);
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

  /// 어디서 가져올지만 고르게 하고 그 선택을 돌려준다.
  ///
  /// 예전에는 이 시트가 고르는 것과 실제로 가져오는 것을 같이 했다. 그래서
  /// `Navigator.pop` 을 부른 직후의 시트 context 로 카메라를 띄우고 Provider 를
  /// 읽어야 했는데, 그 context 는 닫히는 중이라 언제 트리에서 빠질지 모른다.
  /// 고르는 일까지만 하고 나오면 부르는 쪽의 멀쩡한 context 로 이어서 할 수
  /// 있다.
  Future<ImageSourceChoice?> _showSourceSheet(
    BuildContext context, {
    required bool multiple,
  }) {
    final openTime = DateTime.now();

    return showModalBottomSheet<ImageSourceChoice>(
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
                      onTap: () =>
                          Navigator.of(context).pop(ImageSourceChoice.camera),
                      themeProvider: themeProvider,
                    ),
                    const SizedBox(height: 12),
                    _buildActionItem(
                      context: context,
                      icon: Icons.photo_library,
                      iconColor: themeProvider.primaryColor,
                      title: multiple ? '갤러리에서 여러 장 선택' : '갤러리에서 선택',
                      onTap: () =>
                          Navigator.of(context).pop(ImageSourceChoice.gallery),
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

  /// 카메라와 갤러리 중 고르게 하고, 고른 것들을 돌려준다.
  ///
  /// 여러 장을 한 번에 받는 자리에서 쓴다. 콜백이 아니라 결과를 돌려주므로
  /// 부르는 쪽이 `await` 로 이어서 쓸 수 있다.
  ///
  /// 시트를 그냥 닫으면 빈 목록이 나온다.
  Future<List<XFile>> pickMultipleImages(
    BuildContext context, {
    int maxShots = maxShotsPerSession,
  }) async {
    final choice = await _showSourceSheet(context, multiple: true);
    if (choice == null || !context.mounted) return [];

    if (choice == ImageSourceChoice.camera) {
      FirebaseAnalytics.instance.logEvent(name: 'image_select_camera');
      return _logPicked(
        'camera',
        await pickImagesFromCamera(context, maxShots: maxShots),
      );
    }

    FirebaseAnalytics.instance.logEvent(name: 'image_select_multiple_gallery');
    return _logPicked('gallery', await pickMultipleImagesFromGallery(context));
  }

  /// 실제로 받은 장수를 남긴다. image_select_* 는 어디서 가져올지 고른
  /// 순간이라, 카메라나 앨범을 열었다가 그냥 닫은 것도 센다.
  static List<XFile> _logPicked(String source, List<XFile> files) {
    AppAnalytics.logEvent('image_picked', {
      'source': source,
      'count': files.length,
    });
    return files;
  }

  Future<void> showImagePicker(
      BuildContext context, Function(XFile?) onImagePicked,
      {Function(List<XFile>)? onMultipleImagesPicked}) async {
    final multiple = onMultipleImagesPicked != null;
    final accent =
        Provider.of<ThemeHandler>(context, listen: false).primaryColor;

    final choice = await _showSourceSheet(context, multiple: multiple);
    if (choice == null || !context.mounted) return;

    if (choice == ImageSourceChoice.camera) {
      FirebaseAnalytics.instance.logEvent(name: 'image_select_camera');

      // 여러 장을 받는 화면이어도 여기서는 한 장만 찍는다. 이 시트를 쓰는
      // 등록 화면들은 사진이 하나 들어올 때마다 곧바로 업로드하고 태그 추천을
      // 부른다(ProblemRegisterTemplate.dart:424-461). 카메라가 스무 장을
      // 쏟아 내면 presigned-url 스무 번, S3 PUT 스무 번, 태그 추천 스무 번이
      // 한꺼번에 나가고, 태그 추천은 응답 순서가 보장되지 않아 마지막에
      // 도착한 것이 이긴다. 카메라로 여러 장을 이어 찍는 길은 그것을 감당하게
      // 만든 여러 장 작성 화면(pickMultipleImages)에만 낸다.
      final file = await pickImageFromCamera(context, accent: accent);
      _logPicked('camera', [if (file != null) file]);
      onImagePicked(file);
      return;
    }

    FirebaseAnalytics.instance.logEvent(
      name: multiple ? 'image_select_multiple_gallery' : 'image_select_gallery',
    );

    if (multiple) {
      final pickedFiles =
          _logPicked('gallery', await pickMultipleImagesFromGallery(context));
      if (pickedFiles.isNotEmpty) onMultipleImagesPicked(pickedFiles);
      return;
    }

    final file = await pickImageFromGallery(context, accent: accent);
    _logPicked('gallery', [if (file != null) file]);
    onImagePicked(file);
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
