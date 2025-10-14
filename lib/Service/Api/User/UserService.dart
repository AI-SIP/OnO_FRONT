import 'package:ono/Config/AppConfig.dart';
import 'package:ono/Model/User/UserInfoModel.dart';
import 'package:ono/Model/User/UserRegisterModel.dart';
import 'package:ono/Service/Api/HttpService.dart';

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

  Future<UserInfoModel> fetchUserInfo() async {
    final data = await httpService.sendRequest(
      method: 'GET',
      url: '${AppConfig.baseUrl}/api/users',
    );

    return UserInfoModel.fromJson(data);
  }

  Future<void> updateUserProfile(UserRegisterModel? userRegisterModel) async {
    await httpService.sendRequest(
      method: 'PATCH',
      url: '${AppConfig.baseUrl}/api/users',
      body: userRegisterModel?.toJson(),
    );
  }

  Future<void> logoutAccount() async {
    await httpService.sendRequest(
      method: 'POST',
      url: '${AppConfig.baseUrl}/api/auth/logout',
    );
  }

  Future<void> deleteAccount() async {
    await httpService.sendRequest(
      method: 'DELETE',
      url: '${AppConfig.baseUrl}/api/users',
    );
  }
}
