import 'package:ono/Config/AppConfig.dart';
import 'package:ono/Model/Tag/TagModel.dart';
import 'package:ono/Service/Api/HttpService.dart';

class TagService {
  final HttpService _httpService = HttpService();
  final String _baseUrl = '${AppConfig.baseUrl}/api/tags';

  Future<List<TagModel>> getMyTags() async {
    final data = await _httpService.sendRequest(
      method: 'GET',
      url: _baseUrl,
    ) as List<dynamic>;

    return data
        .map((e) => TagModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TagModel> createTag(String name) async {
    final data = await _httpService.sendRequest(
      method: 'POST',
      url: _baseUrl,
      body: {'name': name},
    ) as Map<String, dynamic>;

    return TagModel.fromJson(data);
  }

  Future<void> deleteTag(int tagId) async {
    await _httpService.sendRequest(
      method: 'DELETE',
      url: '$_baseUrl/$tagId',
    );
  }
}
