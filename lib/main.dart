import 'package:flutter/material.dart';
import 'notification_service.dart';
import 'notification_helpers.dart';
import 'ui/show_now_ui.dart';
import 'ui/schedule_reminders_ui.dart';
import 'ui/custom_medicine_reminders_ui.dart';
import 'ui/show_scheduled_notifications_ui.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

  await NotificationService.initialize();

  // Request permissions when app starts
  // final bool granted =
  //     await NotificationService.requestNotificationPermissions();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notification Demo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const NotificationDemo(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class NotificationDemo extends StatefulWidget {
  const NotificationDemo({super.key});

  @override
  State<NotificationDemo> createState() => _NotificationDemoState();
}

class _NotificationDemoState extends State<NotificationDemo> {
  String _lastAction = 'No action taken yet';

  @override
  void initState() {
    super.initState();

    // Set up a callback to receive notification actions
    NotificationService.onNotificationAction = _onNotificationAction;
  }

  void _onNotificationAction(String actionId, String? payload) {
    debugPrint(
      'App received notification action: $actionId with payload: $payload',
    );

    // Update the UI with the action that was taken
    setState(() {
      if (actionId == skipActionId) {
        _lastAction = 'SKIPPED ($payload)';
      } else if (actionId == takenActionId) {
        _lastAction = 'TAKEN ($payload)';
      } else {
        _lastAction = 'Notification tapped (no specific action)';
      }
    });
  }

  @override
  void dispose() {
    // Remove the callback when the widget is disposed
    NotificationService.onNotificationAction = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Test'), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Text(
                'Last Action: $_lastAction',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const ShowNowUI(),
              const SizedBox(height: 20),
              const ScheduleRemindersUI(),
              const SizedBox(height: 20),
              const CustomMedicineRemindersUI(),
              const SizedBox(height: 20),
              const ShowScheduledNotificationsUI(),
            ],
          ),
        ),
      ),
    );
  }
}
