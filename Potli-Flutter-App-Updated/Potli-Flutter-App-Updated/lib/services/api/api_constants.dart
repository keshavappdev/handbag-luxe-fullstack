// Node.js compatibility API used by the existing Flutter screens.

// Android emulator default. Override for iOS/physical devices using --dart-define.
const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:4000/api/v1/',
);
const String chatBaseUrl = baseUrl;
const int apiTimeoutSeconds = 50;
const int perPage = 10;

final Uri getSliderApi = Uri.parse('${baseUrl}get_slider_images');
final Uri getCatApi = Uri.parse('${baseUrl}get_categories');
final Uri getSectionApi = Uri.parse('${baseUrl}get_sections');
final Uri getSettingApi = Uri.parse('${baseUrl}get_settings');
final Uri getSubcatApi = Uri.parse(
  '${baseUrl}get_subcategories_by_category_id',
);
final Uri getCategoryCollectionItemsApi = Uri.parse(
  '${baseUrl}get_category_collection_items',
);
final Uri getProductApi = Uri.parse('${baseUrl}get_products');
final Uri manageCartApi = Uri.parse('${baseUrl}manage_cart');
final Uri removeFromCartApi = Uri.parse('${baseUrl}remove_from_cart');
final Uri getUserLoginApi = Uri.parse('${baseUrl}login');
final Uri getUserSignUpApi = Uri.parse('${baseUrl}register_user');
final Uri updateUserApi = Uri.parse('${baseUrl}update_user');
final Uri setFavoriteApi = Uri.parse('${baseUrl}add_to_favorites');
final Uri removeFavApi = Uri.parse('${baseUrl}remove_from_favorites');
final Uri getCartApi = Uri.parse('${baseUrl}get_user_cart');
final Uri getFavApi = Uri.parse('${baseUrl}get_favorites');
final Uri getNotificationApi = Uri.parse('${baseUrl}get_notifications');
final Uri getAddressApi = Uri.parse('${baseUrl}get_address');
final Uri deleteAddressApi = Uri.parse('${baseUrl}delete_address');
final Uri getAddAddressApi = Uri.parse('${baseUrl}add_address');
final Uri updateAddressApi = Uri.parse('${baseUrl}update_address');
final Uri placeOrderApi = Uri.parse('${baseUrl}place_order');
final Uri validatePromoApi = Uri.parse('${baseUrl}validate_promo_code');
final Uri getOrderApi = Uri.parse('${baseUrl}get_orders');
final Uri updateOrderApi = Uri.parse('${baseUrl}update_order_status');
final Uri addTransactionApi = Uri.parse('${baseUrl}add_transaction');
final Uri updateFcmApi = Uri.parse('${baseUrl}update_fcm');
final Uri getWalTranApi = Uri.parse('${baseUrl}transactions');
final Uri deleteOrderApi = Uri.parse('${baseUrl}delete_order');
final Uri razorpayCreateOrderApi = Uri.parse('${baseUrl}razorpay_create_order');
final Uri createWalletOrderApi = Uri.parse('${baseUrl}create_wallet_order');
final Uri verifyPaymentApi = Uri.parse('${baseUrl}verify_payment');
final Uri sendMsgApi = Uri.parse('${baseUrl}send_message');
final Uri signUpUserApi = Uri.parse('${baseUrl}sign_up');
final Uri getInvoiceHTML = Uri.parse('${baseUrl}get_invoice_html');
final Uri getInvoiceDataApi = Uri.parse('${baseUrl}get_invoice_data');
final Uri getOrderTrackingApi = Uri.parse('${baseUrl}get_order_tracking');

// Customer Support: tickets + per-ticket chat.
final Uri getTicketTypesApi = Uri.parse('${baseUrl}get_ticket_types');
final Uri addTicketApi = Uri.parse('${baseUrl}add_ticket');
final Uri editTicketApi = Uri.parse('${baseUrl}edit_ticket');
final Uri getTicketsApi = Uri.parse('${baseUrl}get_tickets');
final Uri getTicketMessagesApi = Uri.parse('${baseUrl}get_messages');

// Return / Exchange / Potli Credit / Personalization / Complete the Look
final Uri submitReturnRequestApi = Uri.parse('${baseUrl}submit_return_request');
final Uri getMyReturnRequestsApi = Uri.parse(
  '${baseUrl}get_my_return_requests',
);
final Uri submitExchangeRequestApi = Uri.parse(
  '${baseUrl}submit_exchange_request',
);
final Uri getMyExchangeRequestsApi = Uri.parse(
  '${baseUrl}get_my_exchange_requests',
);
final Uri getExchangeVariantsApi = Uri.parse('${baseUrl}get_exchange_variants');
final Uri getMyPotliCreditsApi = Uri.parse(
  '${baseUrl}get_my_potli_credits',
);
final Uri validateCreditCodeApi = Uri.parse('${baseUrl}validate_credit_code');
final Uri getPersonalizationSettingsApi = Uri.parse(
  '${baseUrl}get_personalization_settings',
);
final Uri savePersonalizationPreviewApi = Uri.parse(
  '${baseUrl}save_personalization_preview',
);
final Uri getCompleteTheLookApi = Uri.parse('${baseUrl}get_complete_the_look');
final Uri getAppDeliveryChargeApi = Uri.parse('${baseUrl}get_delivery_charge');
final Uri updatePromoPreferencesApi = Uri.parse(
  '${baseUrl}update_promo_preferences',
);

// Request/response field keys shared with the backend.
const String kId = 'id';
const String kType = 'type';
const String kTypeId = 'type_id';
const String kCategoryId = 'category_id';
const String kSubCategoryId = 'sub_category_id';
const String kSubcategoryId = 'subcategory_id';
const String kProductId = 'product_id';
const String kVariantId = 'variant_id';
const String kLimit = 'limit';
const String kOffset = 'offset';
