import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'notification_helpers.dart';

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
          NotificationHelpers.handleNotificationAction(
            response,
            onNotificationAction,
          );
        },
      );

      // Check if app was opened from a notification
      final NotificationAppLaunchDetails? launchDetails =
          await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (launchDetails != null &&
          launchDetails.notificationResponse != null &&
          launchDetails.didNotificationLaunchApp) {
        NotificationHelpers.handleNotificationAction(
          launchDetails.notificationResponse!,
          onNotificationAction,
        );
      }
    } catch (e) {
      debugPrint('Notification initialization error: $e');
    }
  }

  static Future<bool> requestNotificationPermissions() async {
    return await NotificationHelpers.requestAndroidPermissions(
      _notificationsPlugin,
    );
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

      final notificationDetails = NotificationHelpers.createNotificationDetails(
        channelId: useCustomSound ? 'channel_id_custom_sound' : 'channel_id',
        channelName:
            useCustomSound
                ? 'Immediate Notification channel with sound'
                : 'Immediate Notification channel',
        channelDescription:
            useCustomSound
                ? 'Testing Channel Description with sound'
                : 'Testing Channel Description',
        useCustomSound: useCustomSound,
        soundResource: useCustomSound ? 'notification_sound' : null,
      );

      await _notificationsPlugin.show(
        0,
        title,
        body,
        notificationDetails,
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
      final bool hasPermission =
          await NotificationHelpers.requestExactAlarmPermission(
            _notificationsPlugin,
          );
      if (!hasPermission) {
        debugPrint('Exact alarm permission not granted');
        return;
      }

      final notificationDetails = NotificationHelpers.createNotificationDetails(
        channelId:
            useCustomSound
                ? 'scheduled_channel_id_sound_2'
                : 'scheduled_channel_id_2',
        channelName:
            useCustomSound
                ? 'Scheduled Notification channel with sound 2'
                : 'Scheduled Notification channel 2',
        channelDescription:
            useCustomSound
                ? 'Time Scheduled Notifications with sound'
                : 'Time Scheduled Notifications',
        useCustomSound: useCustomSound,
        soundResource: useCustomSound ? 'notification_sound2' : null,
      );

      // Convert DateTime to TZDateTime
      final tz.TZDateTime scheduledTZTime =
          NotificationHelpers.convertToTZDateTime(scheduledTime);

      // Use provided ID or generate a unique one
      final int id =
          notificationId ?? NotificationHelpers.getNextNotificationId();

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
      final bool hasPermission =
          await NotificationHelpers.requestExactAlarmPermission(
            _notificationsPlugin,
          );
      if (!hasPermission) {
        debugPrint('Exact alarm permission not granted');
        return;
      }

      final notificationDetails = NotificationHelpers.createNotificationDetails(
        channelId:
            useCustomSound
                ? 'scheduled_channel_id_sound'
                : 'scheduled_channel_id',
        channelName:
            useCustomSound
                ? 'Scheduled Notification channel with sound'
                : 'Scheduled Notification channel',
        channelDescription:
            useCustomSound
                ? 'Scheduled Notifications with sound'
                : 'Scheduled Notifications',
        useCustomSound: useCustomSound,
        soundResource: useCustomSound ? 'notification_sound2' : null,
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
            notification['notificationId'] ??
            NotificationHelpers.getNextNotificationId();

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

  /// Get all pending (scheduled) notifications
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    try {
      final List<PendingNotificationRequest> pendingNotifications =
          await _notificationsPlugin.pendingNotificationRequests();
      return pendingNotifications;
    } catch (e) {
      debugPrint('Error getting pending notifications: $e');
      return [];
    }
  }

  /// Get detailed notification information including scheduled times
  static Future<List<Map<String, dynamic>>>
  getDetailedPendingNotifications() async {
    try {
      final List<PendingNotificationRequest> pendingNotifications =
          await _notificationsPlugin.pendingNotificationRequests();

      // Convert to detailed format with additional information
      return pendingNotifications.map((notification) {
        return {
          'id': notification.id,
          'title': notification.title,
          'body': notification.body,
          'payload': notification.payload,
          'scheduledTime': _getScheduledTimeFromPayload(notification.payload),
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting detailed pending notifications: $e');
      return [];
    }
  }

  /// Extract scheduled time information from payload
  static String _getScheduledTimeFromPayload(String? payload) {
    if (payload == null) return 'Time not available';

    // Try to extract time information from payload
    // Format: "payload_type|time_info"
    if (payload.contains('|')) {
      final parts = payload.split('|');
      if (parts.length >= 2) {
        final timeInfo = parts[1];
        if (timeInfo.contains('daily')) {
          return 'Daily recurring';
        } else if (timeInfo.contains(':')) {
          return 'Scheduled for $timeInfo';
        }
      }
    }

    // For daily recurring notifications
    if (payload.contains('daily')) {
      return 'Daily recurring';
    }

    // For one-time notifications
    return 'One-time notification';
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
      final bool hasPermission =
          await NotificationHelpers.requestExactAlarmPermission(
            _notificationsPlugin,
          );
      if (!hasPermission) {
        debugPrint('Exact alarm permission not granted');
        return;
      }

      final notificationDetails = NotificationHelpers.createNotificationDetails(
        channelId:
            useCustomSound ? 'daily_channel_id_sound' : 'daily_channel_id',
        channelName:
            useCustomSound
                ? 'Daily Notification channel with sound'
                : 'Daily Notification channel',
        channelDescription:
            useCustomSound
                ? 'Daily recurring notifications with sound'
                : 'Daily recurring notifications',
        useCustomSound: useCustomSound,
        soundResource: useCustomSound ? 'notification_sound2' : null,
      );

      // Calculate next occurrence of this time
      final DateTime scheduledTime =
          NotificationHelpers.calculateNextOccurrence(time);

      // Convert to TZDateTime
      final tz.TZDateTime scheduledTZTime =
          NotificationHelpers.convertToTZDateTime(scheduledTime);

      // Use provided ID or generate a unique one
      final int id =
          notificationId ?? NotificationHelpers.getNextNotificationId();

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
      for (int i = 0; i < dailyNotifications.length; i++) {
        final notification = dailyNotifications[i];

        await scheduleDailyNotification(
          title: notification['title'] ?? 'Daily Reminder',
          body: notification['body'] ?? 'Time for your daily reminder!',
          time: notification['time'],
          payload: notification['payload'],
          useCustomSound: notification['useCustomSound'] ?? false,
        );

        debugPrint(
          'Daily notification scheduled for time: ${notification['time']}',
        );
      }

      debugPrint(
        '${dailyNotifications.length} daily notifications scheduled successfully',
      );
    } catch (e) {
      debugPrint('Error scheduling multiple daily notifications: $e');
    }
  }
}
