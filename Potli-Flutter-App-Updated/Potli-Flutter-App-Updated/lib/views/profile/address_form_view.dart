import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../models/address.dart';
import '../../services/api/address_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/luxury_widgets.dart';

class AddressFormView extends StatefulWidget {
  const AddressFormView({super.key});

  @override
  State<AddressFormView> createState() => _AddressFormViewState();
}

class _AddressFormViewState extends State<AddressFormView> {
  Address? get _editing => Get.arguments as Address?;

  late final name = TextEditingController(text: _editing?.name);
  late final mobile = TextEditingController(text: _editing?.mobile);
  late final address = TextEditingController(text: _editing?.address);
  late final city = TextEditingController(text: _editing?.city);
  late final pincode = TextEditingController(text: _editing?.pincode);
  final country = TextEditingController(text: 'India');
  String _state = '';

  bool busy = false;
  String? error;
  bool _pincodeLoading = false;
  String? _pincodeMessage;
  Timer? _pincodeDebounce;

  @override
  void dispose() {
    _pincodeDebounce?.cancel();
    super.dispose();
  }

  void _onPincodeChanged(String value) {
    _pincodeDebounce?.cancel();
    final pin = value.replaceAll(RegExp(r'\D'), '');
    if (pin.length != 6) {
      setState(() => _pincodeMessage = null);
      return;
    }
    _pincodeDebounce = Timer(
      const Duration(milliseconds: 400),
      () => _lookupPincode(pin),
    );
  }

  /// Same free India Post API the website's checkout/address pages use to
  /// auto-fill city + state + country from a 6-digit pincode.
  Future<void> _lookupPincode(String pin) async {
    setState(() {
      _pincodeLoading = true;
      _pincodeMessage = 'Looking up pincode…';
    });
    try {
      final response = await http
          .get(Uri.parse('https://api.postalpincode.in/pincode/$pin'))
          .timeout(const Duration(seconds: 8));
      final decoded = jsonDecode(response.body);
      final record = decoded is List && decoded.isNotEmpty
          ? decoded.first
          : null;
      final postOffices = record is Map ? record['PostOffice'] : null;
      if (record is Map &&
          record['Status'] == 'Success' &&
          postOffices is List &&
          postOffices.isNotEmpty) {
        final po = postOffices.first as Map;
        setState(() {
          city.text = '${po['District'] ?? po['Block'] ?? po['Name'] ?? ''}';
          _state = '${po['State'] ?? ''}';
          country.text = '${po['Country'] ?? 'India'}';
          _pincodeMessage = null;
        });
      } else {
        setState(
          () => _pincodeMessage = 'Please enter a correct Indian pincode.',
        );
      }
    } catch (_) {
      setState(
        () => _pincodeMessage =
            'Could not look up pincode — check your connection.',
      );
    } finally {
      if (mounted) setState(() => _pincodeLoading = false);
    }
  }

  Future<void> _save() async {
    if (mobile.text.trim().length != 10) {
      setState(() => error = 'Mobile number must be 10 digits.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    final service = Get.find<AddressService>();
    try {
      final success = _editing != null
          ? await service.updateAddress(
              id: _editing!.id,
              name: name.text.trim(),
              mobile: mobile.text.trim(),
              address: address.text.trim(),
              cityName: city.text.trim(),
              pincode: pincode.text.trim(),
              state: _state,
              country: country.text.trim(),
            )
          : await service.addAddress(
                  name: name.text.trim(),
                  mobile: mobile.text.trim(),
                  address: address.text.trim(),
                  cityName: city.text.trim(),
                  pincode: pincode.text.trim(),
                  state: _state,
                  country: country.text.trim(),
                ) !=
                null;
      if (!success) {
        setState(() => error = 'Could not save address');
        return;
      }
      Get.back();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _editing != null;
    return Scaffold(
      appBar: const LuxuryHeader(showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 40),
        children: [
          Text(
            isEditing ? 'EDIT\nADDRESS' : 'ADD NEW\nADDRESS',
            style: context.textTheme.editorialSmall,
          ),
          const SizedBox(height: 36),
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'FULL NAME'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: mobile,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: const InputDecoration(labelText: 'MOBILE NUMBER'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: address,
            decoration: const InputDecoration(labelText: 'ADDRESS'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: pincode,
            keyboardType: TextInputType.number,
            onChanged: _onPincodeChanged,
            decoration: InputDecoration(
              labelText: 'PIN CODE',
              suffixIcon: _pincodeLoading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
          ),
          if (_pincodeMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              _pincodeMessage!,
              style: TextStyle(
                fontSize: 11,
                color: _pincodeLoading ? KColors.gray : Colors.red,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: city,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'CITY',
                    hintText: 'Auto-filled from pincode',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: country,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'COUNTRY'),
                ),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            Text(
              error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
          const SizedBox(height: 32),
          FullWidthButton(
            label: isEditing ? 'SAVE CHANGES' : 'SAVE ADDRESS',
            busy: busy,
            onPressed: busy ? null : _save,
          ),
        ],
      ),
    );
  }
}
