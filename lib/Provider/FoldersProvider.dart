import 'dart:convert';
import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:ono/GlobalModule/Util/HttpService.dart';
import 'package:ono/GlobalModule/Util/ProblemSorting.dart';
import 'package:ono/GlobalModule/Util/ReviewHandler.dart';
import 'package:ono/Model/FolderThumbnailModel.dart';
import 'package:ono/Model/TemplateType.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../Config/AppConfig.dart';
import '../Model/FolderModel.dart';
import '../Model/ProblemModel.dart';
import '../Model/ProblemRegisterModel.dart';
import '../Model/ProblemRegisterModelV2.dart';
import 'TokenProvider.dart';
import 'package:http/http.dart' as http;

class FoldersProvider with ChangeNotifier {
  FolderModel? _currentFolder;
  List<FolderModel> _folders = [];
  List<ProblemModel> _problems = [];
  final TokenProvider tokenProvider = TokenProvider();
  final ReviewHandler reviewHandler = ReviewHandler();
  final HttpService httpService = HttpService();

  int? currentFolderId;
  String sortOption = 'newest';

  FolderModel? get currentFolder => _currentFolder;
  List<ProblemModel> get problems => List.unmodifiable(_problems);

  Future<void> fetchAllFolderContents() async {
    try {
      final response = await httpService.sendRequest(
        method: 'GET',
        url: '${AppConfig.baseUrl}/api/folder',
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(utf8.decode(response.bodyBytes));

        _folders = jsonResponse.map((folderData) => FolderModel.fromJson(folderData)).toList();

        _folders.forEach((folder) {
          log('Folder ID: ${folder.folderId}');
          log('Folder Name: ${folder.folderName}');
          log('Parent Folder: ${folder.parentFolder?.folderName ?? "No Parent"}');
          log('problems: ');
          folder.problems.forEach((problem){log('${problem.problemId}, ');});
          log('Number of Problems: ${folder.problems.length}');
          log('Number of Subfolders: ${folder.subFolders.length}');
          log('Created At: ${folder.createdAt}');
          log('Updated At: ${folder.updateAt}');
          log('-----------------------------------------');
        });

        // 루트 폴더 설정
        _currentFolder = _folders.firstWhere(
              (folder) => folder.parentFolder == null,
        );

        _problems = _currentFolder!.problems;

        notifyListeners();
      } else {
        throw Exception('Failed to load RootFolderContents');
      }
    } catch (error, stackTrace) {
      log('Error fetching root folder contents: $error');
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
  }

  Future<void> fetchRootFolderContents() async {
    try {
      final response = await httpService.sendRequest(
        method: 'GET',
        url: '${AppConfig.baseUrl}/api/folder/root',
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
        throw Exception('Failed to load RootFolderContents');
      }
    } catch (error, stackTrace) {
      log('Error fetching root folder contents: $error');
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
  }

  Future<void> clearFolderContents() async{
    _currentFolder = null;
    _problems = [];

    notifyListeners();
  }

  Future<void> fetchCurrentFolderContents() async {
    try {
      final response = await httpService.sendRequest(
        method: 'GET',
        url: '${AppConfig.baseUrl}/api/folder/$currentFolderId',
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        _currentFolder = FolderModel.fromJson(jsonResponse);
        _problems = (jsonResponse['problems'] as List)
            .map((e) => ProblemModel.fromJson(e))
            .toList();
        currentFolderId = jsonResponse['folderId'];
        sortProblemsByOption(sortOption);
        notifyListeners();
      } else {
        throw Exception('Failed to load CurrentFolderContents');
      }
    } catch (error, stackTrace) {
      log('Error fetching current folder contents: $error');
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
  }

  // 폴더 내용 로드 (특정 폴더 ID로)
  Future<void> fetchFolderContents({required int folderId}) async {

    if (currentFolderId == folderId) {
      log('Already viewing the current folder: $folderId');
      return;
    }

    try {
      final response = await httpService.sendRequest(
        method: 'GET',
        url: '${AppConfig.baseUrl}/api/folder/$folderId',
      );

      if (response.statusCode == 200) {
        final folderData = json.decode(utf8.decode(response.bodyBytes));
        final updatedFolder = FolderModel.fromJson(folderData);

        // 기존 데이터를 업데이트
        final index = _folders.indexWhere((folder) => folder.folderId == folderId);
        if (index != -1) {
          _folders[index] = updatedFolder;
        } else {
          _folders.add(updatedFolder);
        }

        notifyListeners();
      } else {
        throw Exception('Failed to fetch folder by ID');
      }
    } catch (error, stackTrace) {
      log('Error fetching folder by ID: $error');
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
  }

  Future<List<FolderThumbnailModel>> fetchAllFolderThumbnails() async {
    try {
      final response = await httpService.sendRequest(
        method: 'GET',
        url: '${AppConfig.baseUrl}/api/folder/folders',
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        log('AllFolderThumbnail Fetch Complete : $jsonResponse');

        return (jsonResponse as List)
            .map((e) => FolderThumbnailModel.fromJson(e))
            .toList();
      } else {
        throw Exception('Failed to load AllFolderThumbnails');
      }
    } catch (error, stackTrace) {
      log('Error fetching all folder thumbnails: $error');
      await Sentry.captureException(error, stackTrace: stackTrace);
      return [];
    }
  }

  // 폴더 생성
  Future<void> createFolder(String folderName, {int? parentFolderId}) async {
    try {
      final response = await httpService.sendRequest(
        method: 'POST',
        url: '${AppConfig.baseUrl}/api/folder',
        body: {
          'folderName': folderName,
          'parentFolderId': parentFolderId ?? currentFolderId,
        },
      );

      if (response.statusCode == 200) {
        log('Folder successfully created');
        await fetchCurrentFolderContents();
      } else {
        throw Exception('Failed to create folder');
      }
    } catch (error, stackTrace) {
      log('Error creating folder: $error');
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
  }

  Future<void> updateFolder(String? newName, int? folderId, int? parentId) async {
    try {
      final response = await httpService.sendRequest(
        method: 'PATCH',
        url: '${AppConfig.baseUrl}/api/folder/$folderId',
        body: {
          'folderName': newName,
          'parentFolderId': parentId,
        },
      );

      if (response.statusCode == 200) {
        log('Folder name successfully updated to $newName');
        await fetchCurrentFolderContents();
      } else {
        throw Exception('Failed to update folder name');
      }
    } catch (error, stackTrace) {
      log('Error updating folder name: $error');
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
  }

  // 폴더 삭제
  Future<void> deleteFolder(int folderId) async {

    try {
      final response = await httpService.sendRequest(
        method: 'DELETE',
        url: '${AppConfig.baseUrl}/api/folder/$folderId',
      );

      if (response.statusCode == 200) {
        log('Folder successfully deleted');
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        int parentFolderId = jsonResponse['folderId'] as int;
        await fetchCurrentFolderContents();
      } else {
        throw Exception('Failed to delete folder');
      }
    } catch (error, stackTrace) {
      log('Error deleting folder: $error');
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
  }

  // 상위 폴더로 이동
  Future<void> moveToParentFolder(int? parentFolderId) async {
    await fetchFolderContents(folderId: parentFolderId ?? -1);
  }

  // 문제 이미지 미리 전송
  Future<Map<String, dynamic>?> uploadProblemImage(XFile? problemImage) async{
    try {
      final response = await httpService.sendRequest(
        method: 'POST',
        url: '${AppConfig.baseUrl}/api/process/problemImage',
        isMultipart: true,
        files: [await http.MultipartFile.fromPath('problemImage', problemImage!.path)],
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        log('success for upload problem image: ${jsonResponse['problemImageUrl']}');
        return {
          'problemId': jsonResponse['problemId'],
          'problemImageUrl': jsonResponse['problemImageUrl'],
        };
      } else {
        throw Exception('Failed to upload problem image');
      }
    } catch (error, stackTrace) {
      log('Error uploading problem image: $error');
      await Sentry.captureException(error, stackTrace: stackTrace);
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
    try {
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

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        log('image process result : ${jsonResponse['processImageUrl']}');
        return jsonResponse['processImageUrl'];
      } else {
        log('Failed to fetch process image URL: ${response.body}');
        return null;
      }
    } catch (error) {
      log('Error fetching process image URL: $error');
      return null;
    }
  }

  Future<String?> fetchAnalysisResult(String? problemImageUrl) async {
    try {
      final response = await httpService.sendRequest(
        method: 'POST', // 'GET'에서 'POST'로 변경
        url: '${AppConfig.baseUrl}/api/process/analysis',
        body: {'problemImageUrl': problemImageUrl},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        log('analysis : ${jsonResponse['analysis']}');
        return jsonResponse['analysis'];
      } else {
        log('Failed to fetch analysis result: ${response.body}');
        return null;
      }
    } catch (error) {
      log('Error fetching analysis result: $error');
      return null;
    }
  }

  Future<void> submitProblem(
      ProblemRegisterModel problemData, BuildContext context) async {

    try {
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
        'folderId': (problemData.folderId ?? currentFolderId).toString(),
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
        url: '${AppConfig.baseUrl}/api/problem/V2',
        isMultipart: true,
        files: files,
        body: requestBody,
      );

      if (response.statusCode == 200) {
        log('Problem successfully submitted');
        await fetchCurrentFolderContents();

        int userProblemCount = await getUserProblemCount();
        if (userProblemCount > 0 && userProblemCount % 10 == 0) {
          reviewHandler.requestReview(context);
        }
      } else {
        throw Exception('Failed to submit problem');
      }
    } catch (error, stackTrace) {
      log('Error submitting problem: $error');
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
  }

  Future<void> submitProblemV2(
      ProblemRegisterModelV2 problemData, BuildContext context) async {

    try {
      final files = <http.MultipartFile>[];

      if (problemData.problemImage != null) {
        files.add(await http.MultipartFile.fromPath('problemImage', problemData.problemImage!.path));
      }
      if (problemData.answerImage != null) {
        files.add(await http.MultipartFile.fromPath('answerImage', problemData.answerImage!.path));
      }

      final requestBody = {
        'problemId': problemData.problemId.toString(),
        'solvedAt': (problemData.solvedAt ?? DateTime.now()).toIso8601String(),
        'reference': problemData.reference ?? "",
        'memo': problemData.memo ?? "",
        'folderId': (problemData.folderId ?? currentFolderId).toString(),
      };

      final response = await httpService.sendRequest(
        method: 'POST',
        url: '${AppConfig.baseUrl}/api/problem/V2',
        isMultipart: true,
        files: files,
        body: requestBody,
      );

      if (response.statusCode == 200) {
        log('Problem successfully submitted');

        await fetchCurrentFolderContents();

        int userProblemCount = await getUserProblemCount();
        if (userProblemCount > 0 && userProblemCount % 10 == 0) {
          reviewHandler.requestReview(context);
        }
      } else {
        throw Exception('Failed to submit problem');
      }
    } catch (error, stackTrace) {
      log('Error submitting problem: $error');
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
  }

  Future<int> getUserProblemCount() async {

    try {
      final response = await httpService.sendRequest(
        method: 'GET',
        url: '${AppConfig.baseUrl}/api/user/problemCount',
      );

      if (response.statusCode == 200) {
        int userProblemCount = int.parse(response.body);
        log('User problem count: $userProblemCount');
        return userProblemCount;
      } else {
        throw Exception('Failed to get user problem count');
      }
    } catch (error, stackTrace) {
      log('Error fetching user problem count: $error');
      await Sentry.captureException(error, stackTrace: stackTrace);
      return 0;
    }
  }

  Future<void> updateProblem(ProblemRegisterModel problemData) async {

    try {
      final files = <http.MultipartFile>[];
      if (problemData.answerImage != null) {
        files.add(await http.MultipartFile.fromPath('answerImage', problemData.answerImage!.path));
      }

      final response = await httpService.sendRequest(
        method: 'PATCH',
        url: '${AppConfig.baseUrl}/api/problem',
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

      if (response.statusCode == 200) {
        log('Problem successfully updated');

        await fetchCurrentFolderContents();
      } else {
        throw Exception('Failed to update problem');
      }
    } catch (error, stackTrace) {
      log('Error updating problem: $error');
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
  }

  Future<bool> deleteProblem(int problemId) async {
    try {
      final response = await httpService.sendRequest(
        method: 'DELETE',
        url: '${AppConfig.baseUrl}/api/problem',
        headers: {
          'problemId': problemId.toString(),
        },
      );

      if (response.statusCode == 200) {
        log('Problem successfully deleted');
        await fetchCurrentFolderContents();
        return true;
      } else {
        throw Exception('Failed to delete problem');
      }
    } catch (error, stackTrace) {
      log('Error deleting problem: $error');
      await Sentry.captureException(error, stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> addRepeatCount(int problemId, XFile? solveImage) async {
    try {
      if (solveImage != null) {
        // Multipart 파일로 변환
        final file = await http.MultipartFile.fromPath('solveImage', solveImage.path);

        // Multipart 요청 생성
        final response = await httpService.sendRequest(
          method: 'POST',
          url: '${AppConfig.baseUrl}/api/problem/repeat',
          headers: {
            'problemId': problemId.toString(),
          },
          isMultipart: true,
          files: [file],
        );

        if (response.statusCode == 200) {
          log('Problem successfully repeated with image');
          await fetchCurrentFolderContents();
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

        if (response.statusCode == 200) {
          log('Problem successfully repeated without image');
          await fetchCurrentFolderContents();
        } else {
          throw Exception('Failed to repeat problem without image');
        }
      }
    } catch (error, stackTrace) {
      log('Error deleting problem: $error');
      await Sentry.captureException(error, stackTrace: stackTrace);
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
    return _problems.map((problem) => problem.problemId).toList();
  }

  Future<ProblemModel?> getProblemDetails(int? problemId) async {
    try {
      var problemDetails =
      _problems.firstWhere((problem) => problem.problemId == problemId);

      if (problemDetails != null) {
        return problemDetails;
      } else {
        throw Exception('Problem with ID $problemId not found');
      }
    } catch (error, stackTrace) {
      log('Error fetching problem details for ID $problemId: $error');
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
