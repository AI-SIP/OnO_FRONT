import '../Model/Cosmetic/CosmeticLoadoutModel.dart';

/// 프로필 사진을 안 올린 사람 자리에 세울 그림.
///
/// 예전에는 최초 진입 가이드의 마지막 장(`GuideScreen5.svg`)을 돌려썼다.
/// 가이드 화면 그림이 프로필 자리에 서 있는 것이라 이 앱의 것이 아니었다.
/// **맨 개구리**로 바꾼다. 사진을 안 올렸으면 어디서든 개구리가 나온다.
///
/// 내 프로필과 남의 프로필은 이렇게 갈린다.
///
/// - **내 프로필**: `ProfileAvatar` 에 `frogLayers` 를 넘기므로 내가 꾸민
///   모습이 나온다.
/// - **스터디룸에서 보는 남**: 그 사람이 무엇을 입었는지 서버가 내려주지
///   않아서 `frogLayers` 를 넘기지 않는다. 그래서 이 맨 개구리가 나온다.
class ProfileImageDefaults {
  /// 개구리 본체 한 장. 두 군데에 적어 두지 않으려고
  /// [CosmeticLoadoutModel.defaultBaseImageUrl] 을 그대로 쓴다.
  static const String assetPath = CosmeticLoadoutModel.defaultBaseImageUrl;
}
