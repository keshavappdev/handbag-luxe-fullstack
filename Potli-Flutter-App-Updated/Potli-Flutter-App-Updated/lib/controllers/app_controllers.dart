import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../app/routes.dart';
import '../models/category_node.dart';
import '../models/home_section.dart';
import '../models/home_slide.dart';
import '../models/product.dart';
import '../services/api/address_service.dart';
import '../services/api/api_base_helper.dart';
import '../services/api/api_constants.dart';
import '../services/api/auth_service.dart';
import '../services/api/cart_service.dart';
import '../services/api/category_service.dart';
import '../services/api/favorite_service.dart';
import '../services/api/fcm_service.dart';
import '../services/api/notification_service.dart';
import '../services/api/order_service.dart';
import '../services/api/product_service.dart';
import '../services/api/return_exchange_service.dart';
import '../services/api/section_service.dart';
import '../services/api/settings_service.dart';
import '../services/api/slider_service.dart';
import '../services/api/support_service.dart';
import '../services/api/wallet_service.dart';
import '../services/push_notification_service.dart';
import '../services/storage_service.dart';
import '../utils/asset_paths.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(StorageService(GetStorage()), permanent: true);
    Get.put(ApiBaseHelper(Get.find()), permanent: true);
    Get.put(CategoryService(Get.find()), permanent: true);
    Get.put(ProductService(Get.find()), permanent: true);
    Get.put(SliderService(Get.find()), permanent: true);
    Get.put(SectionService(Get.find()), permanent: true);
    Get.put(AuthService(Get.find()), permanent: true);
    Get.put(CartService(Get.find()), permanent: true);
    Get.put(FavoriteService(Get.find()), permanent: true);
    Get.put(AddressService(Get.find()), permanent: true);
    Get.put(OrderService(Get.find()), permanent: true);
    Get.put(ReturnExchangeService(Get.find()), permanent: true);
    Get.put(NotificationService(Get.find()), permanent: true);
    Get.put(SettingsService(Get.find()), permanent: true);
    Get.put(WalletService(Get.find()), permanent: true);
    Get.put(SupportService(Get.find()), permanent: true);
    Get.put(FcmService(Get.find()), permanent: true);
    Get.put(PushNotificationService(Get.find(), Get.find()), permanent: true);
    Get.put(NavigationController(), permanent: true);
    Get.put(
      CatalogController(Get.find(), Get.find(), Get.find(), Get.find()),
      permanent: true,
    );
    Get.put(
      WishlistController(Get.find(), Get.find(), Get.find()),
      permanent: true,
    );
    Get.put(
      CartController(Get.find(), Get.find(), Get.find()),
      permanent: true,
    );
    Get.put(
      AuthController(Get.find(), Get.find(), Get.find()),
      permanent: true,
    );
  }
}

class NavigationController extends GetxController {
  final index = 0.obs;
  final homeChromeVisible = false.obs;

  void go(int value) {
    index.value = value;
    if (value == 0) Get.find<CatalogController>().refreshCatalog();
    if (value == 2) Get.find<CartController>().syncFromServer();
  }

  void setHomeChromeVisible(bool value) => homeChromeVisible.value = value;
}

class CatalogController extends GetxController {
  CatalogController(
    this._categoryService,
    this._productService,
    this._sliderService,
    this._sectionService,
  );

  final CategoryService _categoryService;
  final ProductService _productService;
  final SliderService _sliderService;
  final SectionService _sectionService;

  Future<void> refreshCatalog() async {
    await Future.wait([
      loadTopCategories().then((_) => loadMenuCategories()),
      loadProducts(),
      loadHomeSlides(),
      loadHomeSections(),
    ]);
  }

  final query = ''.obs;
  final isLoading = false.obs;
  final categoriesLoading = false.obs;
  final topCategories = <CategoryNode>[].obs;

  /// Shown in the "Shop by Category" menu screen. There's currently only one
  /// active top-level category, so a listing of main categories there would
  /// be a single useless tile — this shows that category's subcategories
  /// (Tote Bag, Sling Bag, etc.) directly instead.
  final menuCategories = <CategoryNode>[].obs;
  final products = <Product>[].obs;
  final homeSlides = <HomeSlide>[].obs;

