import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin
  _notifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel channel =
      AndroidNotificationChannel(
        'alerts_channel',
        'Critical Alerts',
        description:
            'Canal para alertas críticas biomédicas',
        importance: Importance.max,
      );

  static Future<void> init() async {
    // Android init
    const android = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(
      android: android,
    );

    await _notifications.initialize(settings);

    // crear canal Android
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  // ALERTA NORMAL
  static Future<void> showAlert(
    String title,
    String body,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'alerts_channel',
      'Critical Alerts',
      channelDescription: 'Alertas biomédicas críticas',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  // TEST
  static Future<void> testNotification() async {
    await showAlert(
      '✅ Prueba de notificación',
      'Las notificaciones funcionan correctamente',
    );
  }
}
