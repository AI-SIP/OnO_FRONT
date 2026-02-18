import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ono/Module/Image/CameraHandler.dart';
import 'package:provider/provider.dart';

import '../Text/StandardText.dart';
import '../Theme/ThemeHandler.dart';

class ImagePickerHandler {
  final ImagePicker _picker = ImagePicker();
  final CameraHandler _cameraHandler = CameraHandler();

  Future<void> initializeCamera() async {
    await _cameraHandler.init();
  }

  Future<XFile?> pickImageFromCamera(BuildContext context) async {
    await initializeCamera(); // Ensure the camera is initialized

    final pickedFile = await _cameraHandler.takePicture(context);

    if (pickedFile != null) {
      return _cropImage(pickedFile);
    }
    return null;
  }

  Future<XFile?> pickImageFromGallery(BuildContext context) async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        return _cropImage(pickedFile);
      }
      return null;
    } catch (e) {
      log("Error picking image from gallery: $e");
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
      log("Error picking multiple images from gallery: $e");
      return [];
    }
  }

  Future<XFile?> _cropImage(XFile imageFile) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '이미지 자르기',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
            cropStyle: CropStyle.rectangle,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: '이미지 자르기',
            cancelButtonTitle: '취소',
            doneButtonTitle: '완료',
            cropStyle: CropStyle.rectangle,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
        ],
      );

      if (croppedFile != null) {
        return XFile(croppedFile.path);
      }
      return null;
    } catch (e) {
      log("Error cropping image: $e");
      return null;
    }
  }

  void showImagePicker(BuildContext context, Function(XFile?) onImagePicked,
      {Function(List<XFile>)? onMultipleImagesPicked}) {
    final openTime = DateTime.now();
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      isDismissible: false,
      builder: (BuildContext context) {
        final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

        return TapRegion(
          onTapOutside: (_) {
            // Workaround for iPadOS 26.1 bug: https://github.com/flutter/flutter/issues/177992
            if (DateTime.now().difference(openTime) < const Duration(milliseconds: 500)) {
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
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.add_photo_alternate,
                            color: themeProvider.primaryColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const StandardText(
                          text: '이미지 업로드',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Menu items
                    _buildActionItem(
                      icon: Icons.camera_alt,
                      iconColor: themeProvider.primaryColor,
                      title: '카메라로 촬영',
                      onTap: () async {
                        FirebaseAnalytics.instance
                            .logEvent(name: 'image_select_camera');
                        Navigator.of(context).pop();
                        final pickedFile = await pickImageFromCamera(context);
                        onImagePicked(pickedFile);
                      },
                      themeProvider: themeProvider,
                    ),
                    const SizedBox(height: 12),
                    _buildActionItem(
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
                          final pickedFile = await pickImageFromGallery(context);
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
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    required ThemeHandler themeProvider,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
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
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
