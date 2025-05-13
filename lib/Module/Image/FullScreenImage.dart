import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
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

  Future<void> _downloadImage(BuildContext context) async {
    if (imagePath == null) {
      SnackBarDialog.showSnackBar(
          context: context,
          message: "이미지를 다운로드할 수 없습니다.",
          backgroundColor: Colors.white);
      return;
    }

    // 권한 요청
    var status = await Permission.storage.request();
    if (status.isGranted) {
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
      body: Center(
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
                        errorWidget: (context, url, error) => SvgPicture.asset(
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
    );
  }
}
