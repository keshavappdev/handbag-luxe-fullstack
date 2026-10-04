import '../../models/address.dart';
import 'api_base_helper.dart';
import 'api_constants.dart';

class AddressService {
  AddressService(this._api);

  final ApiBaseHelper _api;

  /// Adds an address and returns its id, or null if the backend didn't
  /// return one.
  Future<String?> addAddress({
    required String name,
    required String mobile,
    required String address,
    required String cityName,
    required String pincode,
    String state = '',
    String country = '',
  }) async {
    final response = await _api.post(getAddAddressApi, {
      'name': name,
      'mobile': mobile,
      'address': address,
      'city_name': cityName,
      'pincode': pincode,
      if (state.isNotEmpty) 'state': state,
      if (country.isNotEmpty) 'country': country,
    });
    final data = response is Map ? response['data'] : null;
    if (data is! List || data.isEmpty) return null;
    final last = data.last;
    if (last is! Map || last['id'] == null) return null;
    return '${last['id']}';
  }

  Future<List<Address>> getAddresses() async {
    final response = await _api.post(getAddressApi, const {});
    final data = response is Map ? response['data'] : null;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => Address.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<bool> updateAddress({
    required String id,
    required String name,
    required String mobile,
    required String address,
    required String cityName,
    required String pincode,
    String state = '',
    String country = '',
  }) async {
    final response = await _api.post(updateAddressApi, {
      'id': id,
      'name': name,
      'mobile': mobile,
      'address': address,
      'city_name': cityName,
      'pincode': pincode,
      if (state.isNotEmpty) 'state': state,
      if (country.isNotEmpty) 'country': country,
    });
    return response is Map && response['error'] != true;
  }

  Future<bool> deleteAddress(String id) async {
    final response = await _api.post(deleteAddressApi, {'id': id});
    return response is Map && response['error'] != true;
  }
}
