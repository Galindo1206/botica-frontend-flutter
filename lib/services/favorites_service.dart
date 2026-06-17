import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const _favoritesKey = 'favorite_product_ids';

  Future<Set<int>> getFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_favoritesKey) ?? [];
    return values.map(int.tryParse).whereType<int>().toSet();
  }

  Future<Set<int>> toggleFavorite(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavoriteIds();

    if (favorites.contains(productId)) {
      favorites.remove(productId);
    } else {
      favorites.add(productId);
    }

    await prefs.setStringList(
      _favoritesKey,
      favorites.map((id) => id.toString()).toList(),
    );
    return favorites;
  }
}
