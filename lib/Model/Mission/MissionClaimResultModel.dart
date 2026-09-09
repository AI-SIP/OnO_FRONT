import 'package:flutter/foundation.dart';

import 'MissionModel.dart';

/// 받기가 뜻대로 되지 않았을 때, 그것이 어떤 실패인지.
///
/// 이 둘을 가르는 것이 중요하다. 서버가 "안 된다"고 답한 것과, 서버가 뭐라고
/// 답했는지 **모르는** 것은 다르다. 후자는 보상이 이미 지급됐을 수 있어서
/// 실패라고 알리면 안 된다. 다시 조회해서 진실을 확인해야 한다.
enum MissionClaimFailureKind {
  /// 서버가 처리하고 거절했다. 보상은 나가지 않았다.
  rejected,

  /// 서버의 답을 받지 못했다. 보상이 나갔는지 알 수 없다.
  /// (연결 끊김, 시간 초과, 5xx, 응답을 읽지 못함)
  unknown,
}

/// 받기 실패 한 건. 화면이 무엇을 띄울지 정하는 데 쓴다.
class MissionClaimFailure {
  final MissionClaimFailureKind kind;

  /// 서버가 준 에러 코드. 7010, 7011, 7012 를 가르는 데 쓴다.
  final int? errorCode;

  /// 사용자에게 보여 줄 수 있는 문구.
  final String message;

  const MissionClaimFailure({
    required this.kind,
    required this.message,
    this.errorCode,
  });

  /// 이미 받은 미션(7012)인가. 서버 기준으로는 받은 상태라 실패로 알리지
  /// 않고 조용히 화면만 맞춘다.
  bool get isAlreadyClaimed => errorCode == 7012;

  /// 결과를 모르는 실패인가.
  bool get isUnknown => kind == MissionClaimFailureKind.unknown;
}

/// `POST /api/missions/{progressId}/claim` 의 응답이다.
///
/// [rewardType] 은 모르는 값이 올 수 있어 nullable 이다. 받기 자체는 이미
/// 성공한 뒤이므로, 종류를 모른다고 결과를 통째로 버리지 않는다. 이 경우
/// 화면은 XP 문구 대신 일반적인 문구를 띄운다.
class MissionClaimResultModel {
  final int progressId;
  final MissionRewardType? rewardType;
  final int rewardValue;

  /// 받은 뒤의 학습 레벨.
  final int? totalStudyLevel;

  /// 이번 보상으로 레벨이 올랐는지.
  final bool leveledUp;

  const MissionClaimResultModel({
    required this.progressId,
    required this.rewardType,
    required this.rewardValue,
    required this.totalStudyLevel,
    required this.leveledUp,
  });

  static MissionClaimResultModel? fromJsonOrNull(Object? json) {
    if (json is! Map<String, dynamic>) return null;

    try {
      final progressId = _asInt(json['progressId']);
      if (progressId == null) return null;

      return MissionClaimResultModel(
        progressId: progressId,
        rewardType: MissionRewardType.from(_asString(json['rewardType'])),
        rewardValue: _asInt(json['rewardValue']) ?? 0,
        totalStudyLevel: _asInt(json['totalStudyLevel']),
        leveledUp: json['leveledUp'] == true,
      );
    } catch (error) {
      debugPrint('[MissionClaimResultModel] 받기 결과를 읽지 못했다: $error');
      return null;
    }
  }

  static String? _asString(Object? value) {
    return value is String ? value : null;
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
