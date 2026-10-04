import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes.dart';
import '../../controllers/app_controllers.dart';
import '../../models/home_slide.dart';
import '../../models/product.dart';
import '../../utils/app_theme.dart';
import '../../utils/asset_paths.dart';
import '../../widgets/luxury_widgets.dart';

/// Toggle the sale campaign poster on the homepage on/off.
const bool showSaleCampaign = false;

/// Reference-led Home: a horizontally paged campaign with a freely scrolling
/// editorial feed inside its first page.
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  static const _introHold = Duration(seconds: 2);

  late final ScrollController _editorialController;
  late final AnimationController _revealController;
  late final Animation<double> _contentOpacity;
  Timer? _introTimer;

  double _wordmarkHideOffset = double.infinity;
  bool _editorialWordmarkVisible = true;
  bool _interactionEnabled = false;

  @override
  void initState() {
    super.initState();
    _editorialController = ScrollController()
      ..addListener(_handleEditorialScroll);
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
    _contentOpacity = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOutCubic,
    );

    _introTimer = Timer(_introHold, _revealHome);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Wordmark stays visible only over the opening collage/mosaic — it fades
    // once the feed scrolls past it, and reappears when scrolled back up.
    _wordmarkHideOffset = MediaQuery.sizeOf(context).height * 1.15;
  }

  Future<void> _revealHome() async {
    if (!mounted) return;
    Get.find<NavigationController>().setHomeChromeVisible(true);
    await _revealController.forward();
    if (mounted) setState(() => _interactionEnabled = true);
  }

  void _handleEditorialScroll() {
    if (!_editorialController.hasClients || !mounted) return;
    final shouldShow = _editorialController.offset < _wordmarkHideOffset;
    if (shouldShow != _editorialWordmarkVisible) {
      setState(() => _editorialWordmarkVisible = shouldShow);
    }
  }

  @override
  void dispose() {
    _introTimer?.cancel();
    _editorialController.removeListener(_handleEditorialScroll);
    _editorialController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = Get.find<CatalogController>();
    return Scaffold(
      backgroundColor: KColors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: IgnorePointer(
          ignoring: !_interactionEnabled,
          child: FadeTransition(
            opacity: _contentOpacity,
            child: const ColoredBox(
              color: KColors.white,
              child: LuxuryHeader(transparent: true),
            ),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            opacity: _contentOpacity,
            child: IgnorePointer(
              ignoring: !_interactionEnabled,
              child: _EditorialFeed(
                controller: _editorialController,
                onExplore: catalog.showAll,
              ),
            ),
          ),
          _FixedHomeWordmark(
            color: KColors.black,
            visible: _editorialWordmarkVisible,
          ),
        ],
      ),
    );
  }
}

class _FixedHomeWordmark extends StatelessWidget {
  const _FixedHomeWordmark({required this.color, required this.visible});

