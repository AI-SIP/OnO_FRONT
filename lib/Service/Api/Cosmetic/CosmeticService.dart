import 'package:flutter/foundation.dart';
import 'package:ono/Config/AppConfig.dart';
import 'package:ono/Model/Cosmetic/CosmeticEquipResultModel.dart';
import 'package:ono/Model/Cosmetic/CosmeticLoadoutModel.dart';
import 'package:ono/Service/Api/HttpService.dart';

/// 옷장(치장) API 다.
///
/// **실패하면 예외를 밖으로 내보내지 않고 null 을 돌려준다.** `MissionService`
/// 와 같은 방침이다. 치장은 있으면 좋은 것이지 앱 진입을 막을 것이 아니라서,
/// 이 API 가 아직 배포되지 않아 404 가 떨어지는 동안에도 앱은 평소대로 떠야
/// 한다. 화면 열일곱 군데가 개구리를 그리고 있어서 여기서 던지면 하단 탭
/// 아이콘부터 출석 도장까지 같이 무너진다.
///
/// [HttpService] 의 기본 알림(아래에서 올라오는 SnackBar)도 끈다. 조회 실패는
/// 애초에 알릴 일이 아니고, 저장 실패는 `CosmeticProvider` 가 옷장 화면의
/// 문구로 따로 알린다. 켜 두면 같은 실패를 두 번 말하게 된다.
class CosmeticService {
  final HttpService _httpService;

  CosmeticService({HttpService? httpService})
      : _httpService = httpService ?? HttpService();

  final String _baseUrl = '${AppConfig.baseUrl}/api/cosmetics';

  /// 카탈로그와 지금 차림을 가져온다. 실패하면 null 이다.
  ///
  /// 잠긴 아이템도 `owned: false` 로 함께 온다. "레벨 6 에 열려요"를 보여
  /// 주려면 잠긴 것의 조건도 알아야 하기 때문이다.
  ///
  /// 장착 행이 없는 사용자에게는 **서버가 기본 차림을 계산해서** `equipped` 에
  /// 채워 준다. 앱은 받은 것을 그대로 그린다.
  Future<CosmeticLoadoutModel?> getCosmetics() async {
    try {
      final data = await _httpService.sendRequest(
        method: 'GET',
        url: _baseUrl,
        showErrorSnackBar: false,
      );

      return CosmeticLoadoutModel.fromJsonOrNull(data);
    } catch (error) {
      debugPrint('[CosmeticService] 옷장 조회 실패: $error');
      return null;
    }
  }

  /// 한 자리를 갈아 끼운다. [itemKey] 가 null 이면 그 자리를 비운다.
  ///
  /// 답으로 **차림 전체**가 온다. 겹쳐 걸 수 없는 것을 서버가 함께 내릴 수
  /// 있어서, 요청만 보고는 결과를 알 수 없다.
  Future<CosmeticEquipResultModel?> equip({
    required String slot,
    String? itemKey,
  }) {
    return _equipRequest(
      path: '/equip',
      body: {'slot': slot, 'itemKey': itemKey},
      what: '장착',
    );
  }

  /// 세트를 통째로 건다.
  Future<CosmeticEquipResultModel?> equipSet(String setId) {
    return _equipRequest(
      path: '/equip-set',
      body: {'setId': setId},
      what: '세트 장착',
    );
  }

  /// 차림을 통째로 갈아 끼운다. 꾸미기 화면의 **저장** 버튼이 쓴다.
  ///
  /// **전체 교체다.** 요청에 없는 자리는 서버가 비운다. 빈 맵을 보내면 전부
  /// 벗는다. 자리마다 요청을 하나씩 보내면 중간에 하나가 실패했을 때 절반만
  /// 갈아입은 차림이 서버에 남는다.
  Future<CosmeticEquipResultModel?> equipAll(Map<String, String> equipped) {
    return _equipRequest(
      path: '/equip-all',
      body: {'equipped': equipped},
      what: '전체 장착',
    );
  }

  Future<CosmeticEquipResultModel?> _equipRequest({
    required String path,
    required Map<String, dynamic> body,
    required String what,
  }) async {
    try {
      final data = await _httpService.sendRequest(
        method: 'PUT',
        url: '$_baseUrl$path',
        body: body,
        showErrorSnackBar: false,
      );

      final result = CosmeticEquipResultModel.fromJsonOrNull(data);
      if (result == null) {
        // 서버는 2xx 로 답했는데 본문을 읽지 못했다. 무엇이 걸렸는지 알 수
        // 없으니 성공으로 다루지 않는다. 프로바이더가 마지막으로 받은 차림으로
        // 되돌리고, 다음 조회 때 서버 값으로 다시 맞춰진다.
        debugPrint('[CosmeticService] $what 응답을 읽지 못했다: $data');
      }
      return result;
    } catch (error) {
      debugPrint('[CosmeticService] $what 실패: $error');
      return null;
    }
  }
}
