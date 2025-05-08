import 'dart:convert';
import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:ono/Service/Network/HttpService.dart';
import 'package:ono/GlobalModule/Util/ProblemSorting.dart';
import 'package:ono/GlobalModule/Util/ReviewHandler.dart';
import 'package:ono/Model/Problem/TemplateType.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../Config/AppConfig.dart';
import '../Model/Folder/FolderModel.dart';
import '../Model/Problem/ProblemModel.dart';
import '../Model/Problem/ProblemRegisterModel.dart';
import '../Model/Problem/ProblemRegisterModelV2.dart';
import 'TokenProvider.dart';
import 'package:http/http.dart' as http;

class FoldersProvider with ChangeNotifier {
  FolderModel? _currentFolder;
  List<FolderModel> _folders = [];
  List<ProblemModel> _currentProblems = [];
  final TokenProvider tokenProvider = TokenProvider();
  final ReviewHandler reviewHandler = ReviewHandler();
  final HttpService httpService = HttpService();

  String sortOption = 'newest';

  FolderModel? get currentFolder => _currentFolder;
  List<ProblemModel> get currentProblems => List.unmodifiable(_currentProblems);
  List<FolderModel> get folders => _folders;

  // 상위 폴더로 이동
  Future<void> moveToFolder(int? folderId) async {
      FolderModel targetFolder = _folders.firstWhere((f) => f.folderId == folderId);

      _currentFolder = targetFolder;
      _currentProblems = targetFolder.problems;
      sortProblemsByOption(sortOption);

      log('Moved to folder: ${targetFolder.folderId}, Problems: ${_currentProblems.length}');

      // 4) UI 갱신
      notifyListeners();
  }

  Future<void> moveToRootFolder() async {
      // 전달받은 folderId에 해당하는 폴더를 _folders에서 검색
      final rootFolder = _folders[0];
      moveToFolder(rootFolder.folderId);
  }

  FolderModel getFolderContents(int? folderId) {
    return _folders.firstWhere(
          (folder) => folder.folderId == folderId,
      orElse: () => throw Exception('Folder with ID $folderId not found'),
    );
  }

  // 폴더 내용 로드 (특정 폴더 ID로)
  Future<void> fetchFolderContent(int? folderId) async {
    folderId ??= currentFolder!.folderId;

    final response = await httpService.sendRequest(
      method: 'GET',
      url: '${AppConfig.baseUrl}/api/folders/$folderId',
    );

    print("Folder Response: ${response}");
    if (response != null) {
      final updatedFolder = FolderModel.fromJson(response);

      // 기존 데이터를 업데이트
      final index = _folders.indexWhere((folder) => folder.folderId == folderId);
      if (index != -1) {
        _folders[index] = updatedFolder;
      } else {
        _folders.add(updatedFolder);
      }

      print("folder fetch complete");
      notifyListeners();
    } else {
      throw Exception('Failed to fetch folder by ID');
    }
  }

  Future<void> fetchAllFolderContents() async {
    final response = await httpService.sendRequest(
      method: 'GET',
      url: '${AppConfig.baseUrl}/api/folders',
    );

    if (response != null) {
      final dataList = response as List<dynamic>;
      _folders = dataList
          .map((e) => FolderModel.fromJson(e as Map<String, dynamic>))
          .toList();
      log('fetch all folder contents');

      for (var folder in _folders) {
        log('-----------------------------------------');
        log('Folder ID: ${folder.folderId}');
        log('Folder Name: ${folder.folderName}');
        log('Parent Folder Id: ${folder.parentFolder?.folderId ?? "No Parent"}');
        log('problem length: ${folder.problems.length}');
        log('Number of Problems: ${folder.problems.length}');
        log('Length of Subfolders: ${folder.subFolderList.length}');
        log('Created At: ${folder.createdAt}');
        log('Updated At: ${folder.updateAt}');
        log('-----------------------------------------');
      }

      await moveToRootFolder();
    } else {
      throw Exception('Failed to load RootFolderContents');
    }
  }

