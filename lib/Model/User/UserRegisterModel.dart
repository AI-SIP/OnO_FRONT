class UserRegisterModel {
  final String? email;
  final String? name;
  final String? identifier;
  final String? platform;
  final String? password;

  UserRegisterModel({
    this.email = '',
    this.name = '',
    this.identifier = '',
    this.platform = '',
    this.password = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'identifier': identifier,
      'platform': platform,
      'password': password,
    };
  }
}