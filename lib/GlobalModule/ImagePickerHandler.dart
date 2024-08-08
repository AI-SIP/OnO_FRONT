import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ono/GlobalModule/DecorateText.dart';

class ImagePickerHandler {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImageFromCamera() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        return _cropImage(pickedFile);
      }
      return null;
    } catch (e) {
      log("Error picking image from camera: $e");
      return null;
    }
  }

  Future<XFile?> pickImageFromGallery() async {
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
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '이미지 자르기',
            toolbarColor: Colors.green,
            toolbarWidgetColor: Colors.white,
            //initAspectRatio: CropAspectRatioPreset.original,
            //lockAspectRatio: false,
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
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const DecorateText(text: '카메라로 촬영'),
                onTap: () async {
                  Navigator.of(context).pop(); // 팝업 닫기
                  final pickedFile = await pickImageFromCamera();
                  onImagePicked(pickedFile);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const DecorateText(text: '갤러리에서 선택'),
                onTap: () async {
                  Navigator.of(context).pop(); // 팝업 닫기
                  final pickedFile = await pickImageFromGallery();
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
