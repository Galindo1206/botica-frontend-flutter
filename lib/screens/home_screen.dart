import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/network/api_exception.dart';
import '../core/session/session_manager.dart';
import '../models/publication_model.dart';
import '../models/product_model.dart';
import '../repositories/auth_repository.dart';
import '../routes/app_routes.dart';
import '../services/category_service.dart';
import '../services/favorites_service.dart';
import '../services/product_service.dart';
import '../services/publication_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';
import 'product_detail_screen.dart';

enum ProductFilter { all, available, prescription }

enum _HomeTab { home, categories, search, favorites, account }

enum _HomeMenuAction { home, categories, search, favorites, account, logout }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService productService = ProductService();
  final CategoryService categoryService = CategoryService();
  final PublicationService publicationService = PublicationService();
  final AuthRepository authRepository = AuthRepository();
  final SessionManager sessionManager = SessionManager();
  final FavoritesService favoritesService = FavoritesService();
  final TextEditingController searchController = TextEditingController();
  Timer? _searchDebounce;

  List<Product> products = [];
  List<String> categoryNames = [];
  List<Publication> publications = [];
  Set<int> favoriteIds = {};
  bool isLoading = false;
  String? errorMessage;
  String selectedCategory = 'Todas';
  String debouncedSearchQuery = '';
  int categoryVisibleCount = 10;
  int searchVisibleCount = 10;
  ProductFilter selectedFilter = ProductFilter.all;
  _HomeTab selectedTab = _HomeTab.home;
  String? userName;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    loadCategories();
    loadPublications();
    loadProfile();
    loadFavorites();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await productService.getProducts();
      if (!mounted) return;
      setState(() {
        products = result.where((product) => product.isActive).toList();
        isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 401) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        });
        return;
      }
      setState(() {
        isLoading = false;
        errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'No pudimos cargar el catalogo. Intenta de nuevo.';
      });
    }
  }

  Future<void> loadCategories() async {
    try {
      final result = await categoryService.getCategories();
      if (!mounted) return;
      setState(() => categoryNames = result);
    } catch (_) {
      if (!mounted) return;
      setState(() => categoryNames = []);
    }
  }

  Future<void> loadPublications() async {
    try {
      final result = await publicationService.getPublications();
      if (!mounted) return;
      setState(() => publications = result.take(5).toList());
    } catch (_) {
      if (!mounted) return;
      setState(() => publications = []);
    }
  }

  void updateSearchQuery(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final normalized = value.trim();
      if (normalized == debouncedSearchQuery) return;
      setState(() {
        debouncedSearchQuery = normalized;
        searchVisibleCount = 10;
      });
    });
  }

  void clearSearchQuery() {
    _searchDebounce?.cancel();
    searchController.clear();
    if (debouncedSearchQuery.isEmpty) return;
    setState(() {
      debouncedSearchQuery = '';
      searchVisibleCount = 10;
    });
  }

  Future<void> loadProfile() async {
    final name = await sessionManager.getUserName();
    final email = await sessionManager.getUserEmail();
    if (!mounted) return;
    setState(() {
      userName = name;
      userEmail = email;
    });
  }

  Future<void> loadFavorites() async {
    final ids = await favoritesService.getFavoriteIds();
    if (!mounted) return;
    setState(() => favoriteIds = ids);
  }

  Future<void> toggleFavorite(Product product) async {
    final ids = await favoritesService.toggleFavorite(product.id);
    if (!mounted) return;
    setState(() => favoriteIds = ids);
  }

  Future<void> logout() async {
    await authRepository.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  void handleMenuAction(_HomeMenuAction action) {
    Navigator.maybePop(context);

    switch (action) {
      case _HomeMenuAction.home:
        selectTab(_HomeTab.home);
        return;
      case _HomeMenuAction.categories:
        selectTab(_HomeTab.categories);
        return;
      case _HomeMenuAction.search:
        selectTab(_HomeTab.search);
        return;
      case _HomeMenuAction.favorites:
        selectTab(_HomeTab.favorites);
        return;
      case _HomeMenuAction.account:
        selectTab(_HomeTab.account);
        return;
      case _HomeMenuAction.logout:
        logout();
        return;
    }
  }

  void selectTab(_HomeTab tab) {
    if (selectedTab == tab) return;
    setState(() => selectedTab = tab);
    switch (tab) {
      case _HomeTab.home:
        loadPublications();
        return;
      case _HomeTab.categories:
        loadCategories();
        if (!isLoading) loadProducts();
        return;
      case _HomeTab.search:
        if (!isLoading) loadProducts();
        return;
      case _HomeTab.favorites:
        loadFavorites();
        if (!isLoading) loadProducts();
        return;
      case _HomeTab.account:
        loadProfile();
        return;
    }
  }

  void openProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }

  void openPublication(Publication publication) {
    final product = publication.product;
    if (product != null) {
      openProduct(product);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Esta oferta aun no tiene producto relacionado.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void openCategory(String category) {
    setState(() {
      selectedCategory = category;
      selectedTab = _HomeTab.categories;
      categoryVisibleCount = 10;
    });
  }

  List<String> get categories {
    final fromProducts =
        products
            .map((product) => product.categoryName)
            .whereType<String>()
            .where((name) => name.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final values = {...categoryNames, ...fromProducts}.toList()..sort();
    return ['Todas', ...values];
  }

  List<Product> get searchResults {
    final query = debouncedSearchQuery.toLowerCase().trim();

    return products.where((product) {
      final matchesSearch =
          query.length < 2 ||
          product.name.toLowerCase().contains(query) ||
          (product.genericName ?? '').toLowerCase().contains(query) ||
          (product.laboratory ?? '').toLowerCase().contains(query) ||
          (product.barcode ?? '').toLowerCase().contains(query);
      final matchesFilter = switch (selectedFilter) {
        ProductFilter.all => true,
        ProductFilter.available => product.available,
        ProductFilter.prescription => product.requiresPrescription,
      };
      return matchesSearch && matchesFilter;
    }).toList();
  }

  List<Product> get categoryProducts {
    if (selectedCategory == 'Todas') return products;
    return products
        .where((product) => product.categoryName == selectedCategory)
        .toList();
  }

  List<Product> get visibleCategoryProducts =>
      categoryProducts.take(categoryVisibleCount).toList();

  List<Product> get visibleSearchResults =>
      searchResults.take(searchVisibleCount).toList();

  List<Product> get favoriteProducts =>
      products.where((product) => favoriteIds.contains(product.id)).toList();

  String get fullName {
    final value = userName?.trim();
    if (value != null && value.isNotEmpty) return value;
    return 'Usuario';
  }

  String get displayEmail {
    final value = userEmail?.trim();
    if (value != null && value.isNotEmpty) return value;
    return 'Correo no disponible';
  }

  void loadMoreCategoryProducts() {
    if (categoryVisibleCount >= categoryProducts.length) return;
    setState(() => categoryVisibleCount += 10);
  }

  void loadMoreSearchResults() {
    if (searchVisibleCount >= searchResults.length) return;
    setState(() => searchVisibleCount += 10);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: _HomeDrawer(onActionSelected: handleMenuAction),
      appBar: AppBar(
        titleSpacing: 0,
        title: const Row(
          children: [
            BrandLogo(size: 34),
            SizedBox(width: 10),
            Text('KunanApp', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: switch (selectedTab) {
            _HomeTab.home => _HomeContent(
              key: const ValueKey('home'),
              publications: publications,
              onOpenPublication: openPublication,
              onRefresh: () async {
                await loadPublications();
              },
            ),
            _HomeTab.categories => _CategoriesScreen(
              key: const ValueKey('categories'),
              categories: categories,
              selectedCategory: selectedCategory,
              products: visibleCategoryProducts,
              totalProducts: categoryProducts.length,
              favoriteIds: favoriteIds,
              isLoading: isLoading,
              errorMessage: errorMessage,
              onCategorySelected: (category) {
                if (selectedCategory == category) return;
                setState(() {
                  selectedCategory = category;
                  categoryVisibleCount = 10;
                });
              },
              onOpenProduct: openProduct,
              onToggleFavorite: toggleFavorite,
              onLoadMore: loadMoreCategoryProducts,
              onRefresh: loadProducts,
            ),
            _HomeTab.search => _SearchScreen(
              key: const ValueKey('search'),
              searchController: searchController,
              selectedFilter: selectedFilter,
              products: visibleSearchResults,
              totalProducts: searchResults.length,
              favoriteIds: favoriteIds,
              isLoading: isLoading,
              errorMessage: errorMessage,
              debouncedQuery: debouncedSearchQuery,
              onQueryChanged: updateSearchQuery,
              onClearQuery: clearSearchQuery,
              onFilterChanged: (filter) {
                if (selectedFilter == filter) return;
                setState(() {
                  selectedFilter = filter;
                  searchVisibleCount = 10;
                });
              },
              onOpenProduct: openProduct,
              onToggleFavorite: toggleFavorite,
              onLoadMore: loadMoreSearchResults,
              onRefresh: loadProducts,
            ),
            _HomeTab.favorites => _FavoritesScreen(
              key: const ValueKey('favorites'),
              products: favoriteProducts,
              favoriteIds: favoriteIds,
              isLoading: isLoading,
              onOpenProduct: openProduct,
              onToggleFavorite: toggleFavorite,
              onExplore: () => selectTab(_HomeTab.search),
            ),
            _HomeTab.account => _AccountScreen(
              key: const ValueKey('account'),
              name: fullName,
              email: displayEmail,
              onOpenFavorites: () => selectTab(_HomeTab.favorites),
              onLogout: logout,
            ),
          },
        ),
      ),
      bottomNavigationBar: _PremiumBottomNav(
        selectedTab: selectedTab,
        onTabSelected: selectTab,
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final List<Publication> publications;
  final ValueChanged<Publication> onOpenPublication;
  final Future<void> Function() onRefresh;

  const _HomeContent({
    super.key,
    required this.publications,
    required this.onOpenPublication,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 108),
        children: [
          const _LocationAccessCard(),
          const SizedBox(height: 18),
          if (publications.isNotEmpty)
            _PublicationSection(
              publications: publications,
              onOpenPublication: onOpenPublication,
            )
          else
            _EmptyState(
              icon: Icons.local_offer_rounded,
              title: 'Aun no hay ofertas disponibles.',
              actionLabel: 'Actualizar',
              onAction: onRefresh,
            ),
        ],
      ),
    );
  }
}

class _CategoriesScreen extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final List<Product> products;
  final int totalProducts;
  final Set<int> favoriteIds;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<Product> onOpenProduct;
  final ValueChanged<Product> onToggleFavorite;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;

  const _CategoriesScreen({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.products,
    required this.totalProducts,
    required this.favoriteIds,
    required this.isLoading,
    required this.errorMessage,
    required this.onCategorySelected,
    required this.onOpenProduct,
    required this.onToggleFavorite,
    required this.onLoadMore,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 108),
        children: [
          DropdownButtonFormField<String>(
            initialValue: categories.contains(selectedCategory)
                ? selectedCategory
                : 'Todas',
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Categoria',
              prefixIcon: Icon(Icons.category_rounded),
            ),
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            dropdownColor: Colors.white,
            items: categories.map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.text),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              onCategorySelected(value);
            },
          ),
          const SizedBox(height: 18),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (errorMessage != null)
            _EmptyState(
              icon: Icons.wifi_off_rounded,
              title: errorMessage ?? 'No pudimos cargar categorias.',
            )
          else if (products.isEmpty)
            _EmptyState(
              icon: Icons.category_outlined,
              title: selectedCategory == 'Todas'
                  ? 'No hay medicamentos disponibles.'
                  : 'No hay productos en esta categoria.',
            )
          else
            _PagedProductList(
              products: products,
              totalProducts: totalProducts,
              favoriteIds: favoriteIds,
              onOpenProduct: onOpenProduct,
              onToggleFavorite: onToggleFavorite,
              onLoadMore: onLoadMore,
            ),
        ],
      ),
    );
  }
}

