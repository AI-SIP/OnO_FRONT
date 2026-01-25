import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:ono/Model/Problem/ProblemAnalysisModel.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Model/Problem/ProblemRegisterModel.dart';

import '../../../Config/AppConfig.dart';
import '../HttpService.dart';

class ProblemService {
  final HttpService httpService = HttpService();
  final baseUrl = "${AppConfig.baseUrl}/api/problems";

  Future<ProblemModel> getProblem(int? problemId) async {
    final data = await httpService.sendRequest(
      method: 'GET',
      url: '$baseUrl/$problemId',
    );

    return ProblemModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<ProblemModel>> getAllProblems() async {
    final data = await httpService.sendRequest(
      method: 'GET',
      url: '$baseUrl/user',
    ) as List<dynamic>;

    return data
        .map((d) => ProblemModel.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  Future<int> getProblemCount() async {
    return await httpService.sendRequest(
      method: 'GET',
      url: '$baseUrl/problemCount',
    ) as int;
  }

  Future<int> registerProblem(ProblemRegisterModel problemRegisterModel) async {
    return await httpService.sendRequest(
      method: 'POST',
      url: baseUrl,
      body: problemRegisterModel.toJson(),
    ) as int;
  }

  Future<void> registerProblemImageData({
    required int problemId,
    required List<File> problemImages,
    required List<String> problemImageTypes,
  }) async {
    // File 리스트를 MultipartFile 리스트로 변환
    final List<http.MultipartFile> multipartFiles = [];
    for (var imageFile in problemImages) {
      multipartFiles.add(
        await http.MultipartFile.fromPath(
          'problemImages', // 서버의 @RequestParam 이름과 동일
          imageFile.path,
        ),
      );
    }

    await httpService.sendRequest(
      method: 'POST',
      url: '$baseUrl/$problemId/imageData',
      isMultipart: true,
      files: multipartFiles,
      body: {
        'problemImageTypes': problemImageTypes,
      },
    );
  }

  Future<void> updateProblemInfo(
      ProblemRegisterModel problemRegisterModel) async {
    await httpService.sendRequest(
      method: 'PATCH',
      url: '$baseUrl/info',
      body: problemRegisterModel.toJson(),
    );
  }

  Future<void> updateProblemPath(
      ProblemRegisterModel problemRegisterModel) async {
    await httpService.sendRequest(
      method: 'PATCH',
      url: '$baseUrl/path',
      body: problemRegisterModel.toJson(),
    );
  }

  Future<void> updateProblemImageData(
      ProblemRegisterModel problemRegisterModel) async {
    await httpService.sendRequest(
      method: 'PATCH',
      url: '$baseUrl/imageData',
      body: problemRegisterModel.toJson(),
    );
  }

  Future<void> deleteProblems(List<int> problemIdList) async {
    await httpService.sendRequest(
      method: 'DELETE',
      url: baseUrl,
      body: {'deleteProblemIdList': problemIdList},
    );
  }

  Future<void> deleteUserProblems() async {
    await httpService.sendRequest(
      method: 'DELETE',
      url: '$baseUrl/all',
    );
  }

  Future<void> deleteProblemImageData(String imageUrl) async {
    await httpService.sendRequest(
      method: 'DELETE',
      url: '$baseUrl/imageData',
      queryParams: {
        'imageUrl': imageUrl,
      },
    );
  }

  Future<ProblemAnalysisModel> getProblemAnalysis(int problemId) async {
    final data = await httpService.sendRequest(
      method: 'GET',
      url: '$baseUrl/$problemId/analysis',
    );

    return ProblemAnalysisModel.fromJson(data as Map<String, dynamic>);
  }
}
