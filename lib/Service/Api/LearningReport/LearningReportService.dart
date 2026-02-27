import 'package:intl/intl.dart';
import 'package:ono/Config/AppConfig.dart';
import 'package:ono/Model/LearningReport/LearningReportResponseModel.dart';

import '../HttpService.dart';

class LearningReportService {
  final HttpService httpService = HttpService();
  final String baseUrl = '${AppConfig.baseUrl}/api/learning-reports';

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
}