class _SearchScreen extends StatelessWidget {
  final TextEditingController searchController;
  final ProductFilter selectedFilter;
  final List<Product> products;
  final int totalProducts;
  final Set<int> favoriteIds;
  final bool isLoading;
  final String? errorMessage;
  final String debouncedQuery;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final ValueChanged<ProductFilter> onFilterChanged;
  final ValueChanged<Product> onOpenProduct;
  final ValueChanged<Product> onToggleFavorite;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;

  const _SearchScreen({
    super.key,
    required this.searchController,
    required this.selectedFilter,
    required this.products,
    required this.totalProducts,
    required this.favoriteIds,
    required this.isLoading,
    required this.errorMessage,
    required this.debouncedQuery,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onFilterChanged,
    required this.onOpenProduct,
    required this.onToggleFavorite,
    required this.onLoadMore,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final hasQuery = debouncedQuery.isNotEmpty;
    final canSearch = debouncedQuery.trim().length >= 2;

    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 108),
        children: [
          TextField(
            controller: searchController,
            autofocus: false,
            cursorColor: AppColors.green,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w800,
            ),
            textInputAction: TextInputAction.search,
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              hintText: 'Que medicamento buscas?',
              hintStyle: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: hasQuery
                  ? IconButton(
                      onPressed: onClearQuery,
                      icon: const Icon(Icons.close_rounded),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Todos',
                  selected: selectedFilter == ProductFilter.all,
                  onTap: () => onFilterChanged(ProductFilter.all),
                ),
                _FilterChip(
                  label: 'Disponibles',
                  selected: selectedFilter == ProductFilter.available,
                  onTap: () => onFilterChanged(ProductFilter.available),
                ),
                _FilterChip(
                  label: 'Con receta',
                  selected: selectedFilter == ProductFilter.prescription,
                  onTap: () => onFilterChanged(ProductFilter.prescription),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (errorMessage != null)
            _EmptyState(
              icon: Icons.wifi_off_rounded,
              title: errorMessage ?? 'No pudimos cargar medicamentos.',
            )
          else if (products.isEmpty)
            _EmptyState(
              icon: Icons.search_off_rounded,
              title: hasQuery && canSearch
                  ? 'No encontramos medicamentos con esa busqueda.'
                  : 'No hay medicamentos disponibles.',
            )
          else
            _PagedProductList(
              products: products,
              totalProducts: totalProducts,
              favoriteIds: favoriteIds,
              onOpenProduct: onOpenProduct,
              onToggleFavorite: onToggleFavorite,
              onLoadMore: onLoadMore,
            ),
        ],
      ),
    );
  }
}

