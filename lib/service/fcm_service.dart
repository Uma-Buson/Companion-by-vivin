import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level background message handler required by Firebase Messaging.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    debugPrint('[FCM Background] Received message: ${message.messageId} - ${message.notification?.title}');
  } catch (e) {
    debugPrint('[FCM Background] Error handling background message: $e');
  }
}

/// Service managing Firebase Cloud Messaging (FCM), token retrieval,
/// push notification permissions, and foreground notification display.
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  FirebaseMessaging? _messagingInstance;

  /// Lazy getter that safely accesses FirebaseMessaging only when Firebase is initialized
  FirebaseMessaging? get _messaging {
    try {
      if (Firebase.apps.isNotEmpty) {
        return _messagingInstance ??= FirebaseMessaging.instance;
      }
    } catch (_) {}
    return null;
  }

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  RemoteMessage? _latestMessage;
  RemoteMessage? get latestMessage => _latestMessage;

  final ValueNotifier<String?> tokenNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<RemoteMessage?> messageNotifier =
      ValueNotifier<RemoteMessage?>(null);

  // Android high priority notification channel
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important push notifications.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  /// Initialize Firebase Cloud Messaging
  Future<void> initialize() async {
    if (kIsWeb) return;

    // Firebase Messaging mobile plugins are supported on Android and iOS
    if (!Platform.isAndroid && !Platform.isIOS) {
      debugPrint('[FcmService] FCM is configured for Android and iOS.');
      return;
    }

    try {
      // 1. Set background messaging handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 2. Request notification permissions
      await requestPermission();

      // 3. Initialize local notification display for foreground alerts
      await _setupLocalNotifications();

      // 4. Fetch FCM Device Registration Token
      await fetchFcmToken();

      // 5. Setup foreground and background message listeners
      _setupMessageListeners();
    } catch (e) {
      debugPrint('[FcmService] Initialization error: $e');
    }
  }

  /// Request user notification permissions (prompts system dialog on iOS & Android 13+)
  Future<NotificationSettings?> requestPermission() async {
    try {
      NotificationSettings? settings;

      // 1. Firebase Messaging Permission (iOS, Web, Android)
      final messaging = _messaging;
      if (messaging != null) {
        settings = await messaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
        debugPrint('[FcmService] Authorization status: ${settings.authorizationStatus}');
      }

      // 2. Android 13+ (API 33+) native runtime permission prompt
      if (!kIsWeb && Platform.isAndroid) {
        final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidPlugin?.requestNotificationsPermission();
        debugPrint('[FcmService] Android 13+ Notification Permission granted: $granted');
      }

      // 3. iOS native notification permissions
      if (!kIsWeb && Platform.isIOS) {
        final iosPlugin = _localNotifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      return settings;
    } catch (e) {
      debugPrint('[FcmService] Permission request failed: $e');
      return null;
    }
  }

  /// Retrieve current device registration token from Firebase
  Future<String?> fetchFcmToken() async {
    try {
      final messaging = _messaging;
      if (messaging == null) return null;

      _fcmToken = await messaging.getToken();
      tokenNotifier.value = _fcmToken;
      debugPrint('[FcmService] FCM Device Token: $_fcmToken');

      // Listen for token refreshes
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        tokenNotifier.value = newToken;
        debugPrint('[FcmService] FCM Token Refreshed: $newToken');
      });

      return _fcmToken;
    } catch (e) {
      debugPrint('[FcmService] Error fetching FCM token: $e');
      return null;
    }
  }

  /// Setup local notifications for Android & iOS foreground display
  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('[FcmService] Notification clicked payload: ${response.payload}');
      },
    );

    // Create the high priority Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Enable foreground notification presentation options for iOS
    final messaging = _messaging;
    if (messaging != null) {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Setup listeners for foreground, background resume, and terminated states
  void _setupMessageListeners() {
    // 1. Foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FcmService] Foreground message received: ${message.notification?.title} / ${message.notification?.body}');
      _latestMessage = message;
      messageNotifier.value = message;

      final notification = message.notification;
      // Extract title and body from notification payload or data payload
      final title = notification?.title ??
          message.data['title']?.toString() ??
          'Notification';
      final body = notification?.body ??
          message.data['body']?.toString() ??
          message.data['message']?.toString();

      // Display heads-up banner notification in foreground
      _localNotifications.show(
        notification?.hashCode ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body ?? 'New message received',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: '@mipmap/launcher_icon',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    });

    // 2. Notification opened when app was running in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FcmService] App opened via notification: ${message.notification?.title}');
      _latestMessage = message;
      messageNotifier.value = message;
    });

    // 3. Notification opened when app was terminated
    final messaging = _messaging;
    if (messaging != null) {
      messaging.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          debugPrint('[FcmService] App opened from terminated state by notification: ${message.notification?.title}');
          _latestMessage = message;
          messageNotifier.value = message;
        }
      });
    }
  }

  /// Subscribe to a specific topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      final messaging = _messaging;
      if (messaging != null) {
        await messaging.subscribeToTopic(topic);
        debugPrint('[FcmService] Subscribed to topic: $topic');
      }
    } catch (e) {
      debugPrint('[FcmService] Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      final messaging = _messaging;
      if (messaging != null) {
        await messaging.unsubscribeFromTopic(topic);
        debugPrint('[FcmService] Unsubscribed from topic: $topic');
      }
    } catch (e) {
      debugPrint('[FcmService] Error unsubscribing from topic: $e');
    }
  }
}
