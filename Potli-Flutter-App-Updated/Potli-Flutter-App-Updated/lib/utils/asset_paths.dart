/// The only file that maps UI roles to image files.
/// Replace any client image here without editing a view or widget.
abstract final class AssetPaths {
  static const _logo = 'assets/images/logo';
  static const _onboarding = 'assets/images/onboarding';
  static const _banners = 'assets/images/banners';
  static const _editorial = 'assets/images/editorial';
  static const _categories = 'assets/images/categories';
  static const _products = 'assets/images/products';

  static const officialLogo = '$_logo/potli_mark.png';
  static const homeWordmark = '$_logo/potli_wordmark_luxury.png';

  static const onboarding01 = '$_onboarding/potli_story_01.png';
  static const onboarding02 = '$_onboarding/potli_story_02.png';
  static const onboarding03 = '$_onboarding/potli_story_03.png';

  static const heroCampaign = '$_banners/potli_signature_campaign.png';
  static const editorialModel = '$_editorial/atelier_edit.png';

  static const handBags = '$_categories/signature_handbags.png';
  static const toteBags = '$_categories/structured_totes.png';
  static const beadBags = '$_categories/evening_bead_bags.png';

  static const aabhaTote = '$_products/aaria_tote.png';
  static const viraTote = '$_products/zoya_signature.png';
  static const neevCarryall = '$_products/noor_carryall.png';
  static const meherMini = '$_products/mira_mini.png';
  static const kaiaBead = '$_products/veera_tote.png';

  static const heroSlides = <String>[
    heroCampaign,
    editorialModel,
    onboarding03,
    onboarding02,
  ];

  static const onboarding = <String>[onboarding01, onboarding02, onboarding03];

  static const categoryFallbacks = <String>[
    handBags,
    toteBags,
    beadBags,
    editorialModel,
  ];

  /// Large mixed model + product sequence used by the horizontal Home edit.
  /// Replace or reorder files here; the Home UI does not need to change.
  static const horizontalCollection = <String>[
    editorialModel,
    aabhaTote,
    onboarding02,
    kaiaBead,
    heroCampaign,
    viraTote,
    onboarding03,
    neevCarryall,
    meherMini,
  ];

  /// Home imagery is centralized here so client campaign photography can be
  /// replaced without touching layout, positioning or animation code.
  static const homeMosaic = <String>[
    heroCampaign,
    aabhaTote,
    onboarding01,
    kaiaBead,
    editorialModel,
    handBags,
    viraTote,
    onboarding02,
    toteBags,
    neevCarryall,
    onboarding03,
    meherMini,
  ];

  static const homeCampaignMan = heroCampaign;
  static const homeCampaignKids = onboarding01;
  static const homeCampaignWoman = onboarding03;
  static const homeCampaignRed = onboarding02;

  static const homePortraitBlack = onboarding02;
  static const homePortraitPale = handBags;
  static const homePortraitBlue = beadBags;
  static const homeSale = onboarding03;
}