  /// Admin -> Featured Sections. Drives the real-product grid on the home
  /// page (replacing what used to be a purely decorative hardcoded collage)
  /// so admin-picked products/images show without an app release.
  final homeSections = <HomeSection>[].obs;
  final Map<String, Product> _cache = {};

  @override
  void onInit() {
    super.onInit();
    loadTopCategories().then((_) => loadMenuCategories());
    loadProducts();
    loadHomeSlides();
    loadHomeSections();
  }

  Future<void> loadHomeSections() async {
    try {
      final sections = await _sectionService.getSections();
      homeSections.value = sections;
      for (final section in sections) {
        for (final product in section.products) {
          _cache[product.id] = product;
        }
      }
    } catch (_) {
      homeSections.value = [];
    }
  }

  /// Every admin -> Featured Sections product, flattened across all
  /// sections in order. The home page draws its API-backed image slots
  /// (product collage, hero image, portraits, story background) from this
  /// one pool at fixed offsets, so the same product photo never shows up
  /// twice across different slots on the same page.
  List<Product> get homeSectionProducts => [
    for (final section in homeSections) ...section.products,
  ];

  /// Null when there aren't enough real products yet at this position —
  /// callers fall back to their existing static asset in that case, so no
  /// home-page slot goes blank while Featured Sections are still sparse.
  Product? homeSectionProductAt(int index) {
    final pool = homeSectionProducts;
    return index < pool.length ? pool[index] : null;
  }

  /// Same positional scheme as [homeSectionProductAt], but also carries the
  /// admin-configured section title that product came from — used to
  /// replace a slot's hardcoded heading (e.g. "The Journal") with the real
  /// Featured Section name (e.g. "Fresh Arrivals") instead of just the image.
  ({HomeSection section, Product product})? homeSectionEntryAt(int index) {
    var remaining = index;
    for (final section in homeSections) {
      if (remaining < section.products.length) {
        return (section: section, product: section.products[remaining]);
      }
      remaining -= section.products.length;
    }
    return null;
  }

  Future<void> loadHomeSlides() async {
    try {
      homeSlides.value = await _sliderService.getHomeSlides();
      // TEMP DEBUG — remove once the homepage blank-gap issue is found.
      debugPrint(
        'loadHomeSlides: got ${homeSlides.length} slides: '
        '${homeSlides.map((s) => '${s.type}:${s.image}').toList()}',
      );
    } catch (e, st) {
      debugPrint('loadHomeSlides: FAILED: $e\n$st');
      homeSlides.value = [];
    }
  }

  /// Cycles through whatever real slide images the CMS currently has so every
  /// existing home-page image slot shows a real photo when possible. Falls
  /// back to a bundled asset only if the API genuinely has no usable slides
  /// (e.g. offline, or nothing configured yet) — several full-screen-height
  /// home sections have no other fallback, so an empty list would otherwise
  /// leave them permanently blank.
  ///
  /// Excludes type "brand" slides (a small logo mark on a plain background)
  /// — cover-cropped into a near-full-screen-tall section, a logo just shows
  /// mostly blank background instead of a photo, which read as a "gap" bug.
  List<HomeSlide> get _photoSlides =>
      homeSlides.where((s) => s.type != 'brand').toList();

  String homeSlideImage(int index) {
    final slides = _photoSlides;
    if (slides.isEmpty) {
      return AssetPaths.homeMosaic[index % AssetPaths.homeMosaic.length];
    }
    return slides[index % slides.length].image;
  }

  Product? productById(String id) => _cache[id];

  Future<Product?> fetchProductDetail(String id) async {
    try {
      final result = await _productService.getProducts(id: id);
      if (result.isEmpty) return null;
      final detailed = result.first;
      _cache[id] = detailed;
      return detailed;
    } catch (_) {
      return null;
    }
  }

  Future<void> loadTopCategories() async {
    categoriesLoading.value = true;
    try {
      topCategories.value = await _categoryService.getTopCategories();
    } catch (_) {
      topCategories.value = [];
    } finally {
      categoriesLoading.value = false;
    }
  }

