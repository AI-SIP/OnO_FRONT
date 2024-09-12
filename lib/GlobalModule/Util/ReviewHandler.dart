import 'package:in_app_review/in_app_review.dart';

class ReviewHandler {
  final InAppReview _inAppReview = InAppReview.instance;

  Future<void> requestReview() async {
    if (await _inAppReview.isAvailable()) {
      _inAppReview.requestReview(); // 기본 리뷰 다이얼로그 표시
    } else {
      // Play Store 또는 App Store로 리디렉션할 수 있음
      _inAppReview.openStoreListing(appStoreId: '6602886624');
    }
  }
}