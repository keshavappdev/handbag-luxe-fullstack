import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes.dart';
import '../../controllers/app_controllers.dart';
import '../../utils/app_theme.dart';
import '../../utils/asset_paths.dart';
import '../../widgets/luxury_widgets.dart';

class LoginView extends StatelessWidget {
  LoginView({super.key});

  final mobile = TextEditingController();
  final password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Scaffold(
      backgroundColor: KColors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * .43,
                  width: double.infinity,
                  child: const LuxuryImage(
                    path: AssetPaths.editorialModel,
                    alignment: Alignment.topCenter,
                  ),
                ),
                const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: BrandWordmark(color: KColors.white, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 38, 24, 44),
            sliver: SliverList.list(
              children: [
                Text(
                  auth.isReturningUser ? 'WELCOME\nBACK' : 'WELCOME',
                  style: context.textTheme.editorialSmall,
                ),
                const SizedBox(height: 34),
                TextField(
                  controller: mobile,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'MOBILE NUMBER'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'PASSWORD'),
                ),
                Obx(
                  () => auth.errorMessage.value.isEmpty
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            auth.errorMessage.value,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 28),
                Obx(
                  () => FullWidthButton(
                    label: 'SIGN IN',
                    busy: auth.isBusy.value,
                    onPressed: auth.isBusy.value
                        ? null
                        : () => auth.login(
                            mobile: mobile.text.trim(),
                            password: password.text,
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                FullWidthButton(
                  label: 'CREATE ACCOUNT',
                  inverse: true,
                  onPressed: () => Get.toNamed(Routes.register),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => FullWidthButton(
                    label: 'CONTINUE WITH GOOGLE',
                    inverse: true,
                    busy: auth.isBusy.value,
                    onPressed: auth.isBusy.value ? null : auth.signInWithGoogle,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: auth.continueAsGuest,
                  child: const MicroLabel('CONTINUE AS GUEST'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RegisterView extends StatelessWidget {
  RegisterView({super.key});

  final name = TextEditingController();
  final email = TextEditingController();
  final mobile = TextEditingController();
  final password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Scaffold(
      appBar: const LuxuryHeader(showBack: true),
      backgroundColor: KColors.white,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
        children: [
          const MicroLabel('POTLI MEMBERSHIP', color: KColors.gray),
          const SizedBox(height: 16),
          Text(
            'BECOME\nPART OF\nTHE STORY',
            style: context.textTheme.editorialSmall,
          ),
          const SizedBox(height: 44),
          TextField(
            controller: name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'FULL NAME'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'EMAIL'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: mobile,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'MOBILE NUMBER'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'PASSWORD'),
          ),
          Obx(
            () => auth.errorMessage.value.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      auth.errorMessage.value,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
          ),
          const SizedBox(height: 32),
          Obx(
            () => FullWidthButton(
              label: 'CREATE ACCOUNT',
              busy: auth.isBusy.value,
              onPressed: auth.isBusy.value
                  ? null
                  : () => auth.register(
                      name: name.text.trim(),
                      email: email.text.trim(),
                      mobile: mobile.text.trim(),
                      password: password.text,
                    ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'By joining, you agree to receive considered updates from POTLI. You can leave at any time.',
            style: TextStyle(fontSize: 10, height: 1.6, color: KColors.gray),
          ),
        ],
      ),
    );
  }
}
