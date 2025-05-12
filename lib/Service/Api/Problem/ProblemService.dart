import 'package:ono/Model/Problem/ProblemImageDataRegisterModel.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Model/Problem/ProblemRegisterModel.dart';
import 'package:ono/Model/Problem/ProblemRepeatRegisterModel.dart';

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

  Future<void> registerProblem(
      ProblemRegisterModel problemRegisterModel) async {
    await httpService.sendRequest(
      method: 'POST',
      url: baseUrl,
      body: problemRegisterModel.toJson(),
    );
  }

  Future<void> registerProblemImageData(
      ProblemImageDataRegisterModel problemImageDataRegisterModel) async {
    await httpService.sendRequest(
      method: 'POST',
      url: '$baseUrl/imageData',
      body: problemImageDataRegisterModel.toJson(),
    );
  }

  Future<void> repeatProblem(
      ProblemRepeatRegisterModel problemRepeatRegisterModel) async {
    await httpService.sendRequest(
      method: 'POST',
      url: '$baseUrl/repeat',
      body: problemRepeatRegisterModel.toJson(),
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
