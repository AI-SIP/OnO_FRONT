import 'package:ono/Model/Problem/ProblemImageDataRegisterModel.dart';
import 'package:ono/Model/Problem/ProblemRegisterModel.dart';

import '../../../Config/AppConfig.dart';
import '../HttpService.dart';

class ProblemService {
  final HttpService httpService = HttpService();
  final baseUrl = "${AppConfig.baseUrl}/api/problems";

  Future<dynamic> getProblem(int? problemId) async {
    return httpService.sendRequest(
      method: 'GET',
      url: '$baseUrl/$problemId',
    );
  }

  Future<dynamic> getAllProblems() async {
    return httpService.sendRequest(
      method: 'GET',
      url: '$baseUrl/user',
    );
  }

  Future<int> getProblemCount() async {
    return httpService.sendRequest(
      method: 'GET',
      url: '$baseUrl/problemCount',
    ) as int;
  }

  Future<void> registerProblem(
      ProblemRegisterModel problemRegisterModel) async {
    httpService.sendRequest(
      method: 'POST',
      url: baseUrl,
      body: problemRegisterModel.toJson(),
    );
  }

  Future<void> registerProblemImageData(
      ProblemImageDataRegisterModel problemImageDataRegisterModel) async {
    httpService.sendRequest(
      method: 'POST',
      url: '$baseUrl/imageData',
      body: problemImageDataRegisterModel.toJson(),
    );
  }

  Future<void> updateProblemInfo(
      ProblemRegisterModel problemRegisterModel) async {
    httpService.sendRequest(
      method: 'PATCH',
      url: '$baseUrl/info',
      body: problemRegisterModel.toJson(),
    );
  }

  Future<void> updateProblemPath(
      ProblemRegisterModel problemRegisterModel) async {
    httpService.sendRequest(
      method: 'PATCH',
      url: '$baseUrl/path',
      body: problemRegisterModel.toJson(),
    );
  }

  Future<void> updateProblemImageData(
      ProblemRegisterModel problemRegisterModel) async {
    httpService.sendRequest(
      method: 'PATCH',
      url: '$baseUrl/imageData',
      body: problemRegisterModel.toJson(),
    );
  }

  Future<void> deleteProblems(List<int> problemIdList) async {
    await httpService.sendRequest(
      method: 'DELETE',
      url: baseUrl,
      body: {'problemIdList': problemIdList},
    );
  }

  Future<void> deleteUserProblems() async {
    await httpService.sendRequest(
      method: 'DELETE',
      url: '$baseUrl/all',
    );
  }

  Future<void> deleteProblemImageData(String imageUrl) async {
    httpService.sendRequest(
      method: 'DELETE',
      url: '$baseUrl/imageData',
      queryParams: {
        'imageUrl': imageUrl,
      },
    );
  }
}
