import 'package:flutter/services.dart';

import '../models/product.dart';
import '../utils/site_links.dart';

/// Opens the Android Share Sheet using our Java MethodChannel implementation.
class NativeProductShareService {
  static const _channel = MethodChannel('com.potli.app/product_share');

  static Future<void> share(Product product) async {
    await _channel.invokeMethod<bool>('shareProduct', {
      'name': product.name,
      'price': '₹${product.price}',
      // Store homepage: no product-detail URL format is assumed.
      'website': SiteLinks.website,
    });
  }
}
