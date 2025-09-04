import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:io' show Platform;

// Define action IDs as constants
const String skipActionId = 'SKIP_ACTION';
const String takenActionId = 'TAKEN_ACTION';

// Define a callback type for handling actions
typedef NotificationActionCallback =
    void Function(String actionId, String? payload);

class NotificationHelpers {
  // Counter for generating unique notification IDs
  static int _notificationIdCounter = 1000;

  /// Get the next unique notification ID
  static int getNextNotificationId() {
    return _notificationIdCounter++;
  }

  /// Create Android notification actions
  static List<AndroidNotificationAction> createNotificationActions() {
    return [
      AndroidNotificationAction(skipActionId, 'Skip', showsUserInterface: true),
      AndroidNotificationAction(
        takenActionId,
        'Taken',
        showsUserInterface: true,
      ),
    ];
  }

  /// Create Android notification details with custom sound
  static AndroidNotificationDetails createAndroidNotificationDetails({
    required String channelId,
    required String channelName,
    required String channelDescription,
    required List<AndroidNotificationAction> actions,
    bool useCustomSound = false,
    String? soundResource,
  }) {
    if (useCustomSound && soundResource != null) {
      return AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound(soundResource),
        playSound: true,
        actions: actions,
      );
    } else {
      return AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        actions: actions,
      );
    }
  }

  /// Create Darwin (iOS/macOS) notification details
  static DarwinNotificationDetails createDarwinNotificationDetails() {
    return const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'medicine_category',
    );
  }

  /// Request notification permissions for Android
  static Future<bool> requestAndroidPermissions(
    FlutterLocalNotificationsPlugin notificationsPlugin,
  ) async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      // Request notification permission (Android 13+)
      final bool? notificationAllowed =
          await androidPlugin?.requestNotificationsPermission();

      // Request exact alarm permission (Android 14+)
      final bool? exactAlarmAllowed =
          await androidPlugin?.requestExactAlarmsPermission();

      return notificationAllowed == true && exactAlarmAllowed == true;
    }
    return true;
  }

  /// Request exact alarm permission for Android
  static Future<bool> requestExactAlarmPermission(
    FlutterLocalNotificationsPlugin notificationsPlugin,
  ) async {
    if (Platform.isAndroid) {
      final bool? hasPermission =
          await notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestExactAlarmsPermission();

      return hasPermission == true;
    }
    return true;
  }

  /// Convert DateTime to TZDateTime
  static tz.TZDateTime convertToTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  /// Calculate next occurrence of a time for daily scheduling
  static DateTime calculateNextOccurrence(TimeOfDay time) {
    final now = DateTime.now();
    DateTime scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If time has already passed today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    return scheduledTime;
  }

  /// Create notification details for different types
  static NotificationDetails createNotificationDetails({
    required String channelId,
    required String channelName,
    required String channelDescription,
    bool useCustomSound = false,
    String? soundResource,
  }) {
    final actions = createNotificationActions();
    final androidDetails = createAndroidNotificationDetails(
      channelId: channelId,
      channelName: channelName,
      channelDescription: channelDescription,
      actions: actions,
      useCustomSound: useCustomSound,
      soundResource: soundResource,
    );
    final darwinDetails = createDarwinNotificationDetails();

    return NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
  }

  /// Handle notification action response
  static void handleNotificationAction(
    NotificationResponse response,
    NotificationActionCallback? callback,
  ) {
    final actionId = response.actionId;
    final payload = response.payload;

    debugPrint('Notification action received: $actionId, payload: $payload');

    // Check which action was pressed
    switch (actionId) {
      case skipActionId:
        debugPrint('Notification SKIPPED!');
        break;
      case takenActionId:
        debugPrint('Notification TAKEN!');
        break;
      default:
        debugPrint('Notification tapped (no specific action)');
        break;
    }

    // Call the external callback if it's set
    if (callback != null) {
      callback(actionId ?? '', payload);
    }
  }
}
