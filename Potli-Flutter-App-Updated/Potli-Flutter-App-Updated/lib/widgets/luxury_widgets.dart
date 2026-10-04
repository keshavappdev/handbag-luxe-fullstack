import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/routes.dart';
import '../controllers/app_controllers.dart';
import '../models/product.dart';
import '../utils/app_theme.dart';
import '../utils/asset_paths.dart';

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.color = KColors.black, this.fontSize = 18});

  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Text(
    'POTLI',
    maxLines: 1,
    style: context.textTheme.editorialSmall.copyWith(
      color: color,
      fontSize: fontSize,
      height: 1,
      letterSpacing: fontSize * .28,
      fontWeight: FontWeight.w500,
    ),
  );
}

class OfficialBrandLogo extends StatelessWidget {
  const OfficialBrandLogo({
    super.key,
    required this.width,
    this.surface = false,
    this.padding = 4,
  });

  final double width;
  final bool surface;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      AssetPaths.officialLogo,
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );

    if (!surface) return logo;
    return Container(
      width: width,
      padding: EdgeInsets.all(padding),
      color: KColors.white.withValues(alpha: .94),
      child: logo,
    );
  }
}

class MicroLabel extends StatelessWidget {
  const MicroLabel(this.text, {super.key, this.color = KColors.black});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: context.textTheme.micro.copyWith(color: color),
  );
}

class UnderlineAction extends StatelessWidget {
  const UnderlineAction(
    this.label, {
    super.key,
    required this.onTap,
    this.light = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light ? KColors.white : KColors.black;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          padding: const EdgeInsets.only(bottom: 5),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: color, width: 1)),
          ),
          child: Text(
            '$label  →',
            style: TextStyle(
              color: color,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class LuxuryImage extends StatelessWidget {
  const LuxuryImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  final String path;
  final BoxFit fit;
  final Alignment alignment;

  static const _placeholder = ColoredBox(color: Color(0xFFF2F0EC));

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) {
      // TEMP DEBUG — remove once the homepage blank-gap issue is found.
      debugPrint('LuxuryImage: empty path passed in — showing placeholder');
      return _placeholder;
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: fit,
        alignment: alignment,
        filterQuality: FilterQuality.high,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _placeholder,
        errorBuilder: (context, error, stackTrace) {
          // TEMP DEBUG — remove once the homepage blank-gap issue is found.
          debugPrint('LuxuryImage FAILED to load: $path\n  error: $error');
          return _placeholder;
        },
      );
    }
    return Image.asset(
      path,
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.high,
      frameBuilder: (context, child, frame, synchronous) {
        return AnimatedOpacity(
          opacity: synchronous || frame != null ? 1 : 0,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOut,
          child: child,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // TEMP DEBUG — remove once the homepage blank-gap issue is found.
        debugPrint(
          'LuxuryImage FAILED to load bundled asset: $path\n  error: $error',
        );
        return _placeholder;
      },
    );
  }
}

class LuxuryHeader extends StatelessWidget implements PreferredSizeWidget {
  const LuxuryHeader({
    super.key,
    this.transparent = false,
    this.light = false,
    this.showBack = false,
  });

  final bool transparent;
  final bool light;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final color = light ? KColors.white : KColors.black;
    final cart = Get.find<CartController>();
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: transparent ? Colors.transparent : KColors.offWhite,
      foregroundColor: color,
      surfaceTintColor: Colors.transparent,
      leadingWidth: 58,
      leading: IconButton(
        icon: Icon(showBack ? Icons.arrow_back : Icons.menu, size: 21),
        onPressed: showBack ? Get.back : () => Get.toNamed(Routes.menu),
      ),
      title: BrandWordmark(color: color, fontSize: 15),
      actions: [
        Obx(() {
          final wishlist = Get.find<WishlistController>();
          final count = wishlist.ids.length;
          return IconButton(
            onPressed: () => Get.toNamed(Routes.wishlist),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  count > 0 ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                ),
                if (count > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 14),
                      height: 14,
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      color: color,
                      alignment: Alignment.center,
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: light ? KColors.black : KColors.white,
                          fontSize: 7,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
        Obx(
          () => InkWell(
            onTap: () {
              if (Get.currentRoute == Routes.shell) {
                Get.find<NavigationController>().go(2);
              } else {
                Get.offAllNamed(Routes.shell);
                Get.find<NavigationController>().go(2);
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16, left: 4),
              child: Center(
                child: Text(
                  'BAG ${cart.count == 0 ? '' : '(${cart.count})'}',
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ProductTile extends StatelessWidget {
  const ProductTile({
    super.key,
    required this.product,
    required this.height,
    this.index = 0,
  });

  final Product product;
  final double height;
  final int index;

  @override
  Widget build(BuildContext context) {
    final catalog = Get.find<CatalogController>();
    final wishlist = Get.find<WishlistController>();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 450 + index * 90),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 18 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: InkWell(
        onTap: () => catalog.openProduct(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'product-${product.id}',
                  child: SizedBox(
                    width: double.infinity,
                    height: height,
                    child: LuxuryImage(path: product.image),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MicroLabel(product.category, color: KColors.gray),
                      const SizedBox(height: 5),
                      Text(
                        product.name,
                        style: context.textTheme.productTitle.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${product.price}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: KColors.gray,
                        ),
                      ),
                    ],
                  ),
                ),
                Obx(
                  () => IconButton(
                    onPressed: () => wishlist.toggle(product),
                    visualDensity: VisualDensity.compact,
                    iconSize: 19,
                    icon: Icon(
                      wishlist.contains(product.id)
                          ? Icons.favorite
                          : Icons.favorite_border,
                    ),
                  ),
                ),
              ],
            ),
            if (product.socialProof.isNotEmpty) ...[
              const SizedBox(height: 9),
              ProductProofBadge(label: product.socialProof.first),
            ],
          ],
        ),
      ),
    );
  }
}

class ProductProofBadge extends StatelessWidget {
  const ProductProofBadge({
    super.key,
    required this.label,
    this.inverse = false,
  });

  final String label;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final normalized = label.toLowerCase();

    final IconData icon;

    if (normalized.contains('view')) {
      icon = Icons.visibility_outlined;
    } else if (normalized.contains('stock') ||
        normalized.contains('left') ||
        normalized.contains('drop')) {
      icon = Icons.shopping_bag_outlined;
    } else {
      icon = Icons.favorite;
    }

    const brandBlue = KColors.charcoal;

    final foreground = inverse
        ? KColors.white.withValues(alpha: .88)
        : brandBlue.withValues(alpha: .82);

    final background = inverse
        ? KColors.black.withValues(alpha: .88)
        : brandBlue.withValues(alpha: .075);

    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foreground),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 9,
                fontWeight: FontWeight.w500,
                letterSpacing: .15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FullWidthButton extends StatelessWidget {
  const FullWidthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.inverse = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final bool inverse;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 58,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        shape: const RoundedRectangleBorder(),
        elevation: 0,
        backgroundColor: inverse ? KColors.white : KColors.black,
        foregroundColor: inverse ? KColors.black : KColors.white,
        side: BorderSide(color: inverse ? KColors.black : KColors.black),
      ),
      child: busy
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 1,
                color: KColors.white,
              ),
            )
          : Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 2.2,
                fontWeight: FontWeight.w600,
              ),
            ),
    ),
  );
}

class SectionDivider extends StatelessWidget {
  const SectionDivider({super.key});

  @override
  Widget build(BuildContext context) => const Divider(height: 1, thickness: 1);
}
