import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  Future<void> saveUserInfo(int userId, String userName, String userEmail) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', userId);
    await prefs.setString('userName', userName);
    await prefs.setString('userEmail', userEmail);
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');
    String? userName = prefs.getString('userName');
    String? userEmail = prefs.getString('userEmail');
    log('userId : ${userId}, userName : ${userName}, userEmail : ${userEmail}');

    if (userId != null && userName != null && userEmail != null) {
      return {
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
      };
    } else {
      print('No user info found'); // 로그 추가
      throw Exception('No user info found');
    }
  }

  Future<void> clearUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('problems');
  }
}