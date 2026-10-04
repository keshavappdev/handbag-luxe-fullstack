import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/routes.dart';
import '../../controllers/app_controllers.dart';
import '../../models/category_node.dart';
import '../../models/product.dart';
import '../../services/api/product_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/asset_paths.dart';
import '../../utils/personalization.dart';
import '../../widgets/luxury_widgets.dart';
import '../../widgets/site_footer.dart';
import '../cart/cart_view.dart';
import '../discover/discover_view.dart';
import '../home/home_view.dart';
import '../profile/profile_view.dart';

class ShopShell extends StatelessWidget {
  const ShopShell({super.key});

  @override
  Widget build(BuildContext context) {
    final navigation = Get.find<NavigationController>();
    final cart = Get.find<CartController>();
    const pages = [HomeView(), DiscoverView(), CartView(), ProfileView()];
    return Obx(() {
      final chromeVisible =
          navigation.index.value != 0 || navigation.homeChromeVisible.value;
      return Scaffold(
        backgroundColor: KColors.white,
        body: IndexedStack(index: navigation.index.value, children: pages),
        bottomNavigationBar: PotliBottomNavigation(
          visible: chromeVisible,
          selectedIndex: navigation.index.value,
          cartCount: cart.count,
          onHome: () => navigation.go(0),
          onMenu: () => Get.toNamed(Routes.categories),
          onSearch: () => Get.toNamed(Routes.search),
          onAccount: () => navigation.go(3),
          onBag: () => navigation.go(2),
        ),
      );
    });
  }
}

class PotliBottomNavigation extends StatelessWidget {
  const PotliBottomNavigation({
    required this.visible,
    required this.selectedIndex,
    required this.cartCount,
    required this.onHome,
    required this.onMenu,
    required this.onSearch,
    required this.onAccount,
    required this.onBag,
  });

