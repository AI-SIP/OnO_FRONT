import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerHandler {
  final ImagePicker _picker = ImagePicker();

  // 카메라를 통해 이미지를 선택하는 함수
  Future<XFile?> pickImageFromCamera() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      return pickedFile;
    } catch (e) {
      print("Error picking image from camera: $e");
      return null;
    }
  }

  // 갤러리에서 이미지를 선택하는 함수
  Future<XFile?> pickImageFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      return pickedFile;
    } catch (e) {
      print("Error picking image from gallery: $e");
      return null;
    }
  }

  // 이미지 선택 팝업을 표시하는 함수
  void showImagePicker(BuildContext context, Function(XFile?) onImagePicked) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text('카메라로 촬영'),
                onTap: () async {
                  Navigator.of(context).pop(); // 팝업 닫기
                  final pickedFile = await pickImageFromCamera();
                  onImagePicked(pickedFile);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('갤러리에서 선택'),
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
