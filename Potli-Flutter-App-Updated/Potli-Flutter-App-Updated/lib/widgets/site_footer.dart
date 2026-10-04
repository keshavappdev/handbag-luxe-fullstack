import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/app_theme.dart';
import '../utils/site_links.dart';
import 'luxury_widgets.dart';

Future<void> _open(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

/// Sleek footer linking out to the website for policy/company pages —
/// these are not duplicated as in-app screens.
class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) => Container(
    color: KColors.offWhite,
    padding: const EdgeInsets.fromLTRB(24, 48, 24, 36),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BrandWordmark(fontSize: 15),
        const SizedBox(height: 28),
        const MicroLabel('MAY WE HELP YOU', color: KColors.gray),
        const SizedBox(height: 12),
        _FooterLink('Privacy Policy', SiteLinks.privacyPolicy),
        _FooterLink('Return Policy', SiteLinks.returnPolicy),
        _FooterLink('Shipping Policy', SiteLinks.shippingPolicy),
        _FooterLink('Terms & Conditions', SiteLinks.termsAndConditions),
        const SizedBox(height: 26),
        const MicroLabel('COMPANY', color: KColors.gray),
        const SizedBox(height: 12),
        _FooterLink('About Us', SiteLinks.aboutUs),
        _FooterLink('Contact Us', SiteLinks.contactUs),
        const SizedBox(height: 26),
        const MicroLabel('VISIT OUR WEBSITE', color: KColors.gray),
        const SizedBox(height: 12),
        _FooterLink('potli.com', SiteLinks.website),
        const SizedBox(height: 30),
        const SectionDivider(),
        const SizedBox(height: 24),
        Text(
          SiteLinks.manufacturingAddress,
          style: const TextStyle(
            fontSize: 11,
            height: 1.6,
            color: KColors.gray,
          ),
        ),
        const SizedBox(height: 14),
        _FooterLink(
          'helpdesk@potli.com',
          'mailto:${SiteLinks.supportEmail}',
        ),
        _FooterLink(SiteLinks.supportPhone, 'tel:${SiteLinks.supportPhone}'),
        const SizedBox(height: 30),
        const MicroLabel(
          '© POTLI. ALL RIGHTS RESERVED.',
          color: KColors.gray,
        ),
      ],
    ),
  );
}

class _FooterLink extends StatelessWidget {
  const _FooterLink(this.label, this.url);

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: InkWell(
      onTap: () => _open(url),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12.5, letterSpacing: .2),
      ),
    ),
  );
}