  Future<void> clearFolderContents() async{
    _currentFolder = null;
    _folders = [];
    _currentProblems = [];

    notifyListeners();
  }

  // 폴더 생성
  Future<void> createFolder(String folderName, {int? parentFolderId}) async {
    final response = await httpService.sendRequest(
      method: 'POST',
      url: '${AppConfig.baseUrl}/api/folders',
      body: {
        'folderName': folderName,
        'parentFolderId': parentFolderId ?? currentFolder!.folderId,
      },
    );

    if (response != null) {
      log('Folder successfully created, folderId: ${response}');

      await fetchFolderContent(response);
      await fetchFolderContent(_currentFolder!.folderId);
      await moveToFolder(_currentFolder!.folderId);
    } else {
      throw Exception('Failed to create folder');
    }
  }

  Future<void> updateFolder(String? newName, int? folderId, int? parentId) async {
    final response = await httpService.sendRequest(
      method: 'PATCH',
      url: '${AppConfig.baseUrl}/api/folders/$folderId',
      body: {
        'folderName': newName,
        'parentFolderId': parentId,
      },
    );

    if (response != null) {
      log('Folder name successfully updated to $newName');

      await fetchFolderContent(parentId);
      await fetchFolderContent(folderId);
      await fetchFolderContent(currentFolder!.folderId);

      await moveToFolder(currentFolder!.folderId);
    } else {
      throw Exception('Failed to update folder name');
    }
  }

  // 폴더 삭제
  Future<void> deleteFolders(List<int> deleteFolderIdList) async {
    final queryParams = {
      'deleteFolderIdList': deleteFolderIdList.join(','), // 쉼표로 구분된 문자열로 변환
    };

    final response = await httpService.sendRequest(
      method: 'DELETE',
      url: '${AppConfig.baseUrl}/api/folders',
      queryParams: queryParams,
    );

    if (response != null) {
      log('Folder successfully deleted');

      await fetchFolderContent(currentFolder!.folderId);
      await moveToFolder(currentFolder!.folderId);
    } else {
      throw Exception('Failed to delete folder');
    }
  }

