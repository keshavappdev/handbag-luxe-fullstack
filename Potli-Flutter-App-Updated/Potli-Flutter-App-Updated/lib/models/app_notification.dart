class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.image,
    required this.dateSent,
  });

  final String id;
  final String title;
  final String message;
  final String image;
  final String dateSent;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      message: '${json['message'] ?? ''}',
      image: '${json['image'] ?? ''}',
      dateSent: '${json['date_sent'] ?? ''}',
    );
  }
}
