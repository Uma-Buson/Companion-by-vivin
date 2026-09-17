/// Model representing an incoming FCM push notification.
class FcmNotificationModel {
  final String? title;
  final String? body;
  final Map<String, dynamic> data;
  final DateTime receivedAt;

  const FcmNotificationModel({
    this.title,
    this.body,
    this.data = const {},
    required this.receivedAt,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'data': data,
        'receivedAt': receivedAt.toIso8601String(),
      };
}
