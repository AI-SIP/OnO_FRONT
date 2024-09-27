import 'dart:typed_data';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

import '../Theme/HandWriteText.dart';

class FullScreenImage extends StatelessWidget {
  final String? imagePath;

  const FullScreenImage({super.key, required this.imagePath});

  Future<void> _downloadImage(BuildContext context) async {
    if (imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: HandWriteText(
                text: "이미지를 다운로드할 수 없습니다.", fontSize: 20, color: Colors.white)),
      );
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: HandWriteText(
                text: "이미지가 다운로드되었습니다.",
                fontSize: 20,
                color: Colors.white,
              )),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: HandWriteText(
                      text: "다운로드에 실패했습니다.",
                      fontSize: 20,
                      color: Colors.white)),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: HandWriteText(
                  text: "에러 발생: $e", fontSize: 20, color: Colors.white)),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: HandWriteText(
                text: "저장 권한이 필요합니다.", fontSize: 20, color: Colors.white)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
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
              _downloadImage(context);
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
              child: Container(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: imagePath == null
                        ? const AssetImage('assets/no_image.png')
                            as ImageProvider<Object>
                        : CachedNetworkImageProvider(imagePath!)
                            as ImageProvider<Object>,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
