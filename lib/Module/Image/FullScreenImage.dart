import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../Dialog/SnackBarDialog.dart';

class FullScreenImage extends StatelessWidget {
  final String? imagePath;
  final String defaultImagePath = 'assets/Icon/noImage.svg';

  const FullScreenImage({super.key, required this.imagePath});

  /// 갤러리에 저장해도 되는지 확인한다.
  /// Android 10(API 29) 이상은 image_gallery_saver_plus 가 MediaStore 로 저장해서 권한이 필요 없다.
  /// Android 13(API 33) 부터는 storage 권한이 없어져 요청하면 대화상자 없이 항상 거부로 온다.
  /// Android 9 이하만 WRITE_EXTERNAL_STORAGE 가 필요해 기존처럼 요청한다.
  /// iOS 는 permission_handler 가 storage 를 항상 허용으로 돌려주므로 기존 동작 그대로다.
  Future<bool> _canSaveToGallery() async {
    if (Platform.isAndroid) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 29) return true;
      } catch (_) {
        // 버전을 못 읽으면 권한 요청 대신 저장을 시도한다.
        // 기기 대부분이 Android 10 이상이고, 저장이 실패하면 실패 안내가 뜬다.
        return true;
      }
    }

    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<void> _downloadImage(BuildContext context) async {
    if (imagePath == null) {
      SnackBarDialog.showSnackBar(
          context: context,
          message: "이미지를 다운로드할 수 없습니다.",
          backgroundColor: Colors.white);
      return;
    }

    if (await _canSaveToGallery()) {
      try {
        // 이미지 다운로드
        var response = await http.get(Uri.parse(imagePath!));
        if (response.statusCode == 200) {
          // 갤러리에 이미지 저장
          final result = await ImageGallerySaverPlus.saveImage(
            Uint8List.fromList(response.bodyBytes),
            quality: 80,
            name: "downloaded_image",
          );
          if (result["isSuccess"]) {
            SnackBarDialog.showSnackBar(
                context: context,
                message: "이미지가 다운로드 되었습니다.",
                backgroundColor: Colors.green);
          } else {
            SnackBarDialog.showSnackBar(
                context: context,
                message: "다운로드에 실패했습니다.",
                backgroundColor: Colors.red);
          }
        }
      } catch (e) {
        SnackBarDialog.showSnackBar(
            context: context,
            message: "다운로드에 실패했습니다.",
            backgroundColor: Colors.red);
      }
    } else {
      SnackBarDialog.showSnackBar(
          context: context,
          message: "저장 권한이 필요합니다.",
          backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () {
              FirebaseAnalytics.instance.logEvent(
                name: 'image_download_button_click',
              );
              if (imagePath != null) {
                _downloadImage(context);
              } else {
                SnackBarDialog.showSnackBar(
                    context: context,
                    message: '이미지가 없습니다!',
                    backgroundColor: Colors.red);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return InteractiveViewer(
                  panEnabled: true,
                  minScale: 1.0,
                  maxScale: 3.0,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: imagePath == null || imagePath!.isEmpty
                        ? SvgPicture.asset(
                            defaultImagePath,
                            fit: BoxFit.contain,
                          )
                        : CachedNetworkImage(
                            imageUrl: imagePath!,
                            placeholder: (context, url) =>
                                const CircularProgressIndicator(),
                            errorWidget: (context, url, error) =>
                                SvgPicture.asset(
                              defaultImagePath,
                              fit: BoxFit.contain,
                            ),
                            fit: BoxFit.contain,
                          ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
