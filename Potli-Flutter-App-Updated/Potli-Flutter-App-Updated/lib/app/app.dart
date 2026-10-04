import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/app_theme.dart';
import '../views/auth/auth_views.dart';
import '../views/cart/checkout_views.dart';
import '../views/onboarding/launch_views.dart';
import '../views/profile/account_pages.dart';
import '../views/profile/address_form_view.dart';
import '../views/shop/shop_views.dart';
import '../views/support/support_views.dart';
import 'routes.dart';

class PotliApp extends StatelessWidget {
  const PotliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'POTLI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: Routes.splash,
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 420),
      getPages: [
        GetPage(name: Routes.splash, page: SplashView.new),
        GetPage(name: Routes.onboarding, page: OnboardingView.new),
        GetPage(name: Routes.login, page: LoginView.new),
        GetPage(name: Routes.register, page: RegisterView.new),
        GetPage(name: Routes.shell, page: ShopShell.new),
        GetPage(name: Routes.search, page: SearchView.new),
        GetPage(name: Routes.categories, page: CategoriesView.new),
        GetPage(name: Routes.menu, page: DrawerMenuView.new),
        GetPage(name: Routes.subCategories, page: SubCategoriesView.new),
        GetPage(name: Routes.listing, page: ProductListingView.new),
        GetPage(name: Routes.detail, page: ProductDetailView.new),
        GetPage(name: Routes.wishlist, page: WishlistView.new),
        GetPage(name: Routes.checkout, page: CheckoutView.new),
        GetPage(name: Routes.success, page: OrderSuccessView.new),
        GetPage(name: Routes.orders, page: OrdersView.new),
        GetPage(name: Routes.addressBook, page: AddressBookView.new),
        GetPage(name: Routes.addressForm, page: AddressFormView.new),
        GetPage(name: Routes.paymentMethods, page: PaymentMethodsView.new),
        GetPage(name: Routes.notifications, page: NotificationsView.new),
        GetPage(name: Routes.potliCredits, page: PotliCreditsView.new),
        GetPage(name: Routes.wallet, page: WalletView.new),
        GetPage(
          name: Routes.communicationPreferences,
          page: CommunicationPreferencesView.new,
        ),
        GetPage(name: Routes.support, page: SupportTicketListView.new),
      ],
    );
  }
}
