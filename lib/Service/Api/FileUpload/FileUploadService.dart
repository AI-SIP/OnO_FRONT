import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

import '../../../Config/AppConfig.dart';
import '../HttpService.dart';

class FileUploadService {
  final HttpService httpService = HttpService();
  final baseUrl = "${AppConfig.baseUrl}/api/fileUpload";

  Future<void> uploadImageFile(XFile file) async {
    final files = <http.MultipartFile>[];

    files.add(await http.MultipartFile.fromPath('image', file.path));

    httpService.sendRequest(
        method: 'POST', url: '$baseUrl', isMultipart: true, files: files);
  }

  Future<List<String>> uploadMultipleImageFiles(List<XFile> files) async {
    final multipartFiles = await Future.wait(
        files.map((f) => http.MultipartFile.fromPath('images', f.path)));

    final data = await httpService.sendRequest(
      method: 'POST',
      url: '$baseUrl/images',
      isMultipart: true,
      files: multipartFiles,
    );

    return List<String>.from(data as List);
  }

  Future<void> deleteImage(String imageUrl) async {
    httpService.sendRequest(
      method: 'DELETE',
      url: '$baseUrl/image',
      queryParams: {'imageUrl': imageUrl},
    );
  }
}
