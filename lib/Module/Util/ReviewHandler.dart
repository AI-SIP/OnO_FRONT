import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Text/HandWriteText.dart';
import '../Theme/ThemeHandler.dart';

class ReviewHandler {
  final InAppReview _inAppReview = InAppReview.instance;

  Future<void> requestReview(BuildContext context) async {
    if (await _inAppReview.isAvailable()) {
      _inAppReview.requestReview(); // 기본 리뷰 다이얼로그 표시
    } else {
      // 리뷰 다이얼로그가 불가능할 경우 커스텀 다이얼로그 표시
      _showCustomReviewDialog(context);
    }
  }

  Future<void> openReviewPage() async {
    _inAppReview.openStoreListing(appStoreId: '6602886624');
  }

  // 커스텀 리뷰 다이얼로그
  void _showCustomReviewDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: HandWriteText(
            text: '리뷰 작성 요청',
            fontSize: 24,
            color: themeProvider.primaryColor,
          ),
          content: HandWriteText(
            text: '작성하신 리뷰는 저희에게 큰 도움이 됩니다. 리뷰를 작성하시겠습니까?',
            fontSize: 20,
            color: themeProvider.primaryColor,
          ),
          actions: [
            TextButton(
              child: const HandWriteText(
                text: '취소',
                fontSize: 20,
                color: Colors.black,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // 다이얼로그 닫기
              },
            ),
            TextButton(
              child: const HandWriteText(
                text: '작성하기',
                fontSize: 20,
                color: Colors.blue,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // 다이얼로그 닫기
                _launchURL(
                    'https://forms.gle/MncQvyT57LQr43Pp7'); // Google Forms 링크 열기
              },
            ),
          ],
        );
      },
    );
  }

  // URL 열기 함수
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }
}
