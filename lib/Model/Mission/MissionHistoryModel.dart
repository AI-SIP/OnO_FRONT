import 'package:flutter/foundation.dart';

import 'MissionModel.dart';

/// 받은 보상 한 건이다.
///
/// 미션 목록과 달리 이미 끝난 일이라 [MissionCategory] 나 [MissionRewardType] 을
/// 몰라도 버리지 않는다. 기록은 "언제 무엇을 받았다"가 전부고, 종류를 모른다고
/// 지난 일이 없던 일이 되면 안 된다.
class MissionHistoryItemModel {
  final int progressId;
  final String code;
  final String title;
  final String iconKey;
  final MissionCategory? category;

  /// 그 진행도가 속했던 기간의 키.
  final String? periodKey;

  final MissionRewardType? rewardType;
  final int rewardValue;

  /// 받은 시각.
  final DateTime claimedAt;

  const MissionHistoryItemModel({
    required this.progressId,
    required this.code,
    required this.title,
    required this.iconKey,
    required this.category,
    required this.periodKey,
    required this.rewardType,
    required this.rewardValue,
    required this.claimedAt,
  });

  /// 읽을 수 없는 기록이면 null 이다. 그 줄만 버리고 나머지는 살린다.
  ///
  /// [claimedAt] 은 반드시 있어야 한다. 받은 시각을 모르면 날짜로 묶을 수 없고,
  /// 목록에서 어디에 놓아야 할지도 정할 수 없다.
  static MissionHistoryItemModel? fromJsonOrNull(Object? json) {
    if (json is! Map<String, dynamic>) return null;

    try {
      final claimedAt = DateTime.tryParse(_asString(json['claimedAt']) ?? '');
      if (claimedAt == null) return null;

      final progressId = _asInt(json['progressId']);
      if (progressId == null) return null;

      return MissionHistoryItemModel(
        progressId: progressId,
        code: _asString(json['code']) ?? '',
        title: _asString(json['title']) ?? '',
        iconKey: _asString(json['iconKey']) ?? MissionModel.fallbackIconKey,
        category: MissionCategory.from(_asString(json['category'])),
        periodKey: _asString(json['periodKey']),
        rewardType: MissionRewardType.from(_asString(json['rewardType'])),
        rewardValue: _asInt(json['rewardValue']) ?? 0,
        claimedAt: claimedAt,
      );
    } catch (error) {
      debugPrint('[MissionHistoryItemModel] 기록 하나를 읽지 못해 건너뛴다: $error');
      return null;
    }
  }

  static String? _asString(Object? value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    return null;
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

/// `GET /api/missions/history` 한 페이지다.
///
/// 커서 페이지네이션은 기존 `/V2` 엔드포인트들과 같은 규약을 쓴다.
/// [totalClaimedXp] 와 [totalClaimedCount] 는 **첫 페이지에만** 온다. 다음
/// 페이지부터는 없거나 null 이므로 화면은 첫 페이지 값을 들고 있어야 한다.
class MissionHistoryPageModel {
  final List<MissionHistoryItemModel> content;
  final int? nextCursor;
  final bool hasNext;
  final int? totalClaimedXp;
  final int? totalClaimedCount;

  const MissionHistoryPageModel({
    required this.content,
    required this.nextCursor,
    required this.hasNext,
    this.totalClaimedXp,
    this.totalClaimedCount,
  });

  static const MissionHistoryPageModel empty = MissionHistoryPageModel(
    content: [],
    nextCursor: null,
    hasNext: false,
  );

  factory MissionHistoryPageModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return empty;

    final rawContent = json['content'];
    final content = rawContent is List
        ? rawContent
            .map(MissionHistoryItemModel.fromJsonOrNull)
            .whereType<MissionHistoryItemModel>()
            .toList()
        : <MissionHistoryItemModel>[];

    return MissionHistoryPageModel(
      content: content,
      nextCursor: MissionHistoryItemModel._asInt(json['nextCursor']),
      hasNext: json['hasNext'] == true,
      totalClaimedXp: MissionHistoryItemModel._asInt(json['totalClaimedXp']),
      totalClaimedCount:
          MissionHistoryItemModel._asInt(json['totalClaimedCount']),
    );
  }

  /// 더 읽을 것이 없으면 true. 커서가 없으면 다음 요청을 보낼 수 없다.
  bool get isLastPage => !hasNext || nextCursor == null;
}
