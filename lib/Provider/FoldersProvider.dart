import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ono/GlobalModule/Util/ProblemSorting.dart';
import 'package:ono/Model/FolderThumbnailModel.dart';

import '../Config/AppConfig.dart';
import '../Model/FolderModel.dart';
import '../Model/ProblemModel.dart';
import '../Model/ProblemRegisterModel.dart';
import 'TokenProvider.dart';
import 'package:http/http.dart' as http;

class FoldersProvider with ChangeNotifier {
  FolderModel? _currentFolder;
  List<ProblemModel> _problems = [];
  final TokenProvider tokenProvider = TokenProvider();

  int? currentFolderId;
  String sortOption = 'newest';

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

      sortProblemsByOption(sortOption);
      currentFolderId = jsonResponse['folderId']; // 현재 폴더 ID 업데이트
      notifyListeners(); // 데이터 갱신
      log('Folder contents fetched: ${_currentFolder?.folderName}, ${problems.length} problems');
    } else {
      log('Failed to load folder contents');
    }
  }

  Future<void> fetchCurrentFolderContents() async {
    final accessToken = await tokenProvider.getAccessToken();
    if (accessToken == null) {
      log('Access token is not available');
      return;
    }

    final url = Uri.parse('${AppConfig.baseUrl}/api/folder/$currentFolderId');
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
      currentFolderId = jsonResponse['folderId'];

      sortProblemsByOption(sortOption);
      notifyListeners(); // 데이터 갱신
      log('Folder contents fetched: ${_currentFolder?.folderName}, ${problems.length} problems');
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

      sortProblemsByOption(sortOption);
      currentFolderId = folderId; // 현재 폴더 ID 업데이트
      notifyListeners(); // 데이터 갱신
      log('Folder contents fetched folderId : ${_currentFolder?.folderId}, folderName : ${_currentFolder?.folderName}, ${problems.length} problems');
    } else {
      log('Failed to load folder contents');
    }
  }

  Future<List<FolderThumbnailModel>> fetchAllFolderThumbnails() async {
    final accessToken = await tokenProvider.getAccessToken();
    if (accessToken == null) {
      log('Access token is not available');
      return [];
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
      log('AllFolderThumbnail Fetch Complete : $jsonResponse');

      // JSON 응답을 FolderThumbnailModel 리스트로 변환
      return (jsonResponse as List)
          .map((e) => FolderThumbnailModel.fromJson(e))
          .toList();
    } else {
      log('Failed to load folder contents');
      return [];
    }
  }

  // 폴더 생성
  Future<void> createFolder(String folderName) async {
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
        'parentFolderId': currentFolderId,
      }),
    );

    if (response.statusCode == 200) {
      log('Folder successfully created');
      // 폴더를 생성 후 부모 폴더 내용을 다시 로드
      await fetchCurrentFolderContents();
    } else {
      log('Failed to create folder');
    }
  }

  Future<void> updateFolder(String newName, int? parentId) async {
    final accessToken = await tokenProvider.getAccessToken();
    if (accessToken == null) {
      log('Access token is not available');
      return;
    }

    final url = Uri.parse('${AppConfig.baseUrl}/api/folder/$currentFolderId');
    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
      body: json.encode({
        'folderName': newName,
        'parentFolderId': parentId, // 폴더의 상위 폴더 ID가 필요한 경우 추가
      }),
    );

    if (response.statusCode == 200) {
      log('Folder name successfully updated to $newName');
      // 폴더 내용 다시 로드
      await fetchCurrentFolderContents();
    } else {
      log('Failed to update folder name: ${response.reasonPhrase}');
    }
  }

  // 폴더 삭제
  Future<void> deleteFolder(int folderId) async {
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
      log('folderId: $folderId successfully deleted');

      // JSON 응답 파싱
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));

      int parentFolderId = jsonResponse['folderId'] as int;

      // 부모 폴더 내용 불러오기
      await fetchFolderContents(folderId: parentFolderId);
    } else {
      log('Failed to delete folder');
    }
  }

  // 상위 폴더로 이동
  Future<void> moveToParentFolder(int? parentFolderId) async {
    await fetchFolderContents(folderId: parentFolderId ?? -1);
  }

  Future<void> submitProblem(
      ProblemRegisterModel problemData, BuildContext context) async {
    final accessToken = await tokenProvider.getAccessToken();
    if (accessToken == null) {
      throw Exception("JWT token is not available");
    }

    var uri = Uri.parse('${AppConfig.baseUrl}/api/problem');
    var request = http.MultipartRequest('POST', uri)
      ..headers.addAll({'Authorization': 'Bearer $accessToken'});
    request.fields['solvedAt'] = problemData.solvedAt?.toIso8601String() ?? "";
    request.fields['reference'] = problemData.reference ?? "";
    request.fields['memo'] = problemData.memo ?? "";
    request.fields['folderId'] = problemData.folderId.toString();

    final problemImage = problemData.problemImage;
    final solveImage = problemData.solveImage;
    final answerImage = problemData.answerImage;
    final colors = problemData.colors;

    if (problemImage != null) {
      request.files.add(
          await http.MultipartFile.fromPath('problemImage', problemImage.path));
      if (colors != null) {
        request.fields['colors'] = jsonEncode(colors);
      }
    }
    if (solveImage != null) {
      request.files.add(
          await http.MultipartFile.fromPath('solveImage', solveImage.path));
    }
    if (answerImage != null) {
      request.files.add(
          await http.MultipartFile.fromPath('answerImage', answerImage.path));
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        log('Problem successfully submitted');
        await fetchRootFolderContents();
      } else {
        log('Failed to submit problem: ${response.reasonPhrase}');
      }
    } catch (e) {
      log('Error submitting problem: $e');
    }
  }

  Future<ProblemModel?> getProblemDetails(int? problemId) async {
    try {
      var problemDetails =
          _problems.firstWhere((problem) => problem.problemId == problemId);

      if (problemDetails != null) {
        return ProblemModel.fromJson(problemDetails.toJson());
      } else {
        log('Problem with ID $problemId not found');
        return null;
      }
    } catch (e) {
      log('Error fetching problem details for ID $problemId: $e');
      return null;
    }
  }

  Future<void> updateProblem(ProblemRegisterModel problemData) async {
    final accessToken = await tokenProvider.getAccessToken();
    if (accessToken == null) {
      throw Exception("JWT token is not available");
    }

    var uri = Uri.parse('${AppConfig.baseUrl}/api/problem');
    var request = http.MultipartRequest('PATCH', uri)
      ..headers.addAll({'Authorization': 'Bearer $accessToken'});

    request.fields['problemId'] = (problemData.problemId ?? -1).toString();

    if (problemData.solvedAt != null) {
      request.fields['solvedAt'] = problemData.solvedAt!.toIso8601String();
    }

    if (problemData.reference != null && problemData.reference!.isNotEmpty) {
      request.fields['reference'] = problemData.reference!;
    }
    if (problemData.memo != null && problemData.memo!.isNotEmpty) {
      request.fields['memo'] = problemData.memo!;
    }

    if (problemData.folderId != null) {
      request.fields['folderId'] = problemData.folderId!.toString();
    }

    final problemImage = problemData.problemImage;
    final colors = problemData.colors;
    if (problemImage != null) {
      request.files.add(
          await http.MultipartFile.fromPath('problemImage', problemImage.path));

      if (colors != null) {
        request.fields['colors'] = jsonEncode(colors);
      }
    }

    final solveImage = problemData.solveImage;
    if (solveImage != null) {
      request.files.add(
          await http.MultipartFile.fromPath('solveImage', solveImage.path));
    }

    final answerImage = problemData.answerImage;
    if (answerImage != null) {
      request.files.add(
          await http.MultipartFile.fromPath('answerImage', answerImage.path));
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        log('Problem successfully submitted');
        await fetchCurrentFolderContents();
      } else {
        log('Failed to submit problem: ${response.reasonPhrase}');
      }
    } catch (e) {
      log('Error submitting problem: $e');
    }
  }

  Future<bool> deleteProblem(int problemId) async {
    final accessToken = await tokenProvider.getAccessToken();
    if (accessToken == null) {
      log('accessToken is not available');
      throw Exception('accessToken is not available');
    }

    final url = Uri.parse('${AppConfig.baseUrl}/api/problem');
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
        'problemId': problemId.toString(),
      },
    );

    log('Deleting problem: ${response.statusCode} ${response.body}');

    if (response.statusCode == 200) {
      log('Problem successfully deleted');

      return true;
    } else {
      log('Failed to delete problem from server');
      return false;
    }
  }

  void sortProblemsByOption(String option) {
    if (option == 'name') {
      sortProblemsByName();
    } else if (option == 'newest') {
      sortProblemsByNewest();
    } else if (option == 'oldest') {
      sortProblemsByOldest();
    }
  }

  void sortProblemsByName() {
    _problems.sortByName();
    sortOption = 'name';
  }

  void sortProblemsByNewest() {
    _problems.sortByNewest();
    sortOption = 'newest';
  }

  void sortProblemsByOldest() {
    _problems.sortByOldest();
    sortOption = 'oldest';
  }

  List<int> getProblemIds() {
    return _problems.map((problem) => problem.problemId as int).toList();
  }
}
