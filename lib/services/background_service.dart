import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'bluetooth_service.dart';
import 'notification_service.dart';

final FlutterLocalNotificationsPlugin
flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel =
      AndroidNotificationChannel(
        'ble_channel',
        'BLE Monitoring',
        description: 'Monitoreo BLE en segundo plano',
        importance: Importance.low,
      );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,

      autoStart: true,

      isForegroundMode: true,

      notificationChannelId: 'ble_channel',

      initialNotificationTitle: 'Bio Monitor',

      initialNotificationContent:
          'Monitoreando signos vitales...',

      foregroundServiceNotificationId: 888,
    ),

    iosConfiguration: IosConfiguration(),
  );

  service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  final btService = ArduinoBluetoothService.instance;

  final Map<String, int> criticalCounter = {};

  void checkCritical(String type, double value) {
    bool isCritical = false;

    switch (type) {
      case 'HR':
        isCritical = value < 50 || value > 120;
        break;

      case 'SPO2':
        isCritical = value < 90;
        break;

      case 'FR':
        isCritical = value < 10 || value > 25;
        break;

      case 'ET':
        isCritical = value > 60;
        break;
    }

    criticalCounter[type] ??= 0;

    if (isCritical) {
      criticalCounter[type] = criticalCounter[type]! + 1;

      if (criticalCounter[type]! >= 5) {
        NotificationService.showAlert(
          "⚠️ Alerta $type",
          "Se detectaron 5 valores críticos seguidos",
        );

        criticalCounter[type] = 0;
      }
    } else {
      criticalCounter[type] = 0;
    }
  }

  btService.heartRateStream.listen(
    (v) => checkCritical('HR', v),
  );

  btService.spo2Stream.listen(
    (v) => checkCritical('SPO2', v),
  );

  btService.respiratoryStream.listen(
    (v) => checkCritical('FR', v),
  );

  btService.expansionStream.listen(
    (v) => checkCritical('ET', v),
  );

  Timer.periodic(const Duration(seconds: 5), (timer) async {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "Bio Monitor activo",
        content: btService.isConnected
            ? "BLE conectado"
            : "BLE desconectado",
      );
    }
  });
}
