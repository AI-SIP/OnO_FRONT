import 'package:flutter/foundation.dart';
import 'package:ono/Config/AppConfig.dart';
import 'package:ono/Constants/ErrorMessages.dart';
import 'package:ono/Exception/ApiException.dart';
import 'package:ono/Model/Mission/MissionClaimResultModel.dart';
import 'package:ono/Model/Mission/MissionGroupModel.dart';
import 'package:ono/Service/Api/HttpService.dart';

class MissionService {
  final HttpService _httpService;

  MissionService({HttpService? httpService})
      : _httpService = httpService ?? HttpService();

  final String _baseUrl = '${AppConfig.baseUrl}/api/missions';

  /// 오늘의 일일 미션과 이번 주 주간 미션을 가져온다. 실패하면 null 이다.
  ///
  /// 미션은 있으면 좋은 것이지 앱 진입을 막을 것이 아니다. 백엔드에 아직 이
  /// API 가 배포되지 않아 404 가 떨어지는 동안에도 앱은 평소대로 떠야 한다.
  /// [NoticeService] 가 같은 이유로 같은 선택을 했다.
  Future<MissionBoardModel?> getMissions() async {
    try {
      final data = await _httpService.sendRequest(
        method: 'GET',
        url: _baseUrl,
        showErrorSnackBar: false,
      );

      if (data is! Map<String, dynamic>) return null;
      return MissionBoardModel.fromJson(data);
    } catch (error) {
      debugPrint('[MissionService] 미션 조회 실패: $error');
      return null;
    }
  }

  /// 완료한 미션의 보상을 받는다. 실패하면 null 이다.
  ///
  /// 받기는 사용자가 버튼을 눌러 일으킨 일이라 왜 실패했는지 알려 줘야 한다.
  /// 다만 [HttpService] 의 기본 알림은 아래에서 올라오는 SnackBar 라서, 문구만
  /// [onFailure] 로 넘기고 띄우는 것은 화면이 하도록 둔다.
  Future<MissionClaimResultModel?> claim(
    int progressId, {
    void Function(String message)? onFailure,
  }) async {
    try {
      final data = await _httpService.sendRequest(
        method: 'POST',
        url: '$_baseUrl/$progressId/claim',
        showErrorSnackBar: false,
      );

      final result = MissionClaimResultModel.fromJsonOrNull(data);
      if (result == null) {
        onFailure?.call(ErrorMessages.responseParse);
      }
      return result;
    } catch (error) {
      debugPrint('[MissionService] 미션 보상 받기 실패: $error');
      onFailure?.call(_failureMessage(error));
      return null;
    }
  }

  /// 서버가 준 에러 코드(7010, 7011, 7012)를 사용자 문구로 바꾼다.
  String _failureMessage(Object error) {
    if (error is BadRequestException) return error.getUserMessage();
    if (error is UnauthorizedException) return error.getUserMessage();
    if (error is NetworkException) return error.getUserMessage();
    if (error is TimeoutException) return error.getUserMessage();
    if (error is ServerException) return error.getUserMessage();
    if (error is ParseException) return ErrorMessages.responseParse;
    if (error is ApiException) return error.getUserMessage();
    return ErrorMessages.unknown;
  }
}
