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

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // A static callback that can be set from outside
  static NotificationActionCallback? onNotificationAction;

  static Future<void> initialize() async {
    try {
      // Android initialization
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS/macOS initialization
      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      // Windows initialization

      final InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsDarwin,
          );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _handleNotificationAction(response);
        },
      );

      // Check if app was opened from a notification
      final NotificationAppLaunchDetails? launchDetails =
          await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (launchDetails != null &&
          launchDetails.notificationResponse != null &&
          launchDetails.didNotificationLaunchApp) {
        _handleNotificationAction(launchDetails.notificationResponse!);
      }
    } catch (e) {
      debugPrint('Notification initialization error: $e');
    }
  }

  static Future<bool> requestNotificationPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _notificationsPlugin
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

  // Handler for notification actions
  static void _handleNotificationAction(NotificationResponse response) {
    final actionId = response.actionId;
    final payload = response.payload;

    debugPrint('Notification action received: $actionId, payload: $payload');

    // Check which action was pressed
    switch (actionId) {
      case skipActionId:
        debugPrint('Notification SKIPPED!');
        // Add your skip logic here
        break;
      case takenActionId:
        debugPrint('Notification TAKEN!');
        // Add your taken logic here
        break;
      default:
        debugPrint('Notification tapped (no specific action)');
        // This handles the default tap on the notification body
        break;
    }

    // Call the external callback if it's set
    if (onNotificationAction != null) {
      onNotificationAction!(actionId ?? '', payload);
    }
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    bool useCustomSound = false,
  }) async {
    try {
      // Check permissions first
      final bool hasPermission = await requestNotificationPermissions();
      if (!hasPermission) return;

      // Define action buttons
      final List<AndroidNotificationAction> actions = [
        AndroidNotificationAction(
          skipActionId,
          'Skip',
          // Comment out or remove if you don't have these icons
          // icon: DrawableResourceAndroidBitmap('ic_skip'),
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          takenActionId,
          'Taken',
          // Comment out or remove if you don't have these icons
          // icon: DrawableResourceAndroidBitmap('ic_taken'),
          showsUserInterface: true,
        ),
      ];

      final AndroidNotificationDetails androidNotificationDetails;
      if (useCustomSound) {
        androidNotificationDetails = AndroidNotificationDetails(
          'channel_id_custom_sound',
          'Immediate Notification channel with sound',
          channelDescription: 'Testing Channel Description with sound',
          importance: Importance.max,
          priority: Priority.high,
          sound: const RawResourceAndroidNotificationSound(
            'notification_sound',
          ),
          playSound: true,
          actions: actions,
        );
      } else {
        androidNotificationDetails = AndroidNotificationDetails(
          'channel_id',
          'Immediate Notification channel',
          channelDescription: 'Testing Channel Description',
          importance: Importance.max,
          priority: Priority.high,
          actions: actions,
        );
      }

      // For iOS/macOS
      const DarwinNotificationDetails darwinNotificationDetails =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            // For iOS, you would need to set up categories in AppDelegate
            categoryIdentifier: 'medicine_category',
          );

      await _notificationsPlugin.show(
        0,
        title,
        body,
        NotificationDetails(
          android: androidNotificationDetails,
          iOS: darwinNotificationDetails,
          macOS: darwinNotificationDetails,
        ),
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  static Future<void> scheduleNotification({
    required String title,
    required String body,
    required Duration duration,
    String? payload,
    bool useCustomSound = false,
  }) async {
    try {
      if (Platform.isAndroid) {
        // Request exact alarm permission for Android 14+
        final bool? hasPermission =
            await _notificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >()
                ?.requestExactAlarmsPermission();

        if (hasPermission != true) {
          debugPrint('Exact alarm permission not granted');
          return;
        }
      }

      // Define action buttons
      final List<AndroidNotificationAction> actions = [
        AndroidNotificationAction(
          skipActionId,
          'Skip',
          // Comment out or remove if you don't have these icons
          // icon: DrawableResourceAndroidBitmap('ic_skip'),
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          takenActionId,
          'Taken',
          // Comment out or remove if you don't have these icons
          // icon: DrawableResourceAndroidBitmap('ic_taken'),
          showsUserInterface: true,
        ),
      ];

      final AndroidNotificationDetails androidNotificationDetails;
      if (useCustomSound) {
        androidNotificationDetails = AndroidNotificationDetails(
          'scheduled_channel_id_sound',
          'Scheduled Notification channel with sound',
          channelDescription: 'Scheduled Notifications with sound',
          importance: Importance.max,
          priority: Priority.high,
          sound: const RawResourceAndroidNotificationSound(
            'notification_sound2',
          ),
          playSound: true,
          actions: actions,
        );
      } else {
        androidNotificationDetails = AndroidNotificationDetails(
          'scheduled_channel_id',
          'Scheduled Notification channel',
          channelDescription: 'Scheduled Notifications',
          importance: Importance.max,
          priority: Priority.high,
          actions: actions,
        );
      }

      // For iOS/macOS
      const DarwinNotificationDetails darwinNotificationDetails =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            categoryIdentifier: 'medicine_category',
          );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: darwinNotificationDetails,
        macOS: darwinNotificationDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        1,
        title,
        body,
        tz.TZDateTime.now(tz.local).add(duration),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }
}
