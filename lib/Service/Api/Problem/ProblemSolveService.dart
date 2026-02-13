import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../Config/AppConfig.dart';
import '../../../Model/Problem/ProblemSolveModel.dart';
import '../../../Model/Problem/ProblemSolveRegisterDto.dart';
import '../../../Model/Problem/ProblemSolveUpdateDto.dart';
import '../HttpService.dart';

class ProblemSolveService {
  final HttpService httpService = HttpService();
  final baseUrl = "${AppConfig.baseUrl}/api/problem-solves";

  // 특정 복습 기록 조회
  Future<ProblemSolveModel> getProblemSolve(int problemSolveId) async {
    final data = await httpService.sendRequest(
      method: 'GET',
      url: '$baseUrl/$problemSolveId',
    );

    return ProblemSolveModel.fromJson(data as Map<String, dynamic>);
  }

  // 특정 문제의 모든 복습 기록 조회
  Future<List<ProblemSolveModel>> getProblemSolvesByProblemId(
      int problemId) async {
    final data = await httpService.sendRequest(
      method: 'GET',
      url: '$baseUrl/problem/$problemId',
    ) as List<dynamic>;

    return data
        .map((d) => ProblemSolveModel.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  // 사용자의 모든 복습 기록 조회
  Future<List<ProblemSolveModel>> getUserProblemSolves() async {
    final data = await httpService.sendRequest(
      method: 'GET',
      url: '$baseUrl/user',
    ) as List<dynamic>;

    return data
        .map((d) => ProblemSolveModel.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  // 특정 문제의 복습 기록 개수 조회
  Future<int> getProblemSolveCountByProblemId(int problemId) async {
    return await httpService.sendRequest(
      method: 'GET',
      url: '$baseUrl/problem/$problemId/count',
    ) as int;
  }

  // 사용자의 총 복습 기록 개수 조회
  Future<int> getUserProblemSolveCount() async {
    return await httpService.sendRequest(
      method: 'GET',
      url: '$baseUrl/user/count',
    ) as int;
  }

  // 복습 기록 생성
  Future<int> createProblemSolve(ProblemSolveRegisterDto registerDto) async {
    return await httpService.sendRequest(
      method: 'POST',
      url: baseUrl,
      body: registerDto.toJson(),
    ) as int;
  }

  // 복습 기록 이미지 업로드
  Future<void> uploadProblemSolveImages({
    required int problemSolveId,
    required List<File> images,
  }) async {
    // File 리스트를 MultipartFile 리스트로 변환
    final List<http.MultipartFile> multipartFiles = [];
    for (var imageFile in images) {
      multipartFiles.add(
        await http.MultipartFile.fromPath(
          'images', // 서버의 @RequestParam 이름과 동일
          imageFile.path,
        ),
      );
    }

    await httpService.sendRequest(
      method: 'POST',
      url: '$baseUrl/$problemSolveId/images',
      isMultipart: true,
      files: multipartFiles,
    );
  }

  // 복습 기록 수정
  Future<void> updateProblemSolve(ProblemSolveUpdateDto updateDto) async {
    await httpService.sendRequest(
      method: 'PATCH',
      url: baseUrl,
      body: updateDto.toJson(),
    );
  }

  // 복습 기록 삭제
  Future<void> deleteProblemSolve(int practiceRecordId) async {
    await httpService.sendRequest(
      method: 'DELETE',
      url: '$baseUrl/$practiceRecordId',
    );
  }
}
