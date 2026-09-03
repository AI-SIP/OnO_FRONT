import 'dart:async' as async;
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

import '../../../Config/AppConfig.dart';
import '../../../Constants/ErrorMessages.dart';
import '../../../Exception/ApiException.dart';
import '../HttpService.dart';

class FileUploadService {
  final HttpService httpService;

  FileUploadService({HttpService? httpService})
      : httpService = httpService ?? HttpService();
  final baseUrl = "${AppConfig.baseUrl}/api/fileUpload";

  Future<String> uploadImageFile(XFile file) async {
    final uploadedUrls = await uploadMultipleImageFiles([file]);
    if (uploadedUrls.isEmpty) {
      throw ApiException(message: ErrorMessages.fileUploadFailed);
    }
    return uploadedUrls.first;
  }

  Future<List<String>> uploadMultipleImageFiles(List<XFile>? files) async {
    if (files == null || files.isEmpty) {
      return [];
    }

    final uploadedUrls = List<String?>.filled(files.length, null);
    final indexedFiles = files.asMap().entries.toList();
    final filesByContentType = <String, List<MapEntry<int, XFile>>>{};

    for (final entry in indexedFiles) {
      final contentType = _contentTypeForPath(entry.value.path);
      filesByContentType.putIfAbsent(contentType, () => []).add(entry);
    }

    for (final group in filesByContentType.entries) {
      final presignedUrls = await _getPresignedUrls(
        count: group.value.length,
        contentType: group.key,
      );

      if (presignedUrls.length != group.value.length) {
        throw ApiException(message: ErrorMessages.fileUploadFailed);
      }

      await Future.wait(
        group.value.asMap().entries.map((entry) async {
          final file = entry.value.value;
          final presignedUrl = presignedUrls[entry.key];
          await _uploadToS3(
            file: file,
            presignedUrl: presignedUrl.presignedUrl,
            contentType: group.key,
          );
          uploadedUrls[entry.value.key] = presignedUrl.fileUrl;
        }),
      );
    }

    if (uploadedUrls.any((url) => url == null)) {
      throw ApiException(message: ErrorMessages.fileUploadFailed);
    }

    return uploadedUrls.map((url) => url!).toList();
  }

  Future<void> deleteImage(String imageUrl) async {
    await httpService.sendRequest(
      method: 'DELETE',
      url: '$baseUrl/image',
      queryParams: {'imageUrl': imageUrl},
    );
  }

  Future<List<_PresignedUrlResponse>> _getPresignedUrls({
    required int count,
    required String contentType,
  }) async {
    final data = await httpService.sendRequest(
      method: 'GET',
      url: '$baseUrl/presigned-urls',
      queryParams: {
        'count': count.toString(),
        'contentType': contentType,
      },
    ) as List<dynamic>;

    return data
        .map((item) =>
            _PresignedUrlResponse.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _uploadToS3({
    required XFile file,
    required String presignedUrl,
    required String contentType,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse(presignedUrl),
            headers: {'Content-Type': contentType},
            body: await file.readAsBytes(),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          statusCode: response.statusCode,
          message: ErrorMessages.fileUploadFailed,
        );
      }
    } on SocketException {
      throw NetworkException();
    } on async.TimeoutException {
      throw TimeoutException();
    }
  }

  String _contentTypeForPath(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      default:
        return 'application/octet-stream';
    }
  }
}

class _PresignedUrlResponse {
  final String presignedUrl;
  final String fileUrl;

  _PresignedUrlResponse({
    required this.presignedUrl,
    required this.fileUrl,
  });

  factory _PresignedUrlResponse.fromJson(Map<String, dynamic> json) {
    final presignedUrl = json['presignedUrl'];
    final fileUrl = json['fileUrl'];
    if (presignedUrl is! String || fileUrl is! String) {
      throw ApiException(message: ErrorMessages.fileUploadFailed);
    }

    return _PresignedUrlResponse(
      presignedUrl: presignedUrl,
      fileUrl: fileUrl,
    );
  }
}
