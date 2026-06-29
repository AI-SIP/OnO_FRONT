import 'package:ono/Config/AppConfig.dart';
import 'package:ono/Model/StudyCalendar/StudyCalendarModel.dart';

import '../HttpService.dart';

class StudyCalendarService {
  final HttpService httpService = HttpService();
  final String baseUrl = '${AppConfig.baseUrl}/api/learning-calendar';

  Future<StudyCalendarModel> getStudyCalendar({
    required int year,
    required int month,
    bool showErrorSnackBar = true,
  }) async {
    final data = await httpService.sendRequest(
      method: 'GET',
      url: baseUrl,
      queryParams: {
        'year': year.toString(),
        'month': month.toString(),
      },
      showErrorSnackBar: showErrorSnackBar,
    ) as Map<String, dynamic>;

    return StudyCalendarModel.fromJson(data);
  }

  Future<void> updateMoodEmoji({
    required DateTime date,
    required String emojiKey,
    bool showErrorSnackBar = true,
  }) async {
    final dateText =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    await httpService.sendRequest(
      method: 'PATCH',
      url: '$baseUrl/mood',
      body: {
        'date': dateText,
        'emojiKey': emojiKey,
      },
      showErrorSnackBar: showErrorSnackBar,
    );
  }
}
