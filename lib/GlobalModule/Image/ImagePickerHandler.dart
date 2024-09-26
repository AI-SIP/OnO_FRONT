import 'dart:developer';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ono/GlobalModule/Image/CameraHandler.dart';
import 'package:ono/GlobalModule/Theme/DecorateText.dart';
import 'package:provider/provider.dart';

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
      FirebaseAnalytics.instance.logEvent(
        name: '이미지 선택',
        parameters: {
          '이미지 선택 방식': '카메라',
        },
      );

      return _cropImage(pickedFile);
    }
    return null;
  }

  Future<XFile?> pickImageFromGallery(BuildContext context) async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {

        FirebaseAnalytics.instance.logEvent(
          name: '이미지 선택',
          parameters: {
            '이미지 선택 방식': '갤러리',
          },
        );

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
        compressFormat: ImageCompressFormat.png,
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
      context: context,
      builder: (BuildContext context) {
        final themeProvider = Provider.of<ThemeHandler>(context);

        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading:
                    Icon(Icons.camera_alt, color: themeProvider.primaryColor),
                title: DecorateText(
                  text: '카메라로 촬영',
                  color: themeProvider.primaryColor,
                  fontSize: 20,
                ),
                onTap: () async {
                  Navigator.of(context).pop(); // Close the popup
                  final pickedFile = await pickImageFromCamera(context);
                  onImagePicked(pickedFile);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library,
                    color: themeProvider.primaryColor),
                title: DecorateText(
                  text: '갤러리에서 선택',
                  color: themeProvider.primaryColor,
                  fontSize: 20,
                ),
                onTap: () async {
                  Navigator.of(context).pop(); // Close the popup
                  final pickedFile = await pickImageFromGallery(context);
                  onImagePicked(pickedFile);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
