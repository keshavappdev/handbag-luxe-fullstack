import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/app_controllers.dart';
import '../../models/category_node.dart';
import '../../utils/app_theme.dart';
import '../../utils/asset_paths.dart';
import '../../widgets/luxury_widgets.dart';

class DiscoverView extends StatefulWidget {
  const DiscoverView({super.key});

  @override
  State<DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<DiscoverView> {
  late final Future<List<CategoryNode>> _future = Get.find<CatalogController>()
      .loadDiscoverStories();

  @override
  Widget build(BuildContext context) {
    final catalog = Get.find<CatalogController>();
    return Scaffold(
      appBar: const LuxuryHeader(),
      body: FutureBuilder<List<CategoryNode>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final stories = snapshot.data ?? const [];
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 38, 20, 46),
                sliver: SliverList.list(
                  children: [
                    const MicroLabel('POTLI STORIES', color: KColors.gray),
                    const SizedBox(height: 14),
                    Text(
                      'DISCOVER',
                      style: context.textTheme.editorial.copyWith(fontSize: 74),
                    ),
                  ],
                ),
              ),
              SliverList.builder(
                // +1 for the leading "NEW ARRIVALS / shop all" entry.
                itemCount: stories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _RevealStory(
                      index: 0,
                      title: 'NEW\nARRIVALS',
                      image: catalog.homeSlideImage(0),
                      height: 620,
                      onTap: catalog.showAll,
                    );
                  }
                  final story = stories[index - 1];
                  final image = story.image.isNotEmpty
                      ? story.image
                      : AssetPaths.categoryFallbacks[(index - 1) %
                            AssetPaths.categoryFallbacks.length];
                  return _RevealStory(
                    index: index,
                    title: story.name.toUpperCase(),
                    image: image,
                    height: index.isEven ? 500 : 620,
                    onTap: () => catalog.openCategoryById(story.id, story.name),
                  );
                },
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 70, 20, 90),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'NO RULES.\nJUST YOURS.',
                    style: context.textTheme.editorialSmall,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RevealStory extends StatelessWidget {
  const _RevealStory({
    required this.index,
    required this.title,
    required this.image,
    required this.height,
    required this.onTap,
    this.darkText = false,
  });

  final int index;
  final String title;
  final String image;
  final double height;
  final VoidCallback onTap;
  final bool darkText;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: 650 + index * 80),
    curve: Curves.easeOutCubic,
    builder: (context, value, child) => Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, 30 * (1 - value)),
        child: child,
      ),
    ),
    child: InkWell(
      onTap: onTap,
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: height,
            child: LuxuryImage(path: image),
          ),
          Positioned.fill(
            child: ColoredBox(color: KColors.black.withValues(alpha: .14)),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 26,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: context.textTheme.editorialSmall.copyWith(
                      color: darkText ? KColors.black : KColors.white,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  color: darkText ? KColors.black : KColors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