class _FavoritesScreen extends StatelessWidget {
  final List<Product> products;
  final Set<int> favoriteIds;
  final bool isLoading;
  final ValueChanged<Product> onOpenProduct;
  final ValueChanged<Product> onToggleFavorite;
  final VoidCallback onExplore;

  const _FavoritesScreen({
    super.key,
    required this.products,
    required this.favoriteIds,
    required this.isLoading,
    required this.onOpenProduct,
    required this.onToggleFavorite,
    required this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 108),
      children: [
        if (isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (products.isEmpty)
          _EmptyState(
            icon: Icons.favorite_border_rounded,
            title: 'Aun no tienes favoritos.',
            actionLabel: 'Buscar medicamentos',
            onAction: () async => onExplore(),
          )
        else
          _ProductList(
            products: products,
            favoriteIds: favoriteIds,
            onOpenProduct: onOpenProduct,
            onToggleFavorite: onToggleFavorite,
          ),
      ],
    );
  }
}

class _AccountScreen extends StatelessWidget {
  final String name;
  final String email;
  final VoidCallback onOpenFavorites;
  final VoidCallback onLogout;

  const _AccountScreen({
    super.key,
    required this.name,
    required this.email,
    required this.onOpenFavorites,
    required this.onLogout,
  });

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo abrir $url'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openTerms(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const _TermsScreen()),
    );
  }

  Future<void> _shareApp(BuildContext context) async {
    const message = 'Descubre KunanApp para consultar medicamentos y stock.';
    await Clipboard.setData(ClipboardData(text: message));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mensaje copiado para compartir.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 108),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.softGreen,
                child: Text(
                  name.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ProfileAction(
          icon: Icons.person_rounded,
          title: 'Mi perfil',
          subtitle: 'Datos basicos de tu cuenta',
          onTap: () {},
        ),
        _ProfileAction(
          icon: Icons.favorite_rounded,
          title: 'Mis favoritos',
          subtitle: 'Medicamentos guardados',
          onTap: onOpenFavorites,
        ),
        _ProfileAction(
          icon: Icons.privacy_tip_rounded,
          title: 'Politica de privacidad',
          subtitle: 'kunanfarma.com/privacy-policy',
          onTap: () {
            _openUrl(context, 'https://kunanfarma.com/privacy-policy/');
          },
        ),
        _ProfileAction(
          icon: Icons.article_rounded,
          title: 'Terminos y condiciones',
          subtitle: 'Informacion legal de KunanApp',
          onTap: () => _openTerms(context),
        ),
        _ProfileAction(
          icon: Icons.support_agent_rounded,
          title: 'Atencion al cliente',
          subtitle: 'Soporte para consultas y pedidos',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Canal de atencion en preparacion.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        _ProfileAction(
          icon: Icons.ios_share_rounded,
          title: 'Compartir aplicacion',
          subtitle: 'Copia un mensaje para recomendarla',
          onTap: () => _shareApp(context),
        ),
        _ProfileAction(
          icon: Icons.logout_rounded,
          title: 'Cerrar sesion',
          subtitle: 'Salir de tu cuenta de KunanApp',
          iconColor: AppColors.red,
          onTap: onLogout,
        ),
      ],
    );
  }
}

