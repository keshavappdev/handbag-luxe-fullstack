import '../utils/image_url.dart';

/// One entry from the CMS-managed `sliders` table (get_slider_images),
/// used to drive every campaign/editorial image slot on the home page.
class HomeSlide {
  const HomeSlide({
    required this.id,
    required this.type,
    required this.typeId,
    required this.image,
    this.link = '',
    this.title = '',
    this.subtitle = '',
    this.buttonText = '',
  });

  final String id;
  final String type;
  final String typeId;
  final String image;
  final String link;
  final String title;
  final String subtitle;
  final String buttonText;

  factory HomeSlide.fromJson(Map<String, dynamic> json) {
    return HomeSlide(
      id: '${json['id'] ?? ''}',
      type: '${json['type'] ?? ''}',
      typeId: '${json['type_id'] ?? ''}',
      image: normalizeImageUrl(json['image']),
      link: '${json['link'] ?? ''}',
      title: '${json['title'] ?? ''}',
      subtitle: '${json['subtitle'] ?? ''}',
      buttonText: '${json['button_text'] ?? ''}',
    );
  }
}
