class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.kunanfarma.com/api',
  );

  static String get appUrl => baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

  static String storageUrl(String path) {
    if (path.startsWith('http')) return path;
    final normalized = path.replaceFirst(RegExp(r'^/+'), '');
    if (normalized.startsWith('storage/')) return '$appUrl/$normalized';
    return '$appUrl/storage/$normalized';
  }
}
