import 'api_base_helper.dart';
import 'api_constants.dart';

class FavoriteService {
  FavoriteService(this._api);

  final ApiBaseHelper _api;

  Future<void> addFavorite(String productId) {
    return _api.post(setFavoriteApi, {kProductId: productId});
  }

  Future<void> removeFavorite(String productId) {
    return _api.post(removeFavApi, {kProductId: productId});
  }
}
