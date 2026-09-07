import 'package:http/http.dart' as http;
import 'package:ono/Config/AppConfig.dart';
import 'package:ono/Model/User/UserInfoModel.dart';
import 'package:ono/Model/User/UserRegisterModel.dart';
import 'package:ono/Service/Api/HttpService.dart';

class UserService {
  final HttpService httpService;

  UserService({HttpService? httpService})
      : httpService = httpService ?? HttpService();

  Future<dynamic> signInWithGuest() async {
    return await httpService.sendRequest(
      method: 'POST',
      url: '${AppConfig.baseUrl}/api/auth/signup/guest',
      requiredToken: false,
      showErrorSnackBar: false,
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
      showErrorSnackBar: false,
    );
  }

  Future<UserInfoModel> fetchUserInfo({bool showErrorSnackBar = true}) async {
    final data = await httpService.sendRequest(
      method: 'GET',
      url: '${AppConfig.baseUrl}/api/users',
      showErrorSnackBar: showErrorSnackBar,
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

  Future<UserInfoModel> updateUserProfileImage(String imagePath) async {
    final data = await httpService.sendRequest(
      method: 'PATCH',
      url: '${AppConfig.baseUrl}/api/users/me/profile-image',
      isMultipart: true,
      files: [
        await http.MultipartFile.fromPath('profileImage', imagePath),
      ],
    );

    return UserInfoModel.fromJson(data);
  }

  Future<UserInfoModel> updateUserProfileImageUrl(
      String profileImageUrl) async {
    final data = await httpService.sendRequest(
      method: 'PATCH',
      url: '${AppConfig.baseUrl}/api/users/me/profile-image-url',
      body: {
        'profileImageUrl': profileImageUrl,
      },
    );

    return UserInfoModel.fromJson(data);
  }

  Future<UserInfoModel> deleteUserProfileImage() async {
    final data = await httpService.sendRequest(
      method: 'DELETE',
      url: '${AppConfig.baseUrl}/api/users/me/profile-image',
    );

    return UserInfoModel.fromJson(data);
  }

  Future<void> updateNotificationSettings(bool enabled) async {
    await httpService.sendRequest(
      method: 'PATCH',
      url: '${AppConfig.baseUrl}/api/users/notification-settings',
      body: {'notificationEnabled': enabled},
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
