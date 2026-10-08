import 'package:intl/intl.dart';
import 'package:ono/Exception/ApiException.dart';
import 'package:ono/Config/AppConfig.dart';
import 'package:ono/Model/LearningReport/LearningOverviewModel.dart';
import 'package:ono/Model/LearningReport/LearningReportResponseModel.dart';

import '../HttpService.dart';

class LearningReportService {
  final HttpService httpService;

  LearningReportService({HttpService? httpService})
      : httpService = httpService ?? HttpService();
  final String baseUrl = '${AppConfig.baseUrl}/api/learning-reports';

  /// 공유 카드가 쓰는 예전 보고서. 학습 보고서 화면은 [getOverview] 를 쓴다.
  Future<LearningReportResponseModel> getLearningReport({
    DateTime? baseDate,
  }) async {
    final queryParams = <String, String>{};
    if (baseDate != null) {
      queryParams['baseDate'] = DateFormat('yyyy-MM-dd').format(baseDate);
    }

    final data = await httpService.sendRequest(
      method: 'GET',
      url: baseUrl,
      queryParams: queryParams.isEmpty ? null : queryParams,
    ) as Map<String, dynamic>;

    return LearningReportResponseModel.fromJson(data);
  }

  /// 학습 보고서 화면의 한 기간. [baseDate] 가 들어 있는 주나 달을 받는다.
  ///
  /// [baseDate] 를 비우면 서버가 오늘(KST)로 본다. 기기 날짜를 보내면 시간대가
  /// 다른 기기에서 하루 어긋난 주를 받을 수 있어서, 지금 기간은 비워서 부른다.
  Future<LearningOverviewModel> getOverview({
    required LearningOverviewPeriod period,
    DateTime? baseDate,
  }) async {
    final queryParams = <String, String>{'period': period.apiValue};
    if (baseDate != null) {
      queryParams['baseDate'] = DateFormat('yyyy-MM-dd').format(baseDate);
    }

    final data = await httpService.sendRequest(
      method: 'GET',
      url: '$baseUrl/overview',
      queryParams: queryParams,
    );

    // 본문이 비면 0 으로 채운 보고서를 그리는 대신 실패로 알린다. 기록이
    // 있는데 0 문제로 보이면 사용자가 서버 문제인 줄 모른다.
    if (data is! Map<String, dynamic>) throw ParseException();
    return LearningOverviewModel.fromJson(data);
  }
}
