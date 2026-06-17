import '../models/publication_model.dart';
import '../repositories/publication_repository.dart';

class PublicationService {
  final PublicationRepository _publicationRepository;

  PublicationService({PublicationRepository? publicationRepository})
    : _publicationRepository = publicationRepository ?? PublicationRepository();

  Future<List<Publication>> getPublications() {
    return _publicationRepository.getPublications();
  }
}