  final bool visible;
  final int selectedIndex;
  final int cartCount;
  final VoidCallback onHome;
  final VoidCallback onMenu;
  final VoidCallback onSearch;
  final VoidCallback onAccount;
  final VoidCallback onBag;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      height: 58 + bottom,
      color: KColors.white,
      padding: EdgeInsets.only(bottom: bottom),
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 720),
        curve: Curves.easeOutCubic,
        child: IgnorePointer(
          ignoring: !visible,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: KColors.line, width: .7)),
            ),
            child: Row(
              children: [
                _IconNavItem(
                  icon: Icons.home_outlined,
                  active: selectedIndex == 0,
                  onTap: onHome,
                ),
                _TextNavItem(label: 'SHOP', onTap: onMenu),
                _IconNavItem(
                  icon: Icons.search,
                  active: false,
                  onTap: onSearch,
                ),
                _TextNavItem(
                  label: 'ACCOUNT',
                  active: selectedIndex == 3,
                  onTap: onAccount,
                ),
                _IconNavItem(
                  icon: Icons.shopping_bag_outlined,
                  active: selectedIndex == 2,
                  badge: cartCount,
                  onTap: onBag,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconNavItem extends StatelessWidget {
  const _IconNavItem({
    required this.icon,
    required this.active,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final bool active;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Center(
        child: SizedBox(
          width: 34,
          height: 38,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 20, color: KColors.black),
              if (badge > 0)
                Positioned(
                  top: 3,
                  right: 1,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 14),
                    height: 14,
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    color: KColors.black,
                    alignment: Alignment.center,
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        color: KColors.white,
                        fontSize: 7,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              if (active)
                const Positioned(
                  bottom: 3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: KColors.black,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox.square(dimension: 3),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TextNavItem extends StatelessWidget {
  const _TextNavItem({
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Center(
        child: Container(
          padding: const EdgeInsets.only(bottom: 3),
          decoration: active
              ? const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: KColors.black, width: .8),
                  ),
                )
              : null,
          child: Text(
            label,
            style: const TextStyle(
              color: KColors.black,
              fontSize: 9,
              fontWeight: FontWeight.w400,
              letterSpacing: .7,
            ),
          ),
        ),
      ),
    ),
  );
}

class CategoriesView extends StatelessWidget {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = Get.find<CatalogController>();
    return Scaffold(
      appBar: const LuxuryHeader(showBack: true),
      body: Obx(() {
        final categories = catalog.menuCategories;
        if (catalog.categoriesLoading.value && categories.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          itemCount: categories.length + 1,
          padding: const EdgeInsets.only(bottom: 30),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 36, 20, 28),
                child: Text(
                  'SHOP\nBY CATEGORY',
                  style: context.textTheme.editorialSmall,
                ),
              );
            }
            final category = categories[index - 1];
            final image = category.image.isNotEmpty
                ? category.image
                : AssetPaths.categoryFallbacks[(index - 1) %
                      AssetPaths.categoryFallbacks.length];
            return InkWell(
              onTap: () => Get.toNamed(
                Routes.subCategories,
                arguments: SubCategoryArgs(
                  l1Id: catalog.topCategories.first.id,
                  l2Id: category.id,
                  l2Name: category.name,
                ),
              ),
              child: Stack(
                children: [
                  SizedBox(
                    height: index.isEven ? 300 : 390,
                    width: double.infinity,
                    child: LuxuryImage(path: image),
                  ),
                  Positioned.fill(
                    child: ColoredBox(
                      color: KColors.black.withValues(alpha: .18),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 22,
                    child: Row(
                      children: [
                        Text(
                          category.name.toUpperCase(),
                          style: const TextStyle(
                            color: KColors.white,
                            fontSize: 24,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward,
                          color: KColors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}

/// The header hamburger's destination — separate from [CategoriesView]
/// (the bottom nav's "MENU" tab, which stays a pure category browser).
/// Shows the site-wide footer content (policies, company info, contact)
/// moved here from the bottom of the home page.
class DrawerMenuView extends StatelessWidget {
  const DrawerMenuView({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    appBar: LuxuryHeader(showBack: true),
    body: SingleChildScrollView(child: SiteFooter()),
  );
}

class SubCategoryArgs {
  const SubCategoryArgs({
    required this.l1Id,
    required this.l2Id,
    required this.l2Name,
  });

  final String l1Id;
  final String l2Id;
  final String l2Name;
}

/// The third category layer (e.g. "Potli Bag", "Shoulder Bags" under
/// "Bags"). Mirrors CategoriesView's visual style; tapping a tile here is
/// what actually filters the product listing.
class SubCategoriesView extends StatefulWidget {
  const SubCategoriesView({super.key});

  @override
  State<SubCategoriesView> createState() => _SubCategoriesViewState();
}

class _SubCategoriesViewState extends State<SubCategoriesView> {
  late final SubCategoryArgs args = Get.arguments as SubCategoryArgs;
  late final Future<List<CategoryNode>> _future = Get.find<CatalogController>()
      .loadCollectionItems(args.l1Id, args.l2Id);

  @override
  Widget build(BuildContext context) {
    final catalog = Get.find<CatalogController>();
    return Scaffold(
      appBar: const LuxuryHeader(showBack: true),
      body: FutureBuilder<List<CategoryNode>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? const [];
          return ListView.builder(
            itemCount: items.length + 1,
            padding: const EdgeInsets.only(bottom: 30),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 36, 20, 28),
                  child: Text(
                    args.l2Name.toUpperCase(),
                    style: context.textTheme.editorialSmall,
                  ),
                );
              }
              final item = items[index - 1];
              final image = item.image.isNotEmpty
                  ? item.image
                  : AssetPaths.categoryFallbacks[(index - 1) %
                        AssetPaths.categoryFallbacks.length];
              return InkWell(
                onTap: () => catalog.openCategoryById(item.id, item.name),
                child: Stack(
                  children: [
                    SizedBox(
                      height: index.isEven ? 300 : 390,
                      width: double.infinity,
                      child: LuxuryImage(path: image),
                    ),
                    Positioned.fill(
                      child: ColoredBox(
                        color: KColors.black.withValues(alpha: .18),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 22,
                      child: Row(
                        children: [
                          Text(
                            item.name.toUpperCase(),
                            style: const TextStyle(
                              color: KColors.white,
                              fontSize: 24,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward,
                            color: KColors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ProductListingView extends StatelessWidget {
  const ProductListingView({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = Get.find<CatalogController>();
    final title = (Get.arguments as String?) ?? 'THE COLLECTION';
    return Scaffold(
      appBar: const LuxuryHeader(showBack: true),
      body: Obx(() {
        final products = catalog.results;
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 34, 20, 28),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Giving the title its own full-width line (instead of
                    // sharing a Row with the piece count) wasn't enough on
                    // its own — at this style's 46px size, a single long word
                    // like "COLLECTION" still doesn't fit even the full
                    // device width on narrower phones, so Flutter wrapped it
                    // mid-word ("COLLECTIO" / "N"). FittedBox+maxLines:1
                    // forces one line and scales the whole heading down just
                    // enough to fit instead, however long the title is.
                    SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title.toUpperCase(),
                          maxLines: 1,
                          style: context.textTheme.editorialSmall,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    MicroLabel(
                      '${products.length} PIECES',
                      color: KColors.gray,
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverGrid.builder(
                itemCount: products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 38,
                  childAspectRatio: .41,
                ),
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.only(top: index.isOdd ? 72 : 0),
                  child: ProductTile(
                    product: products[index],
                    height: index.isEven ? 300 : 230,
                    index: index,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        );
      }),
    );
  }
}

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _input = TextEditingController();
  Timer? _debounce;
  List<Product> _results = const [];
  bool _loading = false;
  bool _searched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _searched = false;
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    try {
      // Searches the full catalog server-side rather than filtering
      // whatever page CatalogController.products last happened to hold
      // (which defaults to only the first 10 products) — that was why
      // search only ever seemed to match a handful of items.
      final results = await Get.find<ProductService>().getProducts(
        search: query,
        limit: 50,
      );
      if (!mounted || _input.text.trim() != query) return;
      setState(() {
        _results = results;
        _searched = true;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _searched = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LuxuryHeader(showBack: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
            child: TextField(
              controller: _input,
              autofocus: true,
              onChanged: _onChanged,
              decoration: const InputDecoration(
                labelText: 'SEARCH POTLI',
                suffixIcon: Icon(Icons.search, size: 21),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : !_searched
                ? const SizedBox.shrink()
                : _results.isEmpty
                ? const Center(child: MicroLabel('NO PIECES FOUND'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 50),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const SectionDivider(),
                    itemBuilder: (context, index) =>
                        _SearchResult(product: _results[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchResult extends StatelessWidget {
  const _SearchResult({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => Get.find<CatalogController>().openProduct(product),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 126,
            child: LuxuryImage(path: product.image),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MicroLabel(product.category, color: KColors.gray),
                const SizedBox(height: 9),
                Text(product.name, style: const TextStyle(letterSpacing: 1.2)),
                const SizedBox(height: 7),
                Text('₹${product.price}', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward, size: 18),
        ],
      ),
    ),
  );
}

class WishlistView extends StatelessWidget {
  const WishlistView({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlist = Get.find<WishlistController>();
    return Scaffold(
      appBar: const LuxuryHeader(showBack: true),
      body: Obx(() {
        final products = wishlist.products;
        if (products.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'YOUR EDIT\nAWAITS',
                    textAlign: TextAlign.center,
                    style: context.textTheme.editorialSmall,
                  ),
                  const SizedBox(height: 20),
                  const MicroLabel(
                    'SAVE THE PIECES THAT FEEL LIKE YOU',
                    color: KColors.gray,
                  ),
                ],
              ),
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 30, 12, 60),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 34,
            childAspectRatio: .45,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) =>
              ProductTile(product: products[index], height: 260, index: index),
        );
      }),
    );
  }
}

class ProductDetailView extends StatefulWidget {
  const ProductDetailView({super.key});

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  int imageIndex = 0;
  int colorIndex = 0;
  int quantity = 1;
  Product? detailed;

  String? personalizationText;
  Future<PersonalizationSettings>? _personalizationSettingsFuture;
  Future<List<Product>>? _completeTheLookFuture;

  @override
  void initState() {
    super.initState();
    final product = Get.arguments as Product;
    Get.find<CatalogController>().fetchProductDetail(product.id).then((result) {
      if (mounted && result != null) setState(() => detailed = result);
    });
    final productService = Get.find<ProductService>();
    if (product.allowPersonalization) {
      _personalizationSettingsFuture = productService
          .getPersonalizationSettings();
    }
    _completeTheLookFuture = productService.getCompleteTheLook(product.id);
  }

  @override
  Widget build(BuildContext context) {
    final product = detailed ?? Get.arguments as Product;
    final cart = Get.find<CartController>();
    final wishlist = Get.find<WishlistController>();
    final images = product.images.isNotEmpty ? product.images : [product.image];
    return Scaffold(
      backgroundColor: KColors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: MediaQuery.sizeOf(context).height * .68,
            backgroundColor: KColors.offWhite,
            leading: IconButton(
              onPressed: Get.back,
              icon: const Icon(Icons.arrow_back),
            ),
            actions: [
              Obx(
                () => IconButton(
                  onPressed: () => wishlist.toggle(product),
                  icon: Icon(
                    wishlist.contains(product.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: PageView.builder(
                itemCount: images.length,
                onPageChanged: (value) => setState(() => imageIndex = value),
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () => showDialog<void>(
                    context: context,
                    barrierColor: KColors.black,
                    builder: (_) => _ImageViewer(path: images[index]),
                  ),
                  child: index == 0
                      ? Hero(
                          tag: 'product-${product.id}',
                          child: LuxuryImage(path: images[index]),
                        )
                      : LuxuryImage(path: images[index]),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(24),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: MicroLabel('0${imageIndex + 1} / 0${images.length}'),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 36, 22, 130),
            sliver: SliverList.list(
              children: [
                Text(product.name, style: context.textTheme.editorialSmall),
                const SizedBox(height: 16),
                Text('₹${product.price}', style: const TextStyle(fontSize: 17)),
                const SizedBox(height: 4),
                const MicroLabel('INCLUSIVE OF ALL TAXES', color: KColors.gray),
                const SizedBox(height: 34),
                const MicroLabel('OVERVIEW'),
                const SizedBox(height: 16),
                Html(
                  // Descriptions are pasted in from Microsoft Word, which wraps
                  // every single bullet in its own <div><ul><li> (and some, but
                  // not all, in a further nested <p>). Left alone, those extra
                  // wrapper elements each contribute their own margin and the
                  // gaps between bullets compound unevenly depending on which
                  // ones happen to have the nested <p>. Zeroing the wrapper
                  // elements (div/ul/span) and putting all real spacing on
                  // "li" alone makes every gap the same regardless of how a
                  // given bullet happens to be nested.
                  data: product.description,
                  style: {
                    'body': Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      fontSize: FontSize(14),
                      lineHeight: LineHeight(1.75),
                      color: KColors.black,
                    ),
                    'div': Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                    ),
                    'span': Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                    ),
                    'p': Style(margin: Margins.only(bottom: 6)),
                    'ul': Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.only(left: 18),
                    ),
                    'ol': Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.only(left: 18),
                    ),
                    'li': Style(
                      margin: Margins.only(bottom: 10),
                      padding: HtmlPaddings.zero,
                      lineHeight: LineHeight(1.4),
                    ),
                  },
                ),
                const SizedBox(height: 30),
                if (product.socialProof.isNotEmpty)
                  _ExpandableSection(
                    title: 'PRODUCT HIGHLIGHTS',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: product.socialProof
                          .map(
                            (label) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '•  $label',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                const _ExpandableSection(
                  title: 'CRAFT AND CARE',
                  child: Text(
                    'Each piece is finished by hand and inspected before it leaves us. '
                    'Wipe clean with a soft, dry cloth; keep away from direct heat and '
                    'moisture; store upright with the dust bag when not in use.',
                    style: TextStyle(fontSize: 13, height: 1.7),
                  ),
                ),
                const _ExpandableSection(
                  title: 'THE POTLI PROMISE',
                  child: Text(
                    'We stand behind what we make. Every order ships with complimentary '
                    'packaging, easy exchanges, and a team that is genuinely reachable if '
                    'something needs making right.',
                    style: TextStyle(fontSize: 13, height: 1.7),
                  ),
                ),
                const SizedBox(height: 4),
                if (product.colorSwatches.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  const MicroLabel('COLOR'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (
                        var index = 0;
                        index < product.colorSwatches.length;
                        index++
                      )
                        InkWell(
                          onTap: () => setState(() => colorIndex = index),
                          child: Container(
                            width: 36,
                            height: 36,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: colorIndex == index
                                    ? KColors.black
                                    : KColors.line,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: product.colorSwatches[index].color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 30),
                const MicroLabel('QUANTITY'),
                const SizedBox(height: 14),
                Row(
                  children: [
                    IconButton(
                      onPressed: quantity == 1
                          ? null
                          : () => setState(() => quantity -= 1),
                      icon: const Icon(Icons.remove, size: 18),
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '$quantity',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => quantity += 1),
                      icon: const Icon(Icons.add, size: 18),
                    ),
                  ],
                ),
                if (product.allowPersonalization) ...[
                  const SizedBox(height: 30),
                  _PersonalizationCard(
                    product: product,
                    settingsFuture: _personalizationSettingsFuture!,
                    value: personalizationText,
                    onChanged: (payload) =>
                        setState(() => personalizationText = payload),
                  ),
                ],
                const SizedBox(height: 40),
                _CompleteTheLook(future: _completeTheLookFuture),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FullWidthButton(
            label: 'ADD TO BAG',
            onPressed: () => cart.add(
              product,
              quantity: quantity,
              personalizationText: personalizationText,
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonalizationCard extends StatelessWidget {
  const _PersonalizationCard({
    required this.product,
    required this.settingsFuture,
    required this.value,
    required this.onChanged,
  });

  final Product product;
  final Future<PersonalizationSettings> settingsFuture;
  final String? value;
  final ValueChanged<String?> onChanged;

  Future<void> _openSheet(
    BuildContext context,
    PersonalizationSettings settings,
  ) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: KColors.white,
      shape: const RoundedRectangleBorder(),
      builder: (sheetContext) => _PersonalizationSheet(
        product: product,
        settings: settings,
        initialText: decodePersonalization(value).text,
      ),
    );
    if (result != null) onChanged(result.isEmpty ? null : result);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PersonalizationSettings>(
      future: settingsFuture,
      builder: (context, snapshot) {
        final settings = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done ||
            settings == null ||
            !settings.enabled) {
          return const SizedBox.shrink();
        }
        final decoded = decodePersonalization(value);
        final applied = decoded.text.isNotEmpty;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(
              color: applied ? Colors.green.shade300 : KColors.line,
            ),
            color: applied ? Colors.green.shade50 : null,
          ),
          child: Row(
            children: [
              if (applied && decoded.hasImage) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    decoded.image,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ] else
                const Text('✎', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      applied
                          ? 'Personalization added: "${decoded.text}"'
                          : settings.heading.replaceAll(
                              '{product_name}',
                              product.name,
                            ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      applied
                          ? 'Tap to edit or remove.'
                          : settings.description.replaceAll(
                              '{product_name}',
                              product.name,
                            ),
                      style: const TextStyle(fontSize: 11, color: KColors.gray),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _openSheet(context, settings),
                child: Text(applied ? 'EDIT' : 'PERSONALIZE'),
              ),
            ],
          ),
        );
      },
    );
  }
}

const _kPersonalizationEmoji = [
  '❤️',
  '💕',
  '💖',
  '😊',
  '😍',
  '🥰',
  '⭐',
  '✨',
  '🌟',
  '💫',
  '🌸',
  '🌺',
  '🌻',
  '🌷',
  '🍀',
  '🦋',
  '🐾',
  '🐶',
  '🐱',
  '🦄',
  '☀️',
  '🌙',
  '🌈',
  '🔥',
  '💎',
  '👑',
  '🎀',
  '🎉',
  '🥂',
  '🍾',
  '😇',
  '🙏',
];

/// The bottom sheet body: a live preview of the bag with the customer's
/// text/emoji positioned on it exactly where it'll be engraved (mirrors the
/// website's absolutely-positioned overlay), then on save renders that same
/// composition into a real image via [RenderRepaintBoundary] and uploads it
/// — the app's equivalent of the website's <canvas> capture.
class _PersonalizationSheet extends StatefulWidget {
  const _PersonalizationSheet({
    required this.product,
    required this.settings,
    required this.initialText,
  });

  final Product product;
  final PersonalizationSettings settings;
  final String initialText;

  @override
  State<_PersonalizationSheet> createState() => _PersonalizationSheetState();
}

class _PersonalizationSheetState extends State<_PersonalizationSheet> {
  late final TextEditingController _controller;
  final _previewKey = GlobalKey();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String?> _captureAndUpload() async {
    try {
      // The preview's base photo may not have finished decoding yet (e.g. a
      // dedicated personalize_image the product gallery never otherwise
      // shows) — capturing before it's ready would bake a blank placeholder
      // into the saved image instead of the actual bag.
      final baseImage = widget.product.personalizeImage.isNotEmpty
          ? widget.product.personalizeImage
          : widget.product.image;
      if (mounted) {
        final provider = baseImage.startsWith('http')
            ? NetworkImage(baseImage) as ImageProvider
            : AssetImage(baseImage);
        await precacheImage(provider, context);
      }
      // One extra frame so the just-precached image and the just-typed text
      // are definitely painted before the boundary is captured.
      await Future.delayed(const Duration(milliseconds: 20));
      final boundary = _previewKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) return null;
      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      final bytes = byteData.buffer.asUint8List();
      final dataUrl = 'data:image/png;base64,${base64Encode(bytes)}';
      return await Get.find<ProductService>().savePersonalizationPreview(
        dataUrl,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      Navigator.of(context).pop('');
      return;
    }
    setState(() => _saving = true);
    final path = await _captureAndUpload();
    if (!mounted) return;
    // A failed upload still keeps the text-only personalization (matches
    // the website's fallback) rather than blocking the customer entirely.
    final payload = path != null
        ? jsonEncode({'text': text, 'image': path})
        : text;
    Navigator.of(context).pop(payload);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final settings = widget.settings;
    final baseImage = product.personalizeImage.isNotEmpty
        ? product.personalizeImage
        : product.image;
    final text = _controller.text;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                settings.heading.replaceAll('{product_name}', product.name),
                style: context.textTheme.editorialSmall,
              ),
              const SizedBox(height: 8),
              Text(
                settings.description.replaceAll('{product_name}', product.name),
                style: const TextStyle(fontSize: 13, color: KColors.gray),
              ),
              const SizedBox(height: 16),
              RepaintBoundary(
                key: _previewKey,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final maxTextWidth =
                            constraints.maxWidth *
                            (product.personalizeTextWidth / 100);
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            LuxuryImage(path: baseImage),
                            if (text.isNotEmpty)
                              Align(
                                alignment: Alignment(
                                  (product.personalizeTextX / 50) - 1,
                                  (product.personalizeTextY / 50) - 1,
                                ),
                                child: SizedBox(
                                  width: maxTextWidth,
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: Text(
                                      text,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.dancingScript(
                                        fontSize: 40,
                                        fontWeight: FontWeight.w700,
                                        color: _parsePersonalizeColor(
                                          product.personalizeTextColor,
                                        ),
                                        shadows: const [
                                          Shadow(
                                            color: Color(0x8CFFFFFF),
                                            offset: Offset(0.8, 0.8),
                                          ),
                                          Shadow(
                                            color: Color(0x66000000),
                                            offset: Offset(-0.8, -0.8),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 6,
                children: [
                  for (final emoji in _kPersonalizationEmoji)
                    InkWell(
                      onTap: () {
                        final next = _controller.text + emoji;
                        if (next.length > settings.maxCharacters) return;
                        _controller.text = next;
                        _controller.selection = TextSelection.collapsed(
                          offset: _controller.text.length,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                maxLength: settings.maxCharacters,
                decoration: const InputDecoration(
                  hintText: 'Type here…',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FullWidthButton(
                label: _saving ? 'Saving…' : 'Add Personalization',
                busy: _saving,
                onPressed: _saving ? null : _save,
              ),
              const SizedBox(height: 8),
              FullWidthButton(
                label: 'Remove Personalization',
                inverse: true,
                onPressed: _saving ? null : () => Navigator.of(context).pop(''),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _parsePersonalizeColor(String hex) {
  var value = hex.trim();
  if (value.startsWith('#')) value = value.substring(1);
  if (value.length == 3) {
    value = value.split('').map((c) => '$c$c').join();
  }
  if (value.length != 6) return const Color(0xFF4A3624);
  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? const Color(0xFF4A3624) : Color(0xFF000000 | parsed);
}

class _CompleteTheLook extends StatelessWidget {
  const _CompleteTheLook({required this.future});

  final Future<List<Product>>? future;

  @override
  Widget build(BuildContext context) {
    if (future == null) return const SizedBox.shrink();
    return FutureBuilder<List<Product>>(
      future: future,
      builder: (context, snapshot) {
        final charms = snapshot.data ?? const [];
        if (snapshot.connectionState != ConnectionState.done ||
            charms.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MicroLabel('COMPLETE THE LOOK'),
            const SizedBox(height: 16),
            SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: charms.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final charm = charms[index];
                  return SizedBox(
                    width: 140,
                    child: GestureDetector(
                      onTap: () => Get.toNamed(Routes.detail, arguments: charm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AspectRatio(
                            aspectRatio: 1,
                            child: LuxuryImage(path: charm.image),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            charm.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '₹${charm.price}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: KColors.gray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ExpandableSection extends StatefulWidget {
  const _ExpandableSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      InkWell(
        onTap: () => setState(() => expanded = !expanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MicroLabel(widget.title),
              Icon(expanded ? Icons.remove : Icons.add, size: 18),
            ],
          ),
        ),
      ),
      if (expanded)
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: widget.child,
        ),
      const SectionDivider(),
    ],
  );
}

class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: LuxuryImage(path: path, fit: BoxFit.contain),
          ),
        ),
      ),
      SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.close, color: KColors.white),
          ),
        ),
      ),
    ],
  );
}
