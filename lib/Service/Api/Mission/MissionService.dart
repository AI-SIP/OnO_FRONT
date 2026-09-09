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
  /// 다만 [HttpService] 의 기본 알림은 아래에서 올라오는 SnackBar 라서, 실패
  /// 내용만 [onFailure] 로 넘기고 띄우는 것은 화면이 하도록 둔다.
  ///
  /// 실패를 두 갈래로 나눠 넘긴다. 서버가 거절한 것([MissionClaimFailureKind.rejected])과
  /// 서버의 답을 받지 못한 것([MissionClaimFailureKind.unknown])이다. 후자는
  /// 보상이 이미 지급됐을 수 있어서 실패라고 알리면 안 된다.
  Future<MissionClaimResultModel?> claim(
    int progressId, {
    void Function(MissionClaimFailure failure)? onFailure,
  }) async {
    try {
      final data = await _httpService.sendRequest(
        method: 'POST',
        url: '$_baseUrl/$progressId/claim',
        showErrorSnackBar: false,
      );

      final result = MissionClaimResultModel.fromJsonOrNull(data);
      if (result == null) {
        // 서버는 2xx 로 답했는데 본문을 읽지 못했다. 보상은 이미 나갔다고
        // 봐야 한다. 실패로 단정하지 않는다.
        debugPrint('[MissionService] 받기 응답을 읽지 못했다: $data');
        onFailure?.call(
          const MissionClaimFailure(
            kind: MissionClaimFailureKind.unknown,
            message: ErrorMessages.responseParse,
          ),
        );
      }
      return result;
    } catch (error) {
      debugPrint('[MissionService] 미션 보상 받기 실패: $error');
      onFailure?.call(_toFailure(error));
      return null;
    }
  }

  /// 예외를 실패 한 건으로 옮긴다.
  ///
  /// 서버가 에러 코드(7010, 7011, 7012)나 4xx 로 답했으면 서버가 요청을
  /// 처리하고 거절한 것이다. 연결이 끊기거나 시간이 초과되거나 5xx 가
  /// 나면 서버가 어디까지 처리했는지 알 수 없다.
  MissionClaimFailure _toFailure(Object error) {
    if (error is BadRequestException) {
      return MissionClaimFailure(
        kind: MissionClaimFailureKind.rejected,
        errorCode: error.errorCode,
        message: error.getUserMessage(),
      );
    }
    if (error is UnauthorizedException) {
      return MissionClaimFailure(
        kind: MissionClaimFailureKind.rejected,
        errorCode: error.errorCode,
        message: error.getUserMessage(),
      );
    }
    if (error is ApiException) {
      final status = error.statusCode;
      final rejected = status != null && status >= 400 && status < 500;
      return MissionClaimFailure(
        kind: rejected
            ? MissionClaimFailureKind.rejected
            : MissionClaimFailureKind.unknown,
        errorCode: error.errorCode,
        message: error.getUserMessage(),
      );
    }
    if (error is ServerException) {
      return MissionClaimFailure(
        kind: MissionClaimFailureKind.unknown,
        message: error.getUserMessage(),
      );
    }
    if (error is NetworkException) {
      return MissionClaimFailure(
        kind: MissionClaimFailureKind.unknown,
        message: error.getUserMessage(),
      );
    }
    if (error is TimeoutException) {
      return MissionClaimFailure(
        kind: MissionClaimFailureKind.unknown,
        message: error.getUserMessage(),
      );
    }
    if (error is ParseException) {
      return const MissionClaimFailure(
        kind: MissionClaimFailureKind.unknown,
        message: ErrorMessages.responseParse,
      );
    }
    return const MissionClaimFailure(
      kind: MissionClaimFailureKind.unknown,
      message: ErrorMessages.unknown,
    );
  }
}
