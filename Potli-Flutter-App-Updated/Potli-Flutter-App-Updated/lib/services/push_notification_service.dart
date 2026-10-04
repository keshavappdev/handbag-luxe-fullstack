import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import 'api/fcm_service.dart';
import 'storage_service.dart';

const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'potli_default',
  'POTLI Notifications',
  description: 'Order updates, offers and account alerts',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushNotificationService {
  PushNotificationService(this._storage, this._fcmService);

  final StorageService _storage;
  final FcmService _fcmService;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Poora init try/catch mein hai taaki push ka koi bhi error
    // app ko start hone se na roke.
    try {
      await FirebaseMessaging.instance.requestPermission();

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_androidChannel);

      await _localNotifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );

      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      FirebaseMessaging.instance.onTokenRefresh.listen(_syncToken);

      await syncCurrentTokenIfSignedIn();
    } catch (e) {
      debugPrint('Push init failed: $e');
    }
  }

  /// Call again right after a successful sign-in — the FCM token is usually
  /// already fetched by [init] before the user has an auth token to send it
  /// with, so the first sync attempt is silently skipped.
  Future<void> syncCurrentTokenIfSignedIn() async {
    if (Firebase.apps.isEmpty) return;
    try {
      final messaging = FirebaseMessaging.instance;

      // iOS par FCM token se pehle APNS token chahiye.
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        String? apns = await messaging.getAPNSToken();
        for (int i = 0; i < 10 && apns == null; i++) {
          await Future.delayed(const Duration(milliseconds: 500));
          apns = await messaging.getAPNSToken();
        }
        if (apns == null) {
          // Simulator par ya token late aane par yahin skip hoga.
          // Token aane par onTokenRefresh listener apne aap sync kar dega.
          debugPrint('APNS token abhi nahi mila, skip');
          return;
        }
      }

      final token = await messaging.getToken();
      if (token != null) await _syncToken(token);
    } catch (e) {
      debugPrint('FCM token sync failed: $e');
    }
  }

  Future<void> _syncToken(String token) async {
    if (_storage.authToken.isEmpty) return;
    try {
      await _fcmService.updateFcmToken(token);
    } catch (_) {}
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
