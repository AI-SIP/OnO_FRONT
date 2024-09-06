import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ono/Model/FolderThumbnailModel.dart';

import '../Config/AppConfig.dart';
import '../Model/FolderModel.dart';
import '../Model/ProblemModel.dart';
import 'TokenProvider.dart';
import 'package:http/http.dart' as http;

class FoldersProvider with ChangeNotifier {
  FolderModel? _currentFolder;
  List<ProblemModel> _problems = [];
  final TokenProvider tokenProvider = TokenProvider();

  int? currentFolderId; // 현재 폴더 ID 저장

  FolderModel? get currentFolder => _currentFolder;
  List<ProblemModel> get problems => List.unmodifiable(_problems);

  Future<void> fetchRootFolderContents() async {
    final accessToken = await tokenProvider.getAccessToken();
    if (accessToken == null) {
      log('Access token is not available');
      return;
    }

    final url = Uri.parse('${AppConfig.baseUrl}/api/folder');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));

      // 폴더 및 문제 데이터 초기화
      _currentFolder = FolderModel.fromJson(jsonResponse);
      _problems = (jsonResponse['problems'] as List)
          .map((e) => ProblemModel.fromJson(e))
          .toList();

      currentFolderId = jsonResponse['folderId']; // 현재 폴더 ID 업데이트
      notifyListeners(); // 데이터 갱신
      log('Folder contents fetched: ${_currentFolder?.folderName}, ${_problems.length} problems');
    } else {
      log('Failed to load folder contents');
    }
  }

  // 폴더 내용 로드 (특정 폴더 ID로)
  Future<void> fetchFolderContents({required int folderId}) async {
    if (currentFolderId == folderId) {
      // 이미 해당 폴더를 보고 있을 때는 다시 데이터를 요청하지 않음
      log('Already viewing the current folder: $folderId');
      return;
    }

    final accessToken = await tokenProvider.getAccessToken();
    if (accessToken == null) {
      log('Access token is not available');
      return;
    }

    final url = Uri.parse('${AppConfig.baseUrl}/api/folder/$folderId');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));

      // 폴더 및 문제 데이터 초기화
      _currentFolder = FolderModel.fromJson(jsonResponse);
      _problems = (jsonResponse['problems'] as List)
          .map((e) => ProblemModel.fromJson(e))
          .toList();

      currentFolderId = folderId; // 현재 폴더 ID 업데이트
      notifyListeners(); // 데이터 갱신
      log('Folder contents fetched: ${_currentFolder?.folderName}, ${_problems.length} problems');
    } else {
      log('Failed to load folder contents');
    }
  }

  Future<List<FolderThumbnailModel>?> fetchAllFolderThumbnails() async {
    final accessToken = await tokenProvider.getAccessToken();
    if (accessToken == null) {
      log('Access token is not available');
      return null;
    }

    final url = Uri.parse('${AppConfig.baseUrl}/api/folder/folders');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      log('AllFolderThumbnail Fetch Complete : ${jsonResponse}');

      return (jsonResponse as List)
          .map((e) => FolderThumbnailModel.fromJson(e))
          .toList();
    } else {
      log('Failed to load folder contents');
      return null;
    }
  }

  // 폴더 생성
  Future<void> createFolder(String folderName, int? parentFolderId) async {
    final accessToken = await tokenProvider.getAccessToken();
    if (accessToken == null) {
      log('Access token is not available');
      return;
    }

    final url = Uri.parse('${AppConfig.baseUrl}/api/folder');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
      body: json.encode({
        'folderName': folderName,
        'parentFolderId': parentFolderId,
      }),
    );

    if (response.statusCode == 200) {
      log('Folder successfully created');
      // 폴더를 생성 후 부모 폴더 내용을 다시 로드
      await fetchFolderContents(folderId: parentFolderId ?? -1);
    } else {
      log('Failed to create folder');
    }
  }

  // 폴더 삭제
  Future<void> deleteFolder(String folderId) async {
    final accessToken = await tokenProvider.getAccessToken();
    if (accessToken == null) {
      log('Access token is not available');
      return;
    }

    final url = Uri.parse('${AppConfig.baseUrl}/api/folder/$folderId');
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      log('Folder successfully deleted');
      // 폴더 삭제 후 현재 폴더의 부모 폴더를 다시 로드
      await fetchRootFolderContents();
    } else {
      log('Failed to delete folder');
    }
  }

  // 상위 폴더로 이동
  Future<void> moveToParentFolder(int? parentFolderId) async {
    await fetchFolderContents(folderId: parentFolderId ?? -1);
  }
}
