import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../app/routes.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/asset_paths.dart';
import '../../widgets/luxury_widgets.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _navigationTimer = Timer(const Duration(milliseconds: 1900), () {
      if (!mounted) return;

      final storage = Get.find<StorageService>();
      if (storage.authToken.isNotEmpty) {
        Get.offAllNamed(Routes.shell);
        return;
      }
      final seen = storage.hasSeenOnboarding;
      Get.offAllNamed(seen ? Routes.login : Routes.onboarding);
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KColors.white,
      body: Center(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Center(child: OfficialBrandLogo(width: 218)),
              const SizedBox(height: 24),
              SizedBox(
                width: 218,
                child: Text(
                  'UNAPOLOGETICALLY YOU.',
                  textAlign: TextAlign.center,
                  style: context.textTheme.micro.copyWith(color: KColors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _page = 0;

  static const _stories = <({String title, String body})>[
    (title: 'OBJECTS OF\nDESIRE', body: 'Sculptural bags, considered details, and pieces designed to live beyond a season.'),
    (title: 'CRAFTED FOR\nTHE EVERYDAY', body: 'A modern wardrobe of tactile forms—quietly expressive, intentionally made.'),
    (title: 'YOUR STORY,\nCARRIED', body: 'Discover POTLI: a new language of contemporary luxury, made personal.'),
  ];

  Future<void> _complete() async {
    await Get.find<StorageService>().completeOnboarding();
    if (!mounted) return;
    Get.offAllNamed(Routes.login);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = _stories[_page];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: KColors.offWhite,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: KColors.offWhite,
        body: Column(
          children: [
            Expanded(
              flex: 7,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: AssetPaths.onboarding.length,
                    onPageChanged: (value) => setState(() => _page = value),
                    itemBuilder: (context, index) => AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        final value = _pageController.hasClients ? (_pageController.page ?? index.toDouble()) : index.toDouble();
                        final scale = (1 - ((value - index).abs() * .045)).clamp(.955, 1.0);
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: LuxuryImage(path: AssetPaths.onboarding[index]),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x66000000), Colors.transparent, Color(0x22000000)],
                        stops: [0, .42, 1],
                      ),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 18, 0),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Row(
                          children: [
                            const BrandWordmark(color: KColors.white, fontSize: 23),
                            const Spacer(),
                            TextButton(onPressed: _complete, child: const MicroLabel('SKIP', color: KColors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 25, 24, 18),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 380),
                    child: Column(
                      key: ValueKey(_page),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(3, (index) => Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 1,
                              margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                              color: index <= _page ? KColors.black : KColors.line,
                            ),
                          )),
                        ),
                        const SizedBox(height: 20),
                        Text(story.title, style: context.textTheme.editorialSmall.copyWith(fontSize: 43)),
                        const SizedBox(height: 10),
                        Text(story.body, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, height: 1.55, color: KColors.gray)),
                        const Spacer(),
                        Row(
                          children: [
                            MicroLabel('0${_page + 1} / 03', color: KColors.gray),
                            const Spacer(),
                            SizedBox(
                              width: 168,
                              child: FullWidthButton(
                                label: _page == 2 ? 'ENTER POTLI' : 'CONTINUE',
                                onPressed: _page == 2 ? _complete : () => _pageController.nextPage(duration: const Duration(milliseconds: 520), curve: Curves.easeInOutCubic),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
