import 'package:ono/Model/PracticeNote/PracticeNoteThumbnailModel.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteUpdateModel.dart';

import '../../../Config/AppConfig.dart';
import '../../../Model/PracticeNote/PracticeNoteModel.dart';
import '../../../Model/PracticeNote/PracticeNoteRegisterModel.dart';
import '../HttpService.dart';

class PracticeNoteService {
  final HttpService httpService = HttpService();
  final baseUrl = "${AppConfig.baseUrl}/api/practiceNotes";

  Future<PracticeNoteModel> getPracticeNoteById(int practiceId) async {
    final data = await httpService.sendRequest(
      method: 'GET',
      url: '$baseUrl/$practiceId',
    );

    return PracticeNoteModel.fromJson(data);
  }

  Future<List<PracticeNoteThumbnailModel>> fetchPracticeNoteThumbnails() async {
    final data = await httpService.sendRequest(
      method: 'GET',
      url: '$baseUrl/thumbnail',
    ) as List<dynamic>;

    return data
        .map((d) =>
            PracticeNoteThumbnailModel.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  Future<void> registerPracticeNote(
      PracticeNoteRegisterModel practiceNoteRegisterModel) async {
    await httpService.sendRequest(
      method: 'POST',
      url: baseUrl,
      body: practiceNoteRegisterModel.toJson(),
    );
  }

  Future<void> addPracticeNoteCount(int practiceId) async {
    await httpService.sendRequest(
      method: 'PATCH',
      url: '$baseUrl/$practiceId/complete',
    );
  }

  Future<void> updatePracticeNote(
      PracticeNoteUpdateModel practiceNoteUpdateModel) async {
    await httpService.sendRequest(
      method: 'PATCH',
      url: '$baseUrl',
      body: practiceNoteUpdateModel.toJson(),
    );
  }

  Future<void> deletePracticeNotes(List<int> practiceNoteIdList) async {
    await httpService.sendRequest(
      method: 'DELETE',
      url: '$baseUrl',
      body: {'deletePracticeIdList': practiceNoteIdList},
    );
  }

  Future<void> deleteUserPracticeNotes() async {
    await httpService.sendRequest(
      method: 'DELETE',
      url: '$baseUrl/all',
    );
  }
}
