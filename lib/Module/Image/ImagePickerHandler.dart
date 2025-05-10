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

  void showImagePicker(BuildContext context, Function(XFile?) onImagePicked) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                vertical: 20.0, horizontal: 10.0), // 기존 모달과 동일한 여백 적용
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 타이틀 부분
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: 20.0), // 타이틀과 리스트 간 간격 추가
                  child: StandardText(
                    text: '이미지 업로드 방식을 선택해주세요',
                    color: themeProvider.primaryColor,
                    fontSize: 18,
                  ),
                ),
                // 카메라로 촬영 옵션
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: 10.0), // 리스트 항목 간 간격 추가
                  child: ListTile(
                    leading: const Icon(Icons.camera_alt, color: Colors.black),
                    title: const StandardText(
                      text: '카메라로 촬영',
                      color: Colors.black,
                      fontSize: 16,
                    ),
                    onTap: () async {
                      FirebaseAnalytics.instance
                          .logEvent(name: 'image_select_camera');
                      Navigator.of(context).pop(); // 모달 닫기
                      final pickedFile = await pickImageFromCamera(context);
                      onImagePicked(pickedFile);
                    },
                  ),
                ),
                // 갤러리에서 선택 옵션
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: 10.0), // 리스트 항목 간 간격 추가
                  child: ListTile(
                    leading:
                        const Icon(Icons.photo_library, color: Colors.black),
                    title: const StandardText(
                      text: '갤러리에서 선택',
                      color: Colors.black,
                      fontSize: 16,
                    ),
                    onTap: () async {
                      FirebaseAnalytics.instance
                          .logEvent(name: 'image_select_gallery');
                      Navigator.of(context).pop(); // 모달 닫기

                      final pickedFile = await pickImageFromGallery(context);
                      onImagePicked(pickedFile);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
