import 'package:ono/Config/AppConfig.dart';
import 'package:ono/Model/User/UserRegisterModel.dart';
import 'package:ono/Service/Network/HttpService.dart';
import 'package:http/http.dart' as http;

class UserService {
  final HttpService httpService = HttpService();

  Future<dynamic> signInWithGuest() async {

    return await httpService.sendRequest(
      method: 'POST',
      url: '${AppConfig.baseUrl}/api/auth/signup/guest',
      requiredToken: false,
    );
  }

  Future<dynamic> signInWithMember(UserRegisterModel? userRegisterModel) async {
    if (userRegisterModel == null) {
      throw Exception("소셜 로그인 실패. 잘못된 유저 정보입니다.");
    }

    return await httpService.sendRequest(
      method: 'POST',
      url: '${AppConfig.baseUrl}/api/auth/signup/member',
      body: userRegisterModel.toJson(),
      requiredToken: false,
    );
  }

  Future<dynamic> fetchUserInfo() {
    return httpService.sendRequest(
      method: 'GET',
      url: '${AppConfig.baseUrl}/api/users',
    );
  }

  Future<int> fetchProblemCount() async {
    final data = await httpService.sendRequest(
      method: 'GET',
      url: '${AppConfig.baseUrl}/api/problems/problemCount',
    );
    return data as int;
  }

  Future<void> updateUserProfile(Map<String, dynamic> payload) {
    return httpService.sendRequest(
      method: 'PATCH',
      url: '${AppConfig.baseUrl}/api/users',
      body: payload,
    );
  }

  Future<void> deleteAccount() {
    return httpService.sendRequest(
      method: 'DELETE',
      url: '${AppConfig.baseUrl}/api/users',
    );
  }
}