  final Color color;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Positioned(
      left: -2,
      right: -2,
      top: size.height * .60,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeInOutCubic,
          child: Image.asset(
            AssetPaths.homeWordmark,
            width: size.width * 0.12, // screen width ka 70%
            height: size.height * 0.20, // screen height ka 12%
            fit: BoxFit.contain, // aspect ratio maintain karega
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

// class _HomeMasthead extends StatelessWidget {
//   const _HomeMasthead();
//
//   @override
//   Widget build(BuildContext context) => Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 14),
//         child: Row(
//           children: [
//             const OfficialBrandLogo(width: 48),
//             const SizedBox(width: 12),
//             Container(width: 1, height: 38, color: KColors.line),
//             const SizedBox(width: 12),
//             const Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   MicroLabel('THE POTLI EDIT', color: KColors.gray),
//                   SizedBox(height: 5),
//                   Text(
//                     'OBJECTS WITH ATTITUDE.',
//                     style: TextStyle(
//                       fontSize: 11,
//                       fontWeight: FontWeight.w500,
//                       letterSpacing: 1.1,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const MicroLabel('HOME / 01', color: KColors.gray),
//           ],
//         ),
//       );
// }

class _EditorialInterlude extends StatelessWidget {
  const _EditorialInterlude({
    required this.eyebrow,
    required this.headline,
    required this.description,
  });

  final String eyebrow;
  final String headline;
  final String description;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: KColors.line, width: .8),
          bottom: BorderSide(color: KColors.line, width: .8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MicroLabel(eyebrow, color: KColors.gray),
          const SizedBox(height: 17),
          Text(
            headline,
            style: context.textTheme.editorialSmall.copyWith(
              fontSize: 39,
              height: .88,
            ),
          ),
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 310),
            child: Text(
              description,
              style: const TextStyle(
                color: KColors.gray,
                fontSize: 9,
                height: 1.55,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.25,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _EditorialFeed extends StatelessWidget {
  const _EditorialFeed({required this.controller, required this.onExplore});

  final ScrollController controller;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return ColoredBox(
      color: KColors.white,
      child: ListView(
        controller: controller,
        padding: EdgeInsets.zero,
        physics: const ClampingScrollPhysics(),
        cacheExtent: 1400,
        children: [
          // const SizedBox(height: 14),
          // const _HomeMasthead(),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _OpeningMosaic(
              // Half the old height: columns are now 2 tiles deep instead of 4.
              height: height * 0.56,
            ),
          ),
          const SizedBox(height: 28),
          const _BannerCarousel(),
          const SizedBox(height: 28),
          const _EditorialInterlude(
            eyebrow: 'THE POTLI EDIT / 01',
            headline: 'CARRY YOUR\nCONFIDENCE.',
            description: 'PIECES CHOSEN FOR MOVEMENT, PRESENCE AND EVERY VERSION OF YOU.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Obx(() {
              final catalog = Get.find<CatalogController>();
              final product = catalog.homeSectionProductAt(4);
              return _ItemEditorial(
                height: height * .98,
                onTap: product != null
                    ? () => catalog.openProduct(product)
                    : onExplore,
                image: product?.image ?? AssetPaths.heroCampaign,
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _FeaturedProductCollage(
              height: height * .9,
              fallback: _StreetCollage(
                height: height * .9,
                topLeft: AssetPaths.editorialModel,
                topRight: AssetPaths.onboarding02,
                bottomLeft: AssetPaths.handBags,
                bottomRight: AssetPaths.editorialModel,
              ),
            ),
          ),
          Obx(() {
            final product = Get.find<CatalogController>().homeSectionProductAt(
              5,
            );
            return _EditorialPortrait(
              image: product?.image ?? AssetPaths.homePortraitBlack,
              height: height * .94,
              alignment: const Alignment(.15, -.12),
            );
          }),
          Obx(() {
            final product = Get.find<CatalogController>().homeSectionProductAt(
              6,
            );
            return _EditorialPortrait(
              image: product?.image ?? AssetPaths.homePortraitPale,
              height: height * .92,
              alignment: const Alignment(.2, -.1),
            );
          }),
          Obx(() {
            final product = Get.find<CatalogController>().homeSectionProductAt(
              7,
            );
            return _EditorialPortrait(
              image: product?.image ?? AssetPaths.homePortraitBlue,
              height: height * .93,
              alignment: const Alignment(-.15, -.14),
            );
          }),
          Obx(() {
            final catalog = Get.find<CatalogController>();
            final entry = catalog.homeSectionEntryAt(8);
            return _EditorialStory(
              height: height,
              onTap: entry != null
                  ? () => catalog.openProduct(entry.product)
                  : onExplore,
              image: entry?.product.image ?? AssetPaths.onboarding03,
              heading: entry?.section.title.isNotEmpty == true
                  ? entry!.section.title
                  : 'The Journal',
            );
          }),
          if (showSaleCampaign) ...[
            _SaleCampaign(height: height * .92, onTap: onExplore),
            const SizedBox(height: 62),
          ],
          Obx(() {
            final catalog = Get.find<CatalogController>();
            final pool = catalog.homeSectionProducts;
            final more = pool.length > 9 ? pool.sublist(9) : const <Product>[];
            final title = catalog.homeSectionEntryAt(9)?.section.title;
            return _TheNewSection(
              height: height * .82,
              onTap: onExplore,
              products: more,
              sectionTitle: title,
              onProductTap: catalog.openProduct,
            );
          }),
        ],
      ),
    );
  }
}

/// The CMS-managed `sliders` banner carousel. Ported from the previous app's
/// proven pattern: a properly banner-shaped (width/1.6 height) auto-advancing
/// PageView with dot indicators — the images here are wide campaign banners,
/// not portrait photos, so unlike the rest of the home page this section is
/// sized to match their actual shape instead of cropping/letterboxing them
/// into an unrelated aspect ratio.
class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel();

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final _controller = PageController();
  Timer? _autoAdvance;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _autoAdvance = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      final count = Get.find<CatalogController>().homeSlides.length;
      if (count <= 1) return;
      _controller.animateToPage(
        (_page + 1) % count,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoAdvance?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(HomeSlide slide) {
    final catalog = Get.find<CatalogController>();
    if (slide.type == 'categories' && slide.typeId.isNotEmpty) {
      catalog.openCategoryById(
        slide.typeId,
        slide.title.isNotEmpty ? slide.title : 'Collection',
      );
    } else {
      catalog.showAll();
    }
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    final slides = Get.find<CatalogController>().homeSlides;
    if (slides.isEmpty) return const SizedBox.shrink();
    final height = MediaQuery.sizeOf(context).width / 1.6;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Stack(
        children: [
          SizedBox(
            height: height,
            child: PageView.builder(
              controller: _controller,
              itemCount: slides.length,
              onPageChanged: (index) => setState(() => _page = index),
              itemBuilder: (context, index) {
                final slide = slides[index];
                return GestureDetector(
                  onTap: () => _handleTap(slide),
                  child: LuxuryImage(path: slide.image),
                );
              },
            ),
          ),
          if (slides.length > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(slides.length, (index) {
                  final active = index == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: active ? 18 : 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: active
                          ? KColors.white
                          : KColors.white.withValues(alpha: .5),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  });
}

class _OpeningMosaic extends StatelessWidget {
  const _OpeningMosaic({required this.height});

  final double height;

  // Capped at 5 images total (2 + 2 + 1 across the three columns).
  static const _flexes = [30, 22, 28, 20, 50];
  static const _alignments = [
    Alignment(.1, -.2),
    Alignment.center,
    Alignment(.15, -.1),
    Alignment.center,
    Alignment(-.2, -.1),
  ];

  @override
  Widget build(BuildContext context) {
    final catalog = Get.find<CatalogController>();
    return SizedBox(
      height: height,
      child: Obx(() {
        final categories = catalog.topCategories;
        Widget tile(int index) {
          final category = index < categories.length ? categories[index] : null;
          final image = category != null && category.image.isNotEmpty
              ? category.image
              : AssetPaths.homeMosaic[index];
          return _MosaicImage(
            image: image,
            flex: _flexes[index],
            alignment: _alignments[index],
            // Tapping any image here opens the bag-categories browser (Tote
            // Bag, Sling Bag, etc. — pulled live from the site) rather than
            // jumping straight into one hardcoded category.
            onTap: () => Get.toNamed(Routes.categories),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(children: [for (var i = 0; i < 2; i++) tile(i)]),
            ),
            Expanded(
              child: Column(children: [for (var i = 2; i < 4; i++) tile(i)]),
            ),
            Expanded(child: Column(children: [tile(4)])),
          ],
        );
      }),
    );
  }
}

class _MosaicImage extends StatelessWidget {
  const _MosaicImage({
    required this.image,
    required this.flex,
    required this.onTap,
    this.alignment = Alignment.center,
  });

  final String image;
  final int flex;
  final VoidCallback onTap;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: SizedBox.expand(
      child: Semantics(
        button: true,
        label: 'Explore the Potli collection',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: LuxuryImage(path: image, alignment: alignment),
        ),
      ),
    ),
  );
}

class _ItemEditorial extends StatelessWidget {
  const _ItemEditorial({
    required this.height,
    required this.onTap,
    required this.image,
  });

  final double height;
  final VoidCallback onTap;
  final String image;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          LuxuryImage(path: image, alignment: const Alignment(.05, -.15)),
          Positioned(
            left: 8,
            right: 8,
            top: 10,
            child: FittedBox(
              fit: BoxFit.fitWidth,
              child: Text(
                'THE ITEM',
                maxLines: 1,
                style: TextStyle(
                  color: const Color(0xFFD3C6AE).withValues(alpha: .95),
                  fontSize: 92,
                  height: .88,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -5,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Admin -> Featured Sections (get_sections), shown in the same 2x2 collage
/// slot the home page used to fill with 4 fixed local marketing photos.
/// Takes indices 0-3 of the shared product pool (see
/// [CatalogController.homeSectionProducts]) — the other API-backed slots
/// further down the page start at index 4, so nothing repeats. Falls back to
/// the static [fallback] collage until at least 4 real products are
/// available, so this slot is never left blank.
class _FeaturedProductCollage extends StatelessWidget {
  const _FeaturedProductCollage({required this.height, required this.fallback});

  final double height;
  final Widget fallback;

  @override
  Widget build(BuildContext context) => Obx(() {
    final catalog = Get.find<CatalogController>();
    final pool = catalog.homeSectionProducts;
    if (pool.length < 4) return fallback;
    final products = pool.take(4).toList();
    return _ProductCollage(
      height: height,
      products: products,
      onTap: catalog.openProduct,
    );
  });
}

class _ProductCollage extends StatelessWidget {
  const _ProductCollage({
    required this.height,
    required this.products,
    required this.onTap,
  });

  final double height;
  final List<Product> products;
  final ValueChanged<Product> onTap;

  Widget _tile(Product product) => GestureDetector(
    onTap: () => onTap(product),
    child: Stack(
      fit: StackFit.expand,
      children: [
        LuxuryImage(path: product.image),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xA6000000)],
              stops: [0.55, 1],
            ),
          ),
        ),
        Positioned(
          left: 10,
          right: 10,
          bottom: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: KColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '₹${product.price}',
                style: const TextStyle(
                  color: KColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _tile(products[0])),
              const SizedBox(width: 4),
              Expanded(child: _tile(products[1])),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _tile(products[2])),
              const SizedBox(width: 4),
              Expanded(child: _tile(products[3])),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StreetCollage extends StatelessWidget {
  const _StreetCollage({
    required this.height,
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  final double height;
  final String topLeft;
  final String topRight;
  final String bottomLeft;
  final String bottomRight;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Column(
      children: [
        Expanded(
          flex: 42,
          child: Row(
            children: [
              Expanded(
                flex: 58,
                child: LuxuryImage(
                  path: topLeft,
                  alignment: const Alignment(-.35, -.1),
                ),
              ),
              Expanded(
                flex: 42,
                child: LuxuryImage(
                  path: topRight,
                  alignment: const Alignment(.2, -.15),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 58,
          child: Row(
            children: [
              Expanded(
                flex: 38,
                child: LuxuryImage(
                  path: bottomLeft,
                  alignment: const Alignment(.05, -.1),
                ),
              ),
              Expanded(
                flex: 62,
                child: LuxuryImage(
                  path: bottomRight,
                  alignment: const Alignment(.35, .05),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EditorialPortrait extends StatelessWidget {
  const _EditorialPortrait({
    required this.image,
    required this.height,
    required this.alignment,
  });

  final String image;
  final double height;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: LuxuryImage(path: image, alignment: alignment),
    ),
  );
}

class _EditorialStory extends StatelessWidget {
  const _EditorialStory({
    required this.height,
    required this.onTap,
    required this.image,
    this.heading = 'The Journal',
  });

  final double height;
  final VoidCallback onTap;
  final String image;

  /// Admin -> Featured Sections title (e.g. "Fresh Arrivals") when a real
  /// section backs this slot, otherwise the original static heading.
  final String heading;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            heading,
            style: const TextStyle(
              fontSize: 68,
              height: .9,
              fontWeight: FontWeight.w700,
              letterSpacing: -4.4,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
            height: height * 1.02,
            child: Stack(
              fit: StackFit.expand,
              children: [
                LuxuryImage(path: image, alignment: const Alignment(.05, -.16)),
                const ColoredBox(color: Color(0x26000000)),
                const Positioned(
                  left: 14,
                  right: 14,
                  bottom: 24,
                  child: Text(
                    'STYLE BEGINS\nWHERE EXPECTATION\nENDS.',
                    style: TextStyle(
                      color: KColors.white,
                      fontSize: 44,
                      height: .88,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -2.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(10, 22, 10, 0),
          child: Text(
            'A BAG IS MORE THAN SOMETHING YOU CARRY. '
            'IT IS HOW YOU ENTER THE ROOM — ON YOUR OWN TERMS.',
            style: TextStyle(
              fontSize: 35,
              height: .94,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.6,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SaleCampaign extends StatelessWidget {
  const _SaleCampaign({required this.height, required this.onTap});

  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColorFiltered(
              colorFilter: ColorFilter.matrix(<double>[
                .33,
                .59,
                .11,
                0,
                0,
                .33,
                .59,
                .11,
                0,
                0,
                .33,
                .59,
                .11,
                0,
                0,
                0,
                0,
                0,
                1,
                0,
              ]),
              child: LuxuryImage(
                path: AssetPaths.homeSale,
                alignment: Alignment(.15, -.08),
              ),
            ),
            const Positioned(
              left: 8,
              right: 8,
              top: 18,
              child: Text(
                'POTLI\nSALE\nONLINE AND\nIN STORE',
                style: TextStyle(
                  color: Color(0xFFE1241A),
                  fontSize: 54,
                  height: .78,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -3.8,
                ),
              ),
            ),
            const Positioned(
              left: 8,
              right: 8,
              bottom: 20,
              child: Text(
                'FURTHER\nREDUCTIONS',
                style: TextStyle(
                  color: Color(0xFFE1241A),
                  fontSize: 64,
                  height: .76,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -4.4,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TheNewSection extends StatelessWidget {
  const _TheNewSection({
    required this.height,
    required this.onTap,
    this.products = const [],
    this.sectionTitle,
    this.onProductTap,
  });

  final double height;
  final VoidCallback onTap;

  /// More Admin -> Featured Sections products (continuing the shared home
  /// pool past what the collage/hero/portraits/story slots already used) —
  /// shown as a vertical scrolling slider filling the space that used to be
  /// empty (just a Spacer) below the "SCROLL DOWN" line.
  final List<Product> products;
  final String? sectionTitle;
  final ValueChanged<Product>? onProductTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Column(
      children: [
        const SizedBox(height: 34),
        InkWell(
          onTap: onTap,
          child: Text(
            'The New',
            style: context.textTheme.editorial.copyWith(
              fontSize: 62,
              height: .92,
            ),
          ),
        ),
        const SizedBox(height: 22),
        MicroLabel(
          products.isEmpty
              ? 'SCROLL DOWN'
              : (sectionTitle?.isNotEmpty == true
                    ? sectionTitle!
                    : 'FRESH ARRIVALS'),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: products.isEmpty
              ? GestureDetector(
                  onTap: onTap,
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox.expand(),
                )
              : _VerticalProductSlider(
                  products: products,
                  onTap: onProductTap ?? (_) => onTap(),
                ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 34),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: MicroLabel('UNAPOLOGETICALLY YOU.'),
          ),
        ),
      ],
    ),
  );
}

/// A vertically page-snapping slider of more Featured Section products —
/// swipe up/down to browse, tap to open that product.
class _VerticalProductSlider extends StatelessWidget {
  const _VerticalProductSlider({required this.products, required this.onTap});

  final List<Product> products;
  final ValueChanged<Product> onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return GestureDetector(
            onTap: () => onTap(product),
            child: Stack(
              fit: StackFit.expand,
              children: [
                LuxuryImage(path: product.image),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xB3000000)],
                      stops: [0.5, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: KColors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '₹${product.price}',
                        style: const TextStyle(
                          color: KColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
