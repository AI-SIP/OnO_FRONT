import 'package:flutter/foundation.dart';
import 'package:ono/Config/AppConfig.dart';
import 'package:ono/Model/Achievement/AchievementBoardModel.dart';
import 'package:ono/Service/Api/HttpService.dart';

/// 훈장 API 다.
///
/// **실패하면 예외를 밖으로 내보내지 않고 null 을 돌려준다.**
/// [CosmeticService](../Cosmetic/CosmeticService.dart) 와 같은 방침이다. 훈장은
/// 가끔 보고 흐뭇한 것이지 앱 진입을 막을 것이 아니라서, 이 API 가 아직
/// 배포되지 않아 404 가 떨어지는 동안에도 앱은 평소대로 떠야 한다. 옷장 탭의
/// 버튼이 이 조회를 보고 있어서 여기서 던지면 탭 하나가 통째로 안 뜬다.
///
/// [HttpService] 의 기본 알림(위에서 내려오는 알림)도 끈다. 훈장을 못 불러온
/// 것은 사용자가 지금 하려던 일과 상관이 없어서, 다른 화면을 보고 있는데 알림이
/// 내려오면 무엇이 실패했는지도 모른 채 놀라기만 한다. 훈장 화면 안에서는
/// 화면 자체가 못 불러왔다고 말한다.
class AchievementService {
  final HttpService _httpService;

  AchievementService({HttpService? httpService})
      : _httpService = httpService ?? HttpService();

  final String _baseUrl = '${AppConfig.baseUrl}/api/achievements';

  /// 훈장 열두 개와 이번에 새로 받은 것을 가져온다. 실패하면 null 이다.
  ///
  /// 못 받은 것도 함께 온다. "오답노트 100개"만 보여 주면 이미 87개를 적은
  /// 사람이 자기가 코앞이라는 것을 모른다.
  Future<AchievementBoardModel?> getAchievements() async {
    try {
      final data = await _httpService.sendRequest(
        method: 'GET',
        url: _baseUrl,
        showErrorSnackBar: false,
      );

      return AchievementBoardModel.fromJsonOrNull(data);
    } catch (error) {
      debugPrint('[AchievementService] 훈장 조회 실패: $error');
      return null;
    }
  }
}
