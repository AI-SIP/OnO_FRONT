import 'package:ono/Model/Common/PaginatedResponse.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteDetailModel.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteThumbnailModel.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteUpdateModel.dart';

import '../../../Config/AppConfig.dart';
import '../../../Model/PracticeNote/PracticeNoteRegisterModel.dart';
import '../HttpService.dart';

class PracticeNoteService {
  final HttpService httpService = HttpService();
  final baseUrl = "${AppConfig.baseUrl}/api/practiceNotes";

  Future<PracticeNoteDetailModel> getPracticeNoteById(int practiceId) async {
    final data = await httpService.sendRequest(
      method: 'GET',
      url: '$baseUrl/$practiceId',
    );

    return PracticeNoteDetailModel.fromJson(data);
  }

  Future<List<PracticeNoteThumbnails>> getAllPracticeNoteThumbnails() async {
    final data = await httpService.sendRequest(
      method: 'GET',
      url: '$baseUrl/thumbnail',
    ) as List<dynamic>;

    return data
        .map((d) => PracticeNoteThumbnails.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  Future<List<PracticeNoteDetailModel>> getAllPracticeNoteDetails() async {
    final data = await httpService.sendRequest(
      method: 'GET',
      url: '$baseUrl/all',
    ) as List<dynamic>;

    return data
        .map((d) => PracticeNoteDetailModel.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  Future<int> registerPracticeNote(
      PracticeNoteRegisterModel practiceNoteRegisterModel) async {
    return await httpService.sendRequest(
      method: 'POST',
      url: baseUrl,
      body: practiceNoteRegisterModel.toJson(),
    ) as int;
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

  // V2 API - Cursor-based pagination for practice note thumbnails
  Future<PaginatedResponse<PracticeNoteThumbnails>> getPracticeNoteThumbnailsV2({
    int? cursor,
    int size = 20,
  }) async {
    final queryParams = <String, String>{
      'size': size.toString(),
    };
    if (cursor != null) {
      queryParams['cursor'] = cursor.toString();
    }

    final data = await httpService.sendRequest(
      method: 'GET',
      url: '$baseUrl/thumbnail/V2',
      queryParams: queryParams,
    ) as Map<String, dynamic>;

    return PaginatedResponse.fromJson(
      data,
      (json) => PracticeNoteThumbnails.fromJson(json),
    );
  }
}
