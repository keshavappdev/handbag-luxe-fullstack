import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/routes.dart';
import '../../controllers/app_controllers.dart';
import '../../utils/app_theme.dart';
import '../../utils/site_links.dart';
import '../../widgets/luxury_widgets.dart';
import 'user_profile_view.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Scaffold(
      appBar: const LuxuryHeader(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 44, 20, 80),
        children: [
          const MicroLabel('YOUR POTLI', color: KColors.gray),
          const SizedBox(height: 14),
          Obx(() {
            final name = auth.username.value;
            return Text(
              name.isNotEmpty
                  ? 'HELLO,\n${name.toUpperCase()}.'
                  : 'HELLO,\nBEAUTIFUL.',
              style: context.textTheme.editorialSmall,
            );
          }),
          const SizedBox(height: 50),
          Obx(() {
            if (!auth.isSignedIn.value) {
              return _ProfileLink(
                label: 'SIGN IN',
                onTap: () => Get.toNamed(Routes.login),
              );
            }
            return Column(
              children: [
                _ProfileLink(
                  label: 'MY PROFILE',
                  onTap: () => Get.to(() => const UserProfileView()),
                ),
                _ProfileLink(
                  label: 'MY ORDERS',
                  onTap: () => Get.toNamed(Routes.orders),
                ),
                _ProfileLink(
                  label: 'MY WALLET',
                  onTap: () => Get.toNamed(Routes.wallet),
                ),
                _ProfileLink(
                  label: 'ADDRESS BOOK',
                  onTap: () => Get.toNamed(Routes.addressBook),
                ),
                _ProfileLink(
                  label: 'PAYMENT METHODS',
                  onTap: () => Get.toNamed(Routes.paymentMethods),
                ),
                _ProfileLink(
                  label: 'POTLI CREDITS',
                  onTap: () => Get.toNamed(Routes.potliCredits),
                ),
                _ProfileLink(
                  label: 'NOTIFICATIONS',
                  onTap: () => Get.toNamed(Routes.notifications),
                ),
                _ProfileLink(
                  label: 'COMMUNICATION PREFERENCES',
                  onTap: () => Get.toNamed(Routes.communicationPreferences),
                ),
              ],
            );
          }),
          _ProfileLink(
            label: 'WISHLIST',
            onTap: () => Get.toNamed(Routes.wishlist),
          ),
          _ProfileLink(
            label: 'CUSTOMER CARE',
            onTap: () => Get.toNamed(Routes.support),
          ),
          _ProfileLink(
            label: 'ABOUT POTLI',
            onTap: () => launchUrl(
              Uri.parse(SiteLinks.aboutUs),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const SizedBox(height: 48),
          const SectionDivider(),
          const SizedBox(height: 30),
          const BrandWordmark(fontSize: 14),
          const SizedBox(height: 12),
          const FittedBox(
            fit: BoxFit.scaleDown,
            child: MicroLabel('UNAPOLOGETICALLY YOU.', color: KColors.gray),
          ),
          const SizedBox(height: 36),
          Obx(
            () => auth.isSignedIn.value
                ? TextButton(
                    onPressed: auth.signOut,
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.zero,
                    ),
                    child: const MicroLabel('SIGN OUT  →'),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ProfileLink extends StatelessWidget {
  const _ProfileLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      height: 66,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: KColors.line)),
      ),
      child: Row(
        children: [
          Expanded(child: MicroLabel(label)),
          const Icon(Icons.arrow_forward, size: 18),
        ],
      ),
    ),
  );
}
