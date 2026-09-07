import 'package:flutter/foundation.dart';
import 'package:ono/Config/AppConfig.dart';
import 'package:ono/Model/Notice/NoticeModel.dart';
import 'package:ono/Service/Api/HttpService.dart';

class NoticeService {
  final HttpService _httpService;

  NoticeService({HttpService? httpService})
      : _httpService = httpService ?? HttpService();

  final String _baseUrl = '${AppConfig.baseUrl}/api/notices';

  /// 지금 띄울 공지를 가져온다. 없으면 null 이다.
  ///
  /// 서버는 공지가 없을 때 `data` 키 자체를 빼고 `{}` 를 내려준다.
  /// [HttpService] 는 `data` 가 없으면 본문을 그대로 돌려주므로 여기서는
  /// 빈 맵이 온다. 그래서 `noticeId` 가 있는지로 공지 유무를 가른다.
  ///
  /// 공지는 있으면 좋은 것이지 앱 진입을 막을 것이 아니다. 실패하면 오류를
  /// 알리지 않고 조용히 null 을 돌려준다. 백엔드에 아직 이 API 가 배포되지
  /// 않아 404 가 떨어지는 동안에도 앱은 평소대로 떠야 한다.
  Future<NoticeModel?> getActiveNotice() async {
    try {
      final data = await _httpService.sendRequest(
        method: 'GET',
        url: '$_baseUrl/active',
        showErrorSnackBar: false,
      );

      if (data is! Map<String, dynamic> || data['noticeId'] == null) {
        return null;
      }
      return NoticeModel.fromJson(data);
    } catch (error) {
      debugPrint('[NoticeService] 활성 공지 조회 실패: $error');
      return null;
    }
  }

  /// 이 공지를 이 사용자에게 24시간 동안 숨긴다.
  ///
  /// 실패해도 팝업은 닫아야 하므로 성공 여부만 돌려주고 예외는 삼킨다.
  /// 숨기기가 실패하면 다음 진입 때 다시 뜨는데, 그게 오류 알림을 띄우는
  /// 것보다 낫다.
  Future<bool> dismissNotice(int noticeId) async {
    try {
      await _httpService.sendRequest(
        method: 'POST',
        url: '$_baseUrl/$noticeId/dismiss',
        showErrorSnackBar: false,
      );
      return true;
    } catch (error) {
      debugPrint('[NoticeService] 공지 숨기기 실패: $error');
      return false;
    }
  }
}
