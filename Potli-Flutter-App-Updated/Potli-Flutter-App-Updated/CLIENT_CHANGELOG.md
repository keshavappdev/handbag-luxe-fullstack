# POTLI client update — 16.1

## Reference Home recreation

- Home opens on a pure-white canvas with the large Potli wordmark fixed in
  the reference position for exactly four seconds.
- Editorial content and the bottom navigation then fade in softly over 820 ms.
- Replaced vertical full-page snapping with natural, momentum-based scrolling.
- Rebuilt Home as a five-page horizontal campaign. Its first horizontal page
  contains the complete long-form vertical editorial feed.
- Added the reference section sequence: opening three-column mosaic, `THE ITEM`,
  street collage, three tall portraits, `The Journal`, sale campaign and
  `The New` ending.
- The Home wordmark remains fixed while photography scrolls underneath it,
  fades out in the deep article section, and returns when scrolling upward.
- Wordmark contrast crossfades from black to white while swiping across darker
  campaign pages.
- Removed the old Home Browse button, page counter, vertical page snapping,
  shrinking logo and mid-feed carousel.

## Navigation and launch

- Rebuilt the fixed bottom bar to match the five-part reference structure:
  Home, Menu, Search, Account and Bag.
- Existing category, search, profile, cart and product flows remain connected.
- Removed the black Android launch flash. Native launch and Flutter splash now
  use a continuous white background.
- Official Android launcher icons remain unchanged.

## Replaceable assets

- Official source logo:
  `assets/images/logo/potli_mark.png`
- Transparent Home wordmark:
  `assets/images/logo/potli_wordmark_luxury.png`
- Every Home image alias and the opening mosaic order:
  `lib/utils/asset_paths.dart`

No Zara logo or Zara-owned asset is included.