  // 문제 이미지 미리 전송
  Future<Map<String, dynamic>?> uploadProblemImage(XFile? problemImage) async{
    final response = await httpService.sendRequest(
      method: 'POST',
      url: '${AppConfig.baseUrl}/api/process/problemImage',
      isMultipart: true,
      files: [await http.MultipartFile.fromPath('problemImage', problemImage!.path)],
    );

    if (response != null) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      log('success for upload problem image: ${jsonResponse['problemImageUrl']}');
      return {
        'problemId': jsonResponse['problemId'],
        'problemImageUrl': jsonResponse['problemImageUrl'],
      };
    } else {
      throw Exception('Failed to upload problem image');
      return null;
    }
  }

  Future<String?> fetchProcessImage(String? fullUrl, Map<String, dynamic>? colorPickerResult, List<List<double>>? coordinatePickerResult) async {

    List<int>? labels = coordinatePickerResult != null
        ? List<int>.filled(coordinatePickerResult.length, 1)
        : null;

    if(colorPickerResult != null){
      log('remove colors: ${colorPickerResult['colors']}');
      log('remove intensity: ${colorPickerResult['intensity']}');
    } else if(coordinatePickerResult != null){
      log('point list: ${coordinatePickerResult.toString()}');
    }
    final response = await httpService.sendRequest(
      method: 'POST',
      url: '${AppConfig.baseUrl}/api/process/processImage',
      body: {
        'fullUrl': fullUrl,
        'colorsList': colorPickerResult != null ? colorPickerResult['colors'] : null,
        'intensity' : colorPickerResult != null ? colorPickerResult['intensity'] : null,
        'points' : coordinatePickerResult,
        'labels': labels,
      },
    );

    if (response != null) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      log('image process result : ${jsonResponse['processImageUrl']}');
      return jsonResponse['processImageUrl'];
    } else {
      log('Failed to fetch process image URL: ${response.body}');
      return null;
    }
  }

  Future<String?> fetchAnalysisResult(String? problemImageUrl) async {
    final response = await httpService.sendRequest(
      method: 'POST', // 'GET'에서 'POST'로 변경
      url: '${AppConfig.baseUrl}/api/process/analysis',
      body: {'problemImageUrl': problemImageUrl},
    );

    if (response != null) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      log('analysis : ${jsonResponse['analysis']}');
      return jsonResponse['analysis'];
    } else {
      log('Failed to fetch analysis result: ${response.body}');
      return null;
    }
  }

  Future<void> submitProblem(
      ProblemRegisterModel problemData, BuildContext context) async {

    final files = <http.MultipartFile>[];

    if (problemData.solveImage != null) {
      files.add(await http.MultipartFile.fromPath('solveImage', problemData.solveImage!.path));
    }
    if (problemData.answerImage != null) {
      files.add(await http.MultipartFile.fromPath('answerImage', problemData.answerImage!.path));
    }

    final requestBody = {
      'problemId': problemData.problemId.toString(),
      'solvedAt': (problemData.solvedAt ?? DateTime.now()).toIso8601String(),
      'reference': problemData.reference ?? "",
      'memo': problemData.memo ?? "",
      'folderId': (problemData.folderId ?? currentFolder!.folderId).toString(),
      'templateType': problemData.templateType!.templateTypeCode.toString(),
      'analysis': problemData.analysis ?? "",
    };

    if (problemData.templateType == TemplateType.clean ||
        problemData.templateType == TemplateType.special) {
      if(problemData.processImageUrl != null){
        requestBody['processImageUrl'] = problemData.processImageUrl!;
      }
    }

    final response = await httpService.sendRequest(
      method: 'POST',
      url: '${AppConfig.baseUrl}/api/problems',
      isMultipart: false,
      files: files,
      body: requestBody,
    );

    if (response != null) {
      log('Problem successfully submitted');
      await fetchFolderContent(_currentFolder!.folderId);

      int userProblemCount = await getUserProblemCount();
      if (userProblemCount > 0 && userProblemCount % 10 == 0) {
        reviewHandler.requestReview(context);
      }
    } else {
      throw Exception('Failed to submit problem');
    }
  }

  Future<void> submitProblemV2(
      ProblemRegisterModelV2 problemData, BuildContext context) async {

    final files = <http.MultipartFile>[];

    if (problemData.problemImage != null) {
      files.add(await http.MultipartFile.fromPath('problemImage', problemData.problemImage!.path));
    }
    if (problemData.answerImage != null) {
      files.add(await http.MultipartFile.fromPath('answerImage', problemData.answerImage!.path));
    }

    final requestBody = {
      'solvedAt': (problemData.solvedAt ?? DateTime.now()).toIso8601String(),
      'reference': problemData.reference ?? "",
      'memo': problemData.memo ?? "",
      'folderId': (problemData.folderId ?? currentFolder!.folderId).toString(),
      'imageDataDtoList' : []
    };

    if (problemData.problemId != null) {
      requestBody['problemId'] = problemData.problemId.toString();
    }

    final response = await httpService.sendRequest(
      method: 'POST',
      url: '${AppConfig.baseUrl}/api/problems',
      isMultipart: false,
      files: files,
      body: requestBody,
    );

    if (response != null) {
      log('Problem successfully submitted');

      await fetchFolderContent(problemData.folderId ?? currentFolder!.folderId);
      await moveToFolder(currentFolder!.folderId);

      int userProblemCount = await getUserProblemCount();
      if (userProblemCount > 0 && userProblemCount % 10 == 0) {
        reviewHandler.requestReview(context);
      }
    } else {
      throw Exception('Failed to submit problem');
    }
  }

  Future<int> getUserProblemCount() async {

    final response = await httpService.sendRequest(
      method: 'GET',
      url: '${AppConfig.baseUrl}/api/problems/problemCount',
    );

    if (response != null) {
      int userProblemCount = int.parse(response.body);
      log('User problem count: $userProblemCount');
      return userProblemCount;
    } else {
      throw Exception('Failed to get user problem count');
    }
  }

  Future<void> updateProblem(ProblemRegisterModel problemData) async {
    final files = <http.MultipartFile>[];
    if (problemData.answerImage != null) {
      files.add(await http.MultipartFile.fromPath('answerImage', problemData.answerImage!.path));
    }

    final response = await httpService.sendRequest(
      method: 'PATCH',
      url: '${AppConfig.baseUrl}/api/problems',
      isMultipart: true,
      files: files,
      body: {
        'problemId': (problemData.problemId ?? -1).toString(),
        if (problemData.solvedAt != null) 'solvedAt': problemData.solvedAt!.toIso8601String(),
        if (problemData.reference != null && problemData.reference!.isNotEmpty)
          'reference': problemData.reference!,
        if (problemData.memo != null && problemData.memo!.isNotEmpty)
          'memo': problemData.memo!,
        if (problemData.folderId != null) 'folderId': problemData.folderId!.toString(),
      },
    );

    if (response != null) {
      log('Problem successfully updated');

      if (problemData.folderId != null){
        await fetchFolderContent(problemData.folderId!);
      }
      await fetchFolderContent(_currentFolder!.folderId);

      await moveToFolder(_currentFolder!.folderId);
    } else {
      throw Exception('Failed to update problem');
    }
  }

  Future<bool> deleteProblems(List<int> deleteProblemIdList) async {
    final queryParams = {
      'deleteProblemIdList': deleteProblemIdList.join(','), // 쉼표로 구분된 문자열로 변환
    };

    final response = await httpService.sendRequest(
        method: 'DELETE',
        url: '${AppConfig.baseUrl}/api/problem',
        queryParams: queryParams
    );

    if (response != null) {
      log('Problem successfully deleted');
      await fetchFolderContent(_currentFolder!.folderId);
      await moveToFolder(_currentFolder!.folderId);

      return true;
    } else {
      throw Exception('Failed to delete problem');
    }
  }

  Future<void> addRepeatCount(int problemId, XFile? solveImage) async {
    if (solveImage != null) {
      // Multipart 파일로 변환
      final file = await http.MultipartFile.fromPath('solveImage', solveImage.path);

      // Multipart 요청 생성
      final response = await httpService.sendRequest(
        method: 'POST',
        url: '${AppConfig.baseUrl}/api/problems/repeat',
        headers: {
          'problemId': problemId.toString(),
        },
        isMultipart: true,
        files: [file],
      );

      if (response != null) {
        log('Problem successfully repeated with image');
        await fetchFolderContent(_currentFolder!.folderId);
        await moveToFolder(_currentFolder!.folderId);

      } else {
        throw Exception('Failed to repeat problem with image');
      }
    } else {
      // solveImage가 null인 경우, 일반 POST 요청으로 전송
      final response = await httpService.sendRequest(
        method: 'POST',
        url: '${AppConfig.baseUrl}/api/problem/repeat',
        headers: {
          'problemId': problemId.toString(),
        },
        isMultipart: false,
      );

      if (response != null) {
        log('Problem successfully repeated without image');
        await fetchFolderContent(_currentFolder!.folderId);
      } else {
        throw Exception('Failed to repeat problem without image');
      }
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
    _currentProblems.sortByName();
    sortOption = 'name';
  }

  void sortProblemsByNewest() {
    _currentProblems.sortByNewest();
    sortOption = 'newest';
  }

  void sortProblemsByOldest() {
    _currentProblems.sortByOldest();
    sortOption = 'oldest';
  }

  List<int> getProblemIds() {
    return _currentProblems.map((problem) => problem.problemId).toList();
  }

  Future<ProblemModel?> getProblemDetails(int? problemId) async {
    var problemDetails =
    _currentProblems.firstWhere((problem) => problem.problemId == problemId);

    if (problemDetails != null) {
      return problemDetails;
    } else {
      throw Exception('Problem with ID $problemId not found');
    }
  }
}
