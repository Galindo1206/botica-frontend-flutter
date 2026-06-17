import '../core/network/api_client.dart';
import '../models/publication_model.dart';

class PublicationRepository {
  final ApiClient _apiClient;

  PublicationRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<List<Publication>> getPublications() async {
    final data = await _apiClient.get('/publications', authenticated: false);
    final publicationsJson = data is Map<String, dynamic> ? data['data'] : data;

    if (publicationsJson is! List) return [];

    return publicationsJson
        .whereType<Map<String, dynamic>>()
        .map(Publication.fromJson)
        .where((publication) => publication.isActive)
        .toList();
  }
}