class _HomeDrawer extends StatelessWidget {
  final ValueChanged<_HomeMenuAction> onActionSelected;

  const _HomeDrawer({required this.onActionSelected});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Row(
                children: [
                  BrandLogo(size: 52, elevated: true),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'KunanApp',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            _DrawerItem(
              icon: Icons.home_rounded,
              label: 'Inicio',
              onTap: () => onActionSelected(_HomeMenuAction.home),
            ),
            _DrawerItem(
              icon: Icons.category_rounded,
              label: 'Categorias',
              onTap: () => onActionSelected(_HomeMenuAction.categories),
            ),
            _DrawerItem(
              icon: Icons.search_rounded,
              label: 'Buscar',
              onTap: () => onActionSelected(_HomeMenuAction.search),
            ),
            _DrawerItem(
              icon: Icons.favorite_rounded,
              label: 'Favoritos',
              onTap: () => onActionSelected(_HomeMenuAction.favorites),
            ),
            _DrawerItem(
              icon: Icons.person_rounded,
              label: 'Cuenta',
              onTap: () => onActionSelected(_HomeMenuAction.account),
            ),
            const Spacer(),
            const Divider(height: 1, color: AppColors.border),
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: 'Cerrar sesion',
              iconColor: AppColors.red,
              onTap: () => onActionSelected(_HomeMenuAction.logout),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.green),
      title: Text(
        label,
        style: const TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.w800,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _LocationAccessCard extends StatelessWidget {
  static final Uri _mapsUri = Uri.parse(
    'https://maps.app.goo.gl/YzDpiSTNKjnaywNHA',
  );

  const _LocationAccessCard();

  Future<void> _openMaps(BuildContext context) async {
    final opened = await launchUrl(
      _mapsUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir Google Maps.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openMaps(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            children: [
              Icon(Icons.location_on_rounded, color: AppColors.green, size: 30),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ubicacion de la farmacia',
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Abrir en Google Maps',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.open_in_new_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.deepGreen : AppColors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _PublicationSection extends StatelessWidget {
  final List<Publication> publications;
  final ValueChanged<Publication> onOpenPublication;

  const _PublicationSection({
    required this.publications,
    required this.onOpenPublication,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ofertas',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        ...publications.map(
          (publication) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _PublicationCard(
              publication: publication,
              onTap: () => onOpenPublication(publication),
            ),
          ),
        ),
      ],
    );
  }
}

class _PublicationCard extends StatelessWidget {
  final Publication publication;
  final VoidCallback onTap;

  const _PublicationCard({required this.publication, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = publication.displayImageUrl;
    final product = publication.product;
    final productName = product?.name.trim() ?? '';
    final productPrice = product?.formattedPrice ?? '';

    return AspectRatio(
      aspectRatio: 1.7,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl.isNotEmpty)
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    cacheWidth: 900,
                    cacheHeight: 530,
                    errorBuilder: (context, error, stackTrace) {
                      return const _PublicationFallback();
                    },
                  )
                else
                  const _PublicationFallback(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.08),
                        Colors.black.withValues(alpha: 0.78),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          _TinyBadge(
                            label: publication.typeLabel,
                            color: AppColors.deepGreen,
                            background: AppColors.softGreen,
                          ),
                          const Spacer(),
                          if (productPrice.isNotEmpty)
                            Text(
                              productPrice,
                              style: const TextStyle(
                                color: AppColors.yellow,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        publication.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if ((publication.description ?? '')
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          publication.description?.trim() ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xE6FFFFFF),
                            fontSize: 13,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (productName.isNotEmpty)
                            Expanded(
                              child: Text(
                                productName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            )
                          else
                            const Spacer(),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Ver oferta',
                                  style: TextStyle(
                                    color: AppColors.deepGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: AppColors.deepGreen,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PublicationFallback extends StatelessWidget {
  const _PublicationFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.softGreen,
      alignment: Alignment.center,
      child: const Icon(
        Icons.campaign_rounded,
        color: AppColors.green,
        size: 48,
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  final List<Product> products;
  final Set<int> favoriteIds;
  final ValueChanged<Product> onOpenProduct;
  final ValueChanged<Product> onToggleFavorite;

  const _ProductList({
    required this.products,
    required this.favoriteIds,
    required this.onOpenProduct,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ProductCard(
            product: product,
            isFavorite: favoriteIds.contains(product.id),
            onTap: () => onOpenProduct(product),
            onToggleFavorite: () => onToggleFavorite(product),
          ),
        );
      },
    );
  }
}

class _PagedProductList extends StatelessWidget {
  final List<Product> products;
  final int totalProducts;
  final Set<int> favoriteIds;
  final ValueChanged<Product> onOpenProduct;
  final ValueChanged<Product> onToggleFavorite;
  final VoidCallback onLoadMore;

  const _PagedProductList({
    required this.products,
    required this.totalProducts,
    required this.favoriteIds,
    required this.onOpenProduct,
    required this.onToggleFavorite,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'Mostrando ${products.length} de $totalProducts productos',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _ProductList(
          products: products,
          favoriteIds: favoriteIds,
          onOpenProduct: onOpenProduct,
          onToggleFavorite: onToggleFavorite,
        ),
        if (products.length < totalProducts)
          OutlinedButton.icon(
            onPressed: onLoadMore,
            icon: const Icon(Icons.expand_more_rounded),
            label: const Text('Ver 10 mas'),
          ),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const ProductCard({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProductImage(url: product.displayImageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: onToggleFavorite,
                          icon: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFavorite ? AppColors.red : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    if (product.customerSubtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        product.customerSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _TinyBadge(
                          label: product.available ? 'Disponible' : 'Sin stock',
                          color: product.available
                              ? AppColors.deepGreen
                              : AppColors.red,
                          background: product.available
                              ? AppColors.softGreen
                              : AppColors.softRed,
                        ),
                        if (product.requiresPrescription)
                          const _TinyBadge(
                            label: 'Receta',
                            color: AppColors.red,
                            background: AppColors.softRed,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      product.formattedPrice,
                      style: const TextStyle(
                        color: AppColors.red,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String url;

  const _ProductImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 96,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.softGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: url.isEmpty
          ? const Icon(
              Icons.medication_rounded,
              color: AppColors.green,
              size: 38,
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              cacheWidth: 172,
              cacheHeight: 192,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.medication_rounded,
                  color: AppColors.green,
                  size: 38,
                );
              },
            ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _TinyBadge({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PremiumBottomNav extends StatelessWidget {
  final _HomeTab selectedTab;
  final ValueChanged<_HomeTab> onTabSelected;

  const _PremiumBottomNav({
    required this.selectedTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
        child: Container(
          height: 72,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A101828),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Inicio',
                tab: _HomeTab.home,
                selectedTab: selectedTab,
                onTap: onTabSelected,
              ),
              _NavItem(
                icon: Icons.category_rounded,
                label: 'Categorias',
                tab: _HomeTab.categories,
                selectedTab: selectedTab,
                onTap: onTabSelected,
              ),
              _NavItem(
                icon: Icons.search_rounded,
                label: 'Buscar',
                tab: _HomeTab.search,
                selectedTab: selectedTab,
                onTap: onTabSelected,
              ),
              _NavItem(
                icon: Icons.favorite_rounded,
                label: 'Favoritos',
                tab: _HomeTab.favorites,
                selectedTab: selectedTab,
                onTap: onTabSelected,
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Cuenta',
                tab: _HomeTab.account,
                selectedTab: selectedTab,
                onTap: onTabSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final _HomeTab tab;
  final _HomeTab selectedTab;
  final ValueChanged<_HomeTab> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.tab,
    required this.selectedTab,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = tab == selectedTab;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => onTap(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: double.infinity,
          decoration: BoxDecoration(
            color: selected ? AppColors.softGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? AppColors.green : AppColors.muted,
                size: 22,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? AppColors.deepGreen : AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor == AppColors.red
                        ? AppColors.softRed
                        : AppColors.softGreen,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor ?? AppColors.green),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TermsScreen extends StatelessWidget {
  const _TermsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Terminos y condiciones')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: const [
            Text(
              'Terminos y condiciones',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Esta pantalla es temporal. Reemplazar por la URL o contenido legal oficial cuando este disponible.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.green, size: 54),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel ?? 'Continuar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
