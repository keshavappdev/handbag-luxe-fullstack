import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/app_controllers.dart';
import '../../utils/app_theme.dart';
import '../../widgets/luxury_widgets.dart';

/// Lets the signed-in customer view and edit their name/email/mobile.
/// Mobile matters beyond just being the login identity: the checkout
/// address form requires a phone number, and a Google sign-up never
/// collects one — this is how those customers add one so they can
/// actually place an order. update_user now validates it for uniqueness
/// server-side (edit_unique[users.mobile.<id>]) the same way a new
/// registration does.
class UserProfileView extends StatefulWidget {
  const UserProfileView({super.key});

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _mobile;
  bool _editing = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    final auth = Get.find<AuthController>();
    _name = TextEditingController(text: auth.username.value);
    _email = TextEditingController(text: auth.email.value);
    _mobile = TextEditingController(text: auth.mobile.value);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = Get.find<AuthController>();
    setState(() => _message = null);
    final mobileDigits = _mobile.text.trim();
    if (mobileDigits.isNotEmpty && mobileDigits.length != 10) {
      setState(() => _message = 'Mobile number must be 10 digits.');
      return;
    }
    final success = await auth.updateProfile(
      newUsername: _name.text.trim(),
      newEmail: _email.text.trim(),
      newMobile: _mobile.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _editing = !success;
      _message = success
          ? 'Profile updated.'
          : (auth.errorMessage.value.isNotEmpty
                ? auth.errorMessage.value
                : 'Could not update your profile.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Scaffold(
      appBar: const LuxuryHeader(showBack: true),
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 60),
          children: [
            Text('MY\nPROFILE', style: context.textTheme.editorialSmall),
            const SizedBox(height: 40),
            const MicroLabel('NAME'),
            const SizedBox(height: 8),
            _editing
                ? TextField(
                    controller: _name,
                    decoration: const InputDecoration(hintText: 'Your name'),
                  )
                : Text(
                    auth.username.value.isEmpty
                        ? 'Not set'
                        : auth.username.value,
                    style: const TextStyle(fontSize: 16),
                  ),
            const SizedBox(height: 26),
            const MicroLabel('EMAIL'),
            const SizedBox(height: 8),
            _editing
                ? TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(hintText: 'Your email'),
                  )
                : Text(
                    auth.email.value.isEmpty ? 'Not set' : auth.email.value,
                    style: const TextStyle(fontSize: 16),
                  ),
            const SizedBox(height: 26),
            const MicroLabel('MOBILE'),
            const SizedBox(height: 8),
            _editing
                ? TextField(
                    controller: _mobile,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: const InputDecoration(
                      hintText: 'Your mobile number',
                    ),
                  )
                : Text(
                    auth.mobile.value.isEmpty ? 'Not set' : auth.mobile.value,
                    style: const TextStyle(fontSize: 16),
                  ),
            const SizedBox(height: 40),
            if (_message != null) ...[
              Text(
                _message!,
                style: TextStyle(
                  fontSize: 12,
                  color: _message == 'Profile updated.'
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              const SizedBox(height: 16),
            ],
            FullWidthButton(
              label: _editing ? 'SAVE' : 'EDIT PROFILE',
              busy: auth.isBusy.value,
              onPressed: auth.isBusy.value
                  ? null
                  : () {
                      if (_editing) {
                        _save();
                      } else {
                        setState(() {
                          _editing = true;
                          _message = null;
                        });
                      }
                    },
            ),
            if (_editing) ...[
              const SizedBox(height: 10),
              FullWidthButton(
                label: 'CANCEL',
                inverse: true,
                onPressed: () {
                  setState(() {
                    _editing = false;
                    _message = null;
                    _name.text = auth.username.value;
                    _email.text = auth.email.value;
                    _mobile.text = auth.mobile.value;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
