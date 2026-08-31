import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  //INITILIZE AWESOME
  static Future<void> init() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'UMPSA Care Notifications',
          channelDescription: 'Notifications for UMPSA Care app',
          defaultColor: const Color(0xFF00A2A5),
          ledColor: const Color(0xFF00A2A5), 
          importance: NotificationImportance.High,
          playSound: true,
          channelShowBadge: true,
        ),
      ],
    );

    // PERMISSION
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    // LISTENER
    await AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: onDismissActionReceivedMethod,
    );
  }

  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    String? referenceId = receivedAction.payload?['reference_id'];
    if (referenceId != null) {
      print("Notification tapped, reference_id = $referenceId");
    }
  }

  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    print("Notification created: ${receivedNotification.id}");
  }

  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    print("Notification displayed: ${receivedNotification.id}");
  }

  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    print("Notification dismissed: ${receivedAction.id}");
  }

  // DISPLAY
  static Future<void> showNotification(String title, String body, { Map<String, String>? payload }) async {
    int id = DateTime.now().millisecondsSinceEpoch.remainder(2147483647);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'basic_channel',
        title: title,
        body: body,
        payload: payload,
        notificationLayout: NotificationLayout.Default,
        backgroundColor: const Color(0xFF00A2A5),
        color: Colors.white, // icon / text color
      ),
    );
  }
}
