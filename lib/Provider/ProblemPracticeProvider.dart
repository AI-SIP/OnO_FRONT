import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ono/Model/ProblemPracticeModel.dart';
import 'package:ono/Model/ProblemPracticeRegisterModel.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../Config/AppConfig.dart';
import '../GlobalModule/Util/HttpService.dart';
import '../Model/ProblemModel.dart';
import 'TokenProvider.dart';

class ProblemPracticeProvider with ChangeNotifier{

  List<ProblemModel> _problems = [];
  final TokenProvider tokenProvider = TokenProvider();
  final HttpService httpService = HttpService();

  Future<List<ProblemPracticeModel>?> fetchAllPracticeThumbnails() async {
    try {
      final response = await httpService.sendRequest(
        method: 'GET',
        url: '${AppConfig.baseUrl}/api/problem/practice/all',
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));

        log('fetch all practice thumbnails result: $jsonResponse');

        List<ProblemPracticeModel> practiceThumbnails = (jsonResponse as List)
            .map((e) => ProblemPracticeModel.fromJson(e))
            .toList();

        log('Practice contents fetched : ${practiceThumbnails.length} problem practices');
        return practiceThumbnails;
      } else {
        throw Exception('Failed to load RootFolderContents');
      }
    } catch (error, stackTrace) {
      log('Error fetching root folder contents: $error');
      await Sentry.captureException(error, stackTrace: stackTrace);

      return null;
    }
  }

  Future<bool> submitPracticeProblems(ProblemPracticeRegisterModel problemPracticeRegisterModel) async {
    try {
      log('practice problem list: ${problemPracticeRegisterModel.registerProblemIds.toString()}');
      log('practice problem title: ${problemPracticeRegisterModel.practiceTitle}');

      final response = await httpService.sendRequest(
        method: 'POST',
        url: '${AppConfig.baseUrl}/api/problem/practice',
        //headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'practiceTitle': problemPracticeRegisterModel.practiceTitle.toString(),
          'registerProblemIds': problemPracticeRegisterModel.registerProblemIds.map((id) => id.toString()).toList(),
        },
      );

      log('response: ${response.body}');

      if(response.statusCode == 200){
        return true;
      } else{
        return false;
      }
    } catch (error, stackTrace) {
      log('Error submitting selected problems: $error');
      await Sentry.captureException(error, stackTrace: stackTrace);

      return false;
    }
  }
}