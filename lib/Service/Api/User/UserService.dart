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
      // 토큰 갱신 후 재시도할 때 파일을 다시 읽어야 한다.
      filesBuilder: () async => [
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

  /// 로그아웃.
  ///
  /// 서버는 [refreshToken] 이 함께 와야 세션 행을 지운다. 안 보내면 액세스
  /// 토큰만 블랙리스트에 들어가고 리프레시 토큰은 그대로 살아 있어서, 기기에서
  /// 새어 나간 토큰으로 로그아웃 뒤에도 세션을 되살릴 수 있다.
  ///
  /// 토큰을 못 읽은 경우에는 null 이 온다. 그래도 요청은 보낸다. 액세스 토큰만
  /// 이라도 막는 편이 아무것도 안 하는 것보다 낫다.
  Future<void> logoutAccount({String? refreshToken}) async {
    await httpService.sendRequest(
      method: 'POST',
      url: '${AppConfig.baseUrl}/api/auth/logout',
      body: refreshToken == null ? null : {'refreshToken': refreshToken},
    );
  }

  Future<void> deleteAccount() async {
    await httpService.sendRequest(
      method: 'DELETE',
      url: '${AppConfig.baseUrl}/api/users',
    );
  }
}
