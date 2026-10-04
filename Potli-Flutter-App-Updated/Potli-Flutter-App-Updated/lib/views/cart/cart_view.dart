import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes.dart';
import '../../controllers/app_controllers.dart';
import '../../models/product.dart';
import '../../utils/app_theme.dart';
import '../../utils/personalization.dart';
import '../../widgets/luxury_widgets.dart';

class CartView extends StatelessWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();
    final navigation = Get.find<NavigationController>();
    return Scaffold(
      appBar: const LuxuryHeader(),
      body: Obx(() {
        if (cart.lines.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'YOUR BAG\nIS QUIET',
                    textAlign: TextAlign.center,
                    style: context.textTheme.editorialSmall,
                  ),
                  const SizedBox(height: 18),
                  const MicroLabel(
                    'DISCOVER SOMETHING THAT SPEAKS TO YOU',
                    color: KColors.gray,
                  ),
                  const SizedBox(height: 32),
                  FullWidthButton(
                    label: 'DISCOVER THE EDIT',
                    onPressed: () => navigation.go(1),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 34, 20, 28),
                itemCount: cart.lines.length + 1,
                separatorBuilder: (_, __) => const SectionDivider(),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: Text(
                        'SHOPPING\nBAG',
                        style: context.textTheme.editorialSmall,
                      ),
                    );
                  }
                  return _CartLineView(line: cart.lines[index - 1]);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              decoration: const BoxDecoration(
                color: KColors.white,
                border: Border(top: BorderSide(color: KColors.line)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    _MoneyRow(label: 'SUBTOTAL', value: '₹${cart.subtotal}'),
                    const SizedBox(height: 10),
                    _MoneyRow(
                      label: 'DELIVERY',
                      value: cart.delivery == 0
                          ? 'COMPLIMENTARY'
                          : '₹${cart.delivery}',
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 17),
                      child: SectionDivider(),
                    ),
                    _MoneyRow(
                      label: 'TOTAL',
                      value: '₹${cart.total}',
                      strong: true,
                    ),
                    const SizedBox(height: 18),
                    FullWidthButton(
                      label: 'PROCEED TO CHECKOUT',
                      onPressed: () =>
                          Get.find<AuthController>().isSignedIn.value
                          ? Get.toNamed(Routes.checkout)
                          : Get.toNamed(Routes.login),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _CartLineView extends StatelessWidget {
  const _CartLineView({required this.line});
  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 124,
            height: 164,
            child: LuxuryImage(path: line.product.image),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: SizedBox(
              height: 164,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MicroLabel(line.product.category, color: KColors.gray),
                  const SizedBox(height: 7),
                  Text(
                    line.product.name,
                    style: const TextStyle(fontSize: 14, letterSpacing: 1),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '₹${line.product.price}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (decodePersonalization(line.personalizationText)
                      .text
                      .isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Builder(
                      builder: (context) {
                        final decoded = decodePersonalization(
                          line.personalizationText,
                        );
                        return Row(
                          children: [
                            if (decoded.hasImage) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  decoded.image,
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                '✎ Personalized: "${decoded.text}"',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: KColors.gray,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => cart.decrement(line.product),
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.remove, size: 17),
                      ),
                      Text(
                        '${line.quantity}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      IconButton(
                        onPressed: () => cart.add(line.product),
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.add, size: 17),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => cart.remove(line.product),
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close, size: 17),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.strong = false,
  });
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      MicroLabel(label, color: strong ? KColors.black : KColors.gray),
      const Spacer(),
      Text(
        value,
        style: TextStyle(
          fontSize: strong ? 15 : 11,
          fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
          letterSpacing: strong ? .4 : 1,
        ),
      ),
    ],
  );
}
