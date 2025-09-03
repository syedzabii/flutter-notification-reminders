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

  // Counter for generating unique notification IDs
  static int _notificationIdCounter = 1000;

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

  static Future<void> scheduleNotificationAtTime({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    bool useCustomSound = false,
    int? notificationId,
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
          'scheduled_channel_id_sound_2',
          'Scheduled Notification channel with sound 2',
          channelDescription: 'Time Scheduled Notifications with sound',
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
          'scheduled_channel_id_2',
          'Scheduled Notification channel 2',
          channelDescription: 'Time Scheduled Notifications',
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

      // Convert DateTime to TZDateTime
      final tz.TZDateTime scheduledTZTime = tz.TZDateTime.from(
        scheduledTime,
        tz.local,
      );

      // Use provided ID or generate a unique one using counter
      final int id = notificationId ?? _notificationIdCounter++;

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTZTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
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

  static Future<void> cancelScheduledNotification() async {
    try {
      await _notificationsPlugin.cancel(1);
      debugPrint('Scheduled notification cancelled');
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }

  static Future<void> scheduleMultipleNotifications({
    required List<Map<String, dynamic>> notifications,
  }) async {
    try {
      for (int i = 0; i < notifications.length; i++) {
        final notification = notifications[i];

        // Generate unique ID for each notification BEFORE calling scheduleNotificationAtTime
        final int uniqueId =
            notification['notificationId'] ?? (_notificationIdCounter++);

        await scheduleNotificationAtTime(
          title: notification['title'] ?? 'Reminder',
          body: notification['body'] ?? 'Time for your reminder!',
          scheduledTime: notification['scheduledTime'],
          payload: notification['payload'],
          useCustomSound: notification['useCustomSound'] ?? false,
          notificationId: uniqueId, // Use the pre-generated unique ID
        );

        debugPrint('Scheduled notification with ID: $uniqueId');
      }
      debugPrint(
        '${notifications.length} notifications scheduled successfully',
      );
    } catch (e) {
      debugPrint('Error scheduling multiple notifications: $e');
    }
  }

  static Future<void> cancelAllScheduledNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('All scheduled notifications cancelled');
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  // NEW METHOD: Schedule daily recurring notifications
  static Future<void> scheduleDailyNotification({
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
    bool useCustomSound = false,
    int? notificationId,
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
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          takenActionId,
          'Taken',
          showsUserInterface: true,
        ),
      ];

      final AndroidNotificationDetails androidNotificationDetails;
      if (useCustomSound) {
        androidNotificationDetails = AndroidNotificationDetails(
          'daily_channel_id_sound',
          'Daily Notification channel with sound',
          channelDescription: 'Daily recurring notifications with sound',
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
          'daily_channel_id',
          'Daily Notification channel',
          channelDescription: 'Daily recurring notifications',
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

      // Calculate next occurrence of this time
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

      // Convert to TZDateTime
      final tz.TZDateTime scheduledTZTime = tz.TZDateTime.from(
        scheduledTime,
        tz.local,
      );

      // Use provided ID or generate a unique one
      final int id = notificationId ?? _notificationIdCounter++;

      // Schedule with daily recurrence
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTZTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
        matchDateTimeComponents:
            DateTimeComponents.time, // This makes it repeat daily!
      );

      debugPrint(
        'Daily notification scheduled for ${time.hour}:${time.minute.toString().padLeft(2, '0')} with ID: $id',
      );
    } catch (e) {
      debugPrint('Error scheduling daily notification: $e');
    }
  }

  // Schedule multiple daily recurring notifications
  static Future<void> scheduleMultipleDailyNotifications({
    required List<Map<String, dynamic>> dailyNotifications,
  }) async {
    try {
      // Cancel any existing daily notifications first
      await _cancelAllDailyNotifications();

      for (int i = 0; i < dailyNotifications.length; i++) {
        final notification = dailyNotifications[i];

        // Generate unique ID for each daily notification using time + index
        // More robust unique ID generation
        final TimeOfDay time = notification['time'];
        final int baseId = 1000 + (i * 1000); // Use i*1000 for more separation
        final int timeBasedOffset = (time.hour * 60) + time.minute;
        final int uniqueId = baseId + timeBasedOffset;

        await scheduleDailyNotification(
          title: notification['title'] ?? 'Daily Reminder',
          body: notification['body'] ?? 'Time for your daily reminder!',
          time: notification['time'],
          payload: notification['payload'],
          useCustomSound: notification['useCustomSound'] ?? false,
          notificationId: uniqueId,
        );

        debugPrint(
          'Daily notification scheduled with ID: $uniqueId for time: ${notification['time'].format(null)}',
        );

        // Add small delay to avoid conflicts
        await Future.delayed(const Duration(milliseconds: 100));
      }
      debugPrint(
        '${dailyNotifications.length} daily notifications scheduled successfully',
      );
    } catch (e) {
      debugPrint('Error scheduling multiple daily notifications: $e');
    }
  }

  // Helper method to cancel only daily notifications
  static Future<void> _cancelAllDailyNotifications() async {
    try {
      // Cancel notifications with IDs in the daily range (1000-9999)
      for (int id = 1000; id < 10000; id += 100) {
        await _notificationsPlugin.cancel(id);
      }
      debugPrint('All daily notifications cancelled');
    } catch (e) {
      debugPrint('Error cancelling daily notifications: $e');
    }
  }

  // Reset the notification ID counter (useful for testing or if you need to start fresh)
  static void resetNotificationIdCounter() {
    _notificationIdCounter = 1000;
    debugPrint('Notification ID counter reset to 1000');
  }

  // Get the current notification ID counter value
  static int getCurrentNotificationId() {
    return _notificationIdCounter;
  }
}
