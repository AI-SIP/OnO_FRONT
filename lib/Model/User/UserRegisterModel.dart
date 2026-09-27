class UserRegisterModel {
  final String? email;
  final String? name;
  final String? identifier;
  final String? platform;
  final String? password;
  final String? profileImageUrl;

  UserRegisterModel({
    this.email = '',
    this.name = '',
    this.identifier = '',
    this.platform = '',
    this.password = '',
    this.profileImageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'identifier': identifier,
      'platform': platform,
      'password': password,
      'profileImageUrl': profileImageUrl,
    };
  }
}