  Future<List<CategoryNode>> loadSubCategories(String categoryId) {
    return _categoryService.getSubCategories(categoryId);
  }

  Future<void> loadMenuCategories() async {
    if (topCategories.isEmpty) {
      // TEMP DEBUG — remove once the menu/sub-category blank-screen issue is found.
      debugPrint('loadMenuCategories: topCategories is EMPTY, skipping');
      menuCategories.value = [];
      return;
    }
    debugPrint(
      'loadMenuCategories: fetching subcategories for l1 id=${topCategories.first.id}',
    );
    categoriesLoading.value = true;
    try {
      final children = await loadSubCategories(topCategories.first.id);
      menuCategories.value = topCategories.length == 1 && children.isNotEmpty
          ? children
          : topCategories.toList();
      debugPrint(
        'loadMenuCategories: got ${menuCategories.length} subcategories',
      );
    } catch (e, st) {
      debugPrint('loadMenuCategories: FAILED: $e\n$st');
      menuCategories.value = [];
    } finally {
      categoriesLoading.value = false;
    }
  }

  Future<List<CategoryNode>> loadCollectionItems(
    String categoryId,
    String subCategoryId,
  ) {
    return _categoryService.getCollectionItems(categoryId, subCategoryId);
  }

  /// Flattens every L3 category (e.g. "Shoulder Bags", "Bead Bags") across
  /// all of the site's active L2 groups — used to drive the Discover
  /// screen's story list with real, CMS-managed categories instead of a
  /// fixed hardcoded set.
  Future<List<CategoryNode>> loadDiscoverStories() async {
    if (topCategories.isEmpty) return const [];
    final l1Id = topCategories.first.id;
    final subCategories = menuCategories.isNotEmpty
        ? menuCategories
        : await loadSubCategories(l1Id);
    final items = <CategoryNode>[];
    for (final sub in subCategories) {
      items.addAll(await loadCollectionItems(l1Id, sub.id));
    }
    return items;
  }

  Future<void> loadProducts({
    String? categoryId,
    String? search,
    int? minPrice,
    int? maxPrice,
    String? sort,
  }) async {
    isLoading.value = true;
    try {
      final result = <Product>[];
      for (var offset = 0; ; offset += 200) {
        final batch = await _productService.getProducts(
          categoryId: categoryId,
          search: search,
          minPrice: minPrice,
          maxPrice: maxPrice,
          sort: sort,
          limit: 200,
          offset: offset,
        );
        result.addAll(batch);
        if (batch.length < 200) break;
      }
      products.value = result;
      for (final product in result) {
        _cache[product.id] = product;
      }
    } catch (_) {
      products.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  List<Product> get results {
    final needle = query.value.trim().toLowerCase();
    if (needle.isEmpty) return products;
    return products
        .where(
          (product) =>
              product.name.toLowerCase().contains(needle) ||
              product.category.toLowerCase().contains(needle),
        )
        .toList();
  }

  Future<void> openCategory(String categoryName) async {
    query.value = '';
    Get.toNamed(Routes.listing, arguments: categoryName);
    CategoryNode? match;
    for (final category in topCategories) {
      if (category.name.toLowerCase() == categoryName.toLowerCase()) {
        match = category;
        break;
      }
    }
    if (match != null) {
      await loadProducts(categoryId: match.id);
    } else {
      await loadProducts(search: categoryName);
    }
  }

  /// Same as [openCategory] but for a category we already have the id for
  /// (e.g. a menuCategories tile) — filters by id directly instead of
  /// matching on name, which menuCategories entries wouldn't do anyway since
  /// they aren't in topCategories.
  Future<void> openCategoryById(String categoryId, String categoryName) async {
    query.value = '';
    Get.toNamed(Routes.listing, arguments: categoryName);
    await loadProducts(categoryId: categoryId);
  }

  Future<void> showAll() async {
    query.value = '';
    Get.toNamed(Routes.listing, arguments: 'THE COLLECTION');
    await loadProducts();
  }

  void openProduct(Product product) =>
      Get.toNamed(Routes.detail, arguments: product, preventDuplicates: false);
}

class WishlistController extends GetxController {
  WishlistController(this._storage, this._catalog, this._favorites);

  final StorageService _storage;
  final CatalogController _catalog;
  final FavoriteService _favorites;
  final ids = <String>{}.obs;

  bool get _isSignedIn => _storage.authToken.isNotEmpty;

  @override
  void onInit() {
    ids.addAll(_storage.wishlistIds);
    unawaited(syncFromServer());
    super.onInit();
  }

  Future<void> syncFromServer({bool mergeGuest = false}) async {
    try {
      if (_isSignedIn) {
        if (mergeGuest)
          for (final id in ids.toList()) {
            await _favorites.addFavorite(id);
          }
        final response = await Get.find<ApiBaseHelper>().post(getFavApi, {});
        final rows = response['data'] as List;
        ids.assignAll(rows.map((r) => '${r['id']}'));
        await _storage.saveWishlist(ids);
      }
      await Future.wait(ids.map(_catalog.fetchProductDetail));
      ids.refresh();
    } catch (e) {
      if (Get.context != null) Get.rawSnackbar(message: e.toString());
    }
  }

  void clearLocal() {
    ids.clear();
    _storage.saveWishlist(ids);
  }

  bool contains(String id) => ids.contains(id);

  Future<void> toggle(Product product) async {
    final adding = !ids.contains(product.id);
    adding ? ids.add(product.id) : ids.remove(product.id);
    _storage.saveWishlist(ids);
    if (_isSignedIn) {
      final future = adding
          ? _favorites.addFavorite(product.id)
          : _favorites.removeFavorite(product.id);
      try {
        await future;
      } catch (e) {
        adding ? ids.remove(product.id) : ids.add(product.id);
        _storage.saveWishlist(ids);
        if (Get.context != null) Get.rawSnackbar(message: e.toString());
      }
    }
  }

  List<Product> get products =>
      ids.map(_catalog.productById).whereType<Product>().toList();
}

class CartController extends GetxController {
  CartController(this._storage, this._catalog, this._cartService);

  final StorageService _storage;
  final CatalogController _catalog;
  final CartService _cartService;
  final quantities = <String, int>{}.obs;

  /// Engraving text entered per product id. The app's cart is fully local —
  /// nothing re-reads it from the server for display — so this is the only
  /// record of what was typed, carried through to order placement.
  final personalizations = <String, String>{}.obs;

  bool get _isSignedIn => _storage.authToken.isNotEmpty;

  @override
  void onInit() {
    quantities.addAll(_storage.cartQuantities);
    personalizations.addAll(_storage.cartPersonalizations);
    super.onInit();
    _isSignedIn ? syncFromServer() : _hydrateRestoredLines();
  }

  /// `quantities`/`personalizations` are restored from persistent storage
  /// above, but `lines` (what the Bag page actually renders) also needs
  /// each product's full data from CatalogController's cache — which is
  /// purely in-memory and always starts empty on a fresh app launch. Right
  /// after a restart, that left the bag badge correctly showing the
  /// restored count while the Bag page itself rendered empty (lines
  /// silently drops any entry it can't resolve to a Product). Fetching
  /// each restored product here, then refresh()ing quantities once done,
  /// forces every Obx reading count/lines to rebuild against the now
  /// actually-resolvable data.
  Future<void> _hydrateRestoredLines() async {
    final missingIds = quantities.keys
        .where((id) => _catalog.productById(id) == null)
        .toList();
    if (missingIds.isEmpty) return;
    await Future.wait(missingIds.map(_catalog.fetchProductDetail));
    quantities.refresh();
  }

  Future<void> syncFromServer({bool mergeGuest = false}) async {
    if (!_isSignedIn) return;
    try {
      if (mergeGuest) {
        await _hydrateRestoredLines();
        for (final line in lines) {
          await _cartService.manageCart(
            variantId: line.product.variantId!,
            quantity: line.quantity,
            personalizationText: line.personalizationText,
          );
        }
      }
      final response = await Get.find<ApiBaseHelper>().post(getCartApi, {});
      final restored = <String, int>{};
      final texts = <String, String>{};
      for (final row in response['data'] as List) {
        final productId = '${row['product']['id']}';
        await _catalog.fetchProductDetail(productId);
        restored[productId] = (row['qty'] as num).toInt();
        texts[productId] = '${row['personalization_text'] ?? ''}';
      }
      quantities.assignAll(restored);
      personalizations.assignAll(texts);
      _persist();
    } catch (e) {
      if (Get.context != null) Get.rawSnackbar(message: e.toString());
    }
  }

  void clearLocal() {
    quantities.clear();
    personalizations.clear();
    _persist();
  }

  void _syncQuantity(
    Product product,
    int quantity, {
    String? personalizationText,
  }) {
    if (!_isSignedIn || product.variantId == null) return;
    _cartService
        .manageCart(
          variantId: product.variantId!,
          quantity: quantity,
          personalizationText: personalizationText,
        )
        .catchError((Object e) {
          if (Get.context != null) Get.rawSnackbar(message: e.toString());
          unawaited(syncFromServer());
        });
  }

  void _syncRemoved(Product product) {
    if (!_isSignedIn || product.variantId == null) return;
    _cartService.removeFromCart(product.variantId!).catchError((Object e) {
      if (Get.context != null) Get.rawSnackbar(message: e.toString());
      unawaited(syncFromServer());
    });
  }

  int get count => quantities.values.fold(0, (sum, item) => sum + item);

  List<CartLine> get lines => quantities.entries
      .map((entry) {
        final product = _catalog.productById(entry.key);
        return product == null
            ? null
            : CartLine(
                product: product,
                quantity: entry.value,
                personalizationText: personalizations[entry.key],
              );
      })
      .whereType<CartLine>()
      .toList();

  int get subtotal =>
      lines.fold(0, (sum, line) => sum + line.product.price * line.quantity);
  int get delivery => subtotal == 0 || subtotal >= 2999 ? 0 : 99;
  int get total => subtotal + delivery;

  void add(Product product, {int quantity = 1, String? personalizationText}) {
    final next = (quantities[product.id] ?? 0) + quantity;
    if (next > (product.stock ?? 0)) {
      Get.rawSnackbar(message: 'Insufficient stock');
      return;
    }
    quantities[product.id] = next;
    // null = not provided (e.g. a plain quantity "+" tap) — leave any existing
    // personalization alone. '' = explicitly cleared in the personalize card.
    if (personalizationText != null) {
      if (personalizationText.isEmpty) {
        personalizations.remove(product.id);
      } else {
        personalizations[product.id] = personalizationText;
      }
    }
    _persist();
    _syncQuantity(
      product,
      quantities[product.id]!,
      personalizationText: personalizationText,
    );
    Get.rawSnackbar(
      messageText: const Text(
        'ADDED TO BAG',
        style: TextStyle(color: Colors.white, letterSpacing: 2, fontSize: 10),
      ),
      // Same tab-switch pattern used by the app bar's own "BAG" link
      // (luxury_widgets.dart) — jump straight to the cart tab if already
      // inside the shell, otherwise reset the stack back to it first.
      mainButton: TextButton(
        onPressed: () {
          Get.closeCurrentSnackbar();
          if (Get.currentRoute == Routes.shell) {
            Get.find<NavigationController>().go(2);
          } else {
            Get.offAllNamed(Routes.shell);
            Get.find<NavigationController>().go(2);
          }
        },
        child: const Text(
          'GO TO CART',
          style: TextStyle(
            color: Colors.white,
            letterSpacing: 1.6,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(12),
      borderRadius: 0,
      backgroundColor: Colors.black,
      duration: const Duration(milliseconds: 2200),
    );
  }

  void decrement(Product product) {
    final next = (quantities[product.id] ?? 0) - 1;
    if (next <= 0) {
      quantities.remove(product.id);
      personalizations.remove(product.id);
    } else {
      quantities[product.id] = next;
    }
    _persist();
    next <= 0 ? _syncRemoved(product) : _syncQuantity(product, next);
  }

  void remove(Product product) {
    quantities.remove(product.id);
    personalizations.remove(product.id);
    _persist();
    _syncRemoved(product);
  }

  void clear() {
    for (final line in lines) {
      _syncRemoved(line.product);
    }
    quantities.clear();
    personalizations.clear();
    _persist();
  }

  void _persist() {
    _storage.saveCart(Map<String, int>.from(quantities));
    _storage.saveCartPersonalizations(
      Map<String, String>.from(personalizations),
    );
  }
}

class AuthController extends GetxController {
  AuthController(this._authService, this._storage, this._pushNotifications);

  final AuthService _authService;
  final StorageService _storage;
  final PushNotificationService _pushNotifications;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID').isEmpty
        ? null
        : const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
  );

  final isSignedIn = false.obs;
  final isBusy = false.obs;
  final errorMessage = ''.obs;
  final username = ''.obs;
  final email = ''.obs;
  final mobile = ''.obs;

  @override
  void onInit() {
    super.onInit();
    isSignedIn.value = _storage.authToken.isNotEmpty;
    username.value = _storage.username;
    email.value = _storage.userEmail;
    mobile.value = _storage.userMobile;
    // Anyone signed in from before name/email/mobile started being cached
    // (or before update_user's user_id fallback fix below existed) has
    // none of this stored locally yet, even though the admin/database
    // clearly has it — fetch it once in that case. update_user with no
    // fields to change just returns the current profile as-is; it now
    // falls back to the signed-in user's own id from the token when no
    // user_id is sent, which is what makes this fetch-only call work at
    // all without already knowing that id.
    if (isSignedIn.value && (username.value.isEmpty || email.value.isEmpty)) {
      unawaited(
        _fetchProfile().catchError((Object e) {
          errorMessage.value = e.toString();
        }),
      );
    }
  }

  Future<void> _fetchProfile() async {
    final result = await _authService.updateProfile();
    if (!result.success) return;
    if (result.username != null) {
      await _storage.saveUsername(result.username!);
      username.value = result.username!;
    }
    await _storage.saveUserProfile(
      id: _storage.userId,
      email: result.email ?? _storage.userEmail,
      mobile: result.mobile ?? _storage.userMobile,
    );
    if (result.email != null) email.value = result.email!;
    if (result.mobile != null) mobile.value = result.mobile!;
  }

  bool get isReturningUser => _storage.hasSignedInBefore;

  Future<bool> signInWithGoogle() async {
    isBusy.value = true;
    errorMessage.value = '';
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // User cancelled the picker.
        return false;
      }
      final identity = await account.authentication;
      if (identity.idToken == null)
        throw Exception('Configure your Google OAuth client ID.');
      final displayName = account.displayName ?? account.email;
      final result = await _authService.socialSignUp(
        idToken: identity.idToken!,
      );
      if (result.success && result.token != null) {
        await _storage.saveAuthToken(result.token!);
        await _storage.markSignedInBefore();
        await _storage.saveUsername(result.username ?? displayName);
        username.value = result.username ?? displayName;
        await _storage.saveUserProfile(
          id: result.userId ?? '',
          email: result.email ?? account.email,
          mobile: result.mobile ?? '',
        );
        email.value = result.email ?? account.email;
        mobile.value = result.mobile ?? '';
        unawaited(_pushNotifications.syncCurrentTokenIfSignedIn());
        isSignedIn.value = true;
        await Get.find<CartController>().syncFromServer(mergeGuest: true);
        await Get.find<WishlistController>().syncFromServer(mergeGuest: true);
        _prepareHomeEntry();
        Get.offAllNamed(Routes.shell);
        return true;
      }
      errorMessage.value = result.message.isNotEmpty
          ? result.message
          : 'Unable to sign in with Google';
      return false;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isBusy.value = false;
    }
  }

  Future<bool> login({required String mobile, required String password}) async {
    isBusy.value = true;
    errorMessage.value = '';
    try {
      final result = await _authService.login(
        mobile: mobile,
        password: password,
      );
      if (result.success && result.token != null) {
        await _storage.saveAuthToken(result.token!);
        await _storage.markSignedInBefore();
        if (result.username != null) {
          await _storage.saveUsername(result.username!);
          username.value = result.username!;
        }
        await _storage.saveUserProfile(
          id: result.userId ?? '',
          email: result.email ?? '',
          // `mobile` here is this method's own parameter (the number just
          // logged in with), not the reactive field below — this.mobile
          // disambiguates that one.
          mobile: result.mobile ?? mobile,
        );
        email.value = result.email ?? '';
        this.mobile.value = result.mobile ?? mobile;
        unawaited(_pushNotifications.syncCurrentTokenIfSignedIn());
        isSignedIn.value = true;
        await Get.find<CartController>().syncFromServer(mergeGuest: true);
        await Get.find<WishlistController>().syncFromServer(mergeGuest: true);
        _prepareHomeEntry();
        Get.offAllNamed(Routes.shell);
        return true;
      }
      errorMessage.value = result.message.isNotEmpty
          ? result.message
          : 'Unable to sign in';
      return false;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isBusy.value = false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String mobile,
    required String password,
  }) async {
    isBusy.value = true;
    errorMessage.value = '';
    try {
      final result = await _authService.register(
        name: name,
        email: email,
        mobile: mobile,
        password: password,
      );
      if (result.success && result.token != null) {
        await _storage.saveAuthToken(result.token!);
        await _storage.markSignedInBefore();
        await _storage.saveUsername(result.username ?? name);
        username.value = result.username ?? name;
        // `email`/`mobile` here are this method's own parameters (what was
        // just typed in the form) — this.email/this.mobile disambiguate
        // the reactive fields of the same name below.
        await _storage.saveUserProfile(
          id: result.userId ?? '',
          email: result.email ?? email,
          mobile: result.mobile ?? mobile,
        );
        this.email.value = result.email ?? email;
        this.mobile.value = result.mobile ?? mobile;
        unawaited(_pushNotifications.syncCurrentTokenIfSignedIn());
        isSignedIn.value = true;
        await Get.find<CartController>().syncFromServer(mergeGuest: true);
        await Get.find<WishlistController>().syncFromServer(mergeGuest: true);
        _prepareHomeEntry();
        Get.offAllNamed(Routes.shell);
        return true;
      }
      errorMessage.value = result.message.isNotEmpty
          ? result.message
          : 'Unable to create account';
      return false;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isBusy.value = false;
    }
  }

  void continueAsGuest() {
    _prepareHomeEntry();
    Get.offAllNamed(Routes.shell);
  }

  void _prepareHomeEntry() {
    final navigation = Get.find<NavigationController>();
    navigation.index.value = 0;
    navigation.setHomeChromeVisible(false);
  }

  Future<void> signOut() async {
    Get.find<CartController>().clearLocal();
    Get.find<WishlistController>().clearLocal();
    await _storage.clearAuthToken();
    await _storage.clearUsername();
    await _storage.clearUserProfile();
    isSignedIn.value = false;
    username.value = '';
    email.value = '';
    mobile.value = '';
    Get.offAllNamed(Routes.login);
  }

  /// Edits the signed-in user's own name/email — see the Profile page.
  Future<bool> updateProfile({
    String? newUsername,
    String? newEmail,
    String? newMobile,
  }) async {
    isBusy.value = true;
    errorMessage.value = '';
    try {
      final result = await _authService.updateProfile(
        username: newUsername,
        email: newEmail,
        mobile: newMobile,
      );
      if (result.success) {
        if (result.username != null) {
          await _storage.saveUsername(result.username!);
          username.value = result.username!;
        }
        if (result.email != null || result.mobile != null) {
          await _storage.saveUserProfile(
            id: _storage.userId,
            email: result.email ?? _storage.userEmail,
            mobile: result.mobile ?? _storage.userMobile,
          );
          if (result.email != null) email.value = result.email!;
          if (result.mobile != null) mobile.value = result.mobile!;
        }
        return true;
      }
      errorMessage.value = result.message.isNotEmpty
          ? result.message
          : 'Could not update your profile';
      return false;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isBusy.value = false;
    }
  }
}
