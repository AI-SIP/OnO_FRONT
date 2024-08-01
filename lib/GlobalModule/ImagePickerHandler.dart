import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerHandler {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImageFromCamera() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      return pickedFile;
    } catch (e) {
      log("Error picking image from camera: $e");
      return null;
    }
  }

  Future<XFile?> pickImageFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      return pickedFile;
    } catch (e) {
      log("Error picking image from gallery: $e");
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
                title: const Text('카메라로 촬영',
                    style: TextStyle(
                        fontFamily: 'font1',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green)),
                onTap: () async {
                  Navigator.of(context).pop(); // 팝업 닫기
                  final pickedFile = await pickImageFromCamera();
                  onImagePicked(pickedFile);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('갤러리에서 선택',
                    style: TextStyle(
                        fontFamily: 'font1',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green)),
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
