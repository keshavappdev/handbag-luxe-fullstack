import 'package:get_storage/get_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _secure = FlutterSecureStorage();
  static String _token = '';
  static Future<void> initializeSecureToken() async {
    _token = await _secure.read(key: 'potli_api_token') ?? '';
    // The previous PHP token must not be sent to the new backend.
    await GetStorage().remove(authTokenKey);
    if (GetStorage().read<bool>('node_backend_migrated') != true) {
      await GetStorage().remove(cartKey);
      await GetStorage().remove(wishlistKey);
      await GetStorage().remove(cartPersonalizationsKey);
      await GetStorage().write('node_backend_migrated', true);
    }
  }

  StorageService(this._box);

  final GetStorage _box;

  static const onboardingKey = 'onboarding_complete';
  static const wishlistKey = 'wishlist_ids';
  static const cartKey = 'cart_quantities';
  static const cartPersonalizationsKey = 'cart_personalizations';
  static const authTokenKey = 'auth_token';
  static const hasSignedInBeforeKey = 'has_signed_in_before';
  static const usernameKey = 'username';
  static const userIdKey = 'user_id';
  static const userEmailKey = 'user_email';
  static const userMobileKey = 'user_mobile';

  bool get hasSeenOnboarding => _box.read<bool>(onboardingKey) ?? false;

  Future<void> completeOnboarding() => _box.write(onboardingKey, true);

  List<String> get wishlistIds =>
      List<String>.from(_box.read<List<dynamic>>(wishlistKey) ?? const []);

  Future<void> saveWishlist(Iterable<String> ids) =>
      _box.write(wishlistKey, ids.toList());

  Map<String, int> get cartQuantities {
    final raw = Map<String, dynamic>.from(
      _box.read<Map<dynamic, dynamic>>(cartKey) ?? const {},
    );
    return raw.map((key, value) => MapEntry(key, value as int));
  }

  Future<void> saveCart(Map<String, int> quantities) =>
      _box.write(cartKey, quantities);

  /// Engraving/personalization text entered per product, keyed by product id.
  /// Kept alongside cart quantities since the app's cart is fully local/
  /// optimistic — nothing re-reads it from the server for display — so this
  /// is the only place that remembers what was typed once the personalize
  /// card closes, all the way through to order placement.
  Map<String, String> get cartPersonalizations {
    final raw = Map<String, dynamic>.from(
      _box.read<Map<dynamic, dynamic>>(cartPersonalizationsKey) ?? const {},
    );
    return raw.map((key, value) => MapEntry(key, '$value'));
  }

  Future<void> saveCartPersonalizations(Map<String, String> personalizations) =>
      _box.write(cartPersonalizationsKey, personalizations);

  String get authToken => _token;

  Future<void> saveAuthToken(String token) async {
    _token = token;
    await _secure.write(key: 'potli_api_token', value: token);
  }

  Future<void> clearAuthToken() async {
    _token = '';
    await _secure.delete(key: 'potli_api_token');
  }

  bool get hasSignedInBefore => _box.read<bool>(hasSignedInBeforeKey) ?? false;

  Future<void> markSignedInBefore() => _box.write(hasSignedInBeforeKey, true);

  String get username => _box.read<String>(usernameKey) ?? '';

  Future<void> saveUsername(String username) =>
      _box.write(usernameKey, username);

  Future<void> clearUsername() => _box.remove(usernameKey);

  // User id/email/mobile — needed for the profile page and because
  // update_user takes user_id straight from the request body rather than
  // the auth token, so the app has to know and send its own signed-in
  // user's id explicitly.
  String get userId => _box.read<String>(userIdKey) ?? '';
  String get userEmail => _box.read<String>(userEmailKey) ?? '';
  String get userMobile => _box.read<String>(userMobileKey) ?? '';

  Future<void> saveUserProfile({
    required String id,
    required String email,
    required String mobile,
  }) async {
    await _box.write(userIdKey, id);
    await _box.write(userEmailKey, email);
    await _box.write(userMobileKey, mobile);
  }

  Future<void> clearUserProfile() async {
    await _box.remove(userIdKey);
    await _box.remove(userEmailKey);
    await _box.remove(userMobileKey);
  }
}
