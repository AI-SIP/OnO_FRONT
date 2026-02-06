import 'package:ono/Model/Common/PaginatedResponse.dart';
import 'package:ono/Model/Folder/FolderModel.dart';
import 'package:ono/Model/Folder/FolderRegisterModel.dart';
import 'package:ono/Model/Folder/FolderThumbnailModel.dart';

import '../../../Config/AppConfig.dart';
import '../HttpService.dart';

class FolderService {
  final HttpService httpService = HttpService();
  final baseUrl = "${AppConfig.baseUrl}/api/folders";

  Future<FolderModel> fetchFolder(int folderId) async {
    final data = await httpService.sendRequest(
      method: 'GET',
      url: '$baseUrl/$folderId',
    );

    return FolderModel.fromJson(data);
  }

  Future<FolderModel> getRootFolder() async {
    final data = await httpService.sendRequest(
      method: 'GET',
      url: '$baseUrl/root',
    );

    return FolderModel.fromJson(data);
  }

  Future<List<FolderThumbnailModel>> getAllFolderThumbnails() async {
    final data = await httpService.sendRequest(
      method: 'GET',
      url: '$baseUrl/thumbnails',
    ) as List<dynamic>;

    return data
        .map((d) => FolderThumbnailModel.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  Future<List<FolderModel>> getAllFolderDetails() async {
    final data = await httpService.sendRequest(
      method: 'GET',
      url: '$baseUrl',
    ) as List<dynamic>;

    final result = data
        .map((d) => FolderModel.fromJson(d as Map<String, dynamic>))
        .toList();

    return result;
  }

  Future<int> registerFolder(FolderRegisterModel folderRegisterModel) async {
    return await httpService.sendRequest(
      method: 'POST',
      url: baseUrl,
      body: folderRegisterModel.toJson(),
    ) as int;
  }

  Future<void> updateFolderInfo(FolderRegisterModel folderRegisterModel) async {
    await httpService.sendRequest(
      method: 'PATCH',
      url: '$baseUrl',
      body: folderRegisterModel.toJson(),
    );
  }

  Future<void> deleteFolders(List<int> folderIdList) async {
    await httpService.sendRequest(
      method: 'DELETE',
      url: baseUrl,
      body: {'deleteFolderIdList': folderIdList},
    );
  }

  Future<void> deleteUserFolders() async {
    await httpService.sendRequest(
      method: 'DELETE',
      url: '$baseUrl/all',
    );
  }

  // V2 API - Cursor-based pagination for subfolders
  Future<PaginatedResponse<FolderThumbnailModel>> getSubfoldersV2({
    required int folderId,
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
      url: '$baseUrl/$folderId/subfolders/V2',
      queryParams: queryParams,
    ) as Map<String, dynamic>;

    return PaginatedResponse.fromJson(
      data,
      (json) => FolderThumbnailModel.fromJson(json),
    );
  }

  // V2 API - Cursor-based pagination for all folder thumbnails
  Future<PaginatedResponse<FolderThumbnailModel>> getAllFolderThumbnailsV2({
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
      url: '$baseUrl/thumbnails/V2',
      queryParams: queryParams,
    ) as Map<String, dynamic>;

    return PaginatedResponse.fromJson(
      data,
      (json) => FolderThumbnailModel.fromJson(json),
    );
  }
}