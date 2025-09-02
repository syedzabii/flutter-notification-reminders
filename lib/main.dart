import 'package:flutter/material.dart';
import 'battery_optimization_helper.dart';
import 'notification_service.dart';
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
    // Check and prompt for battery optimization settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BatteryOptimizationHelper.checkAndPrompt(context);
    });
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Last Action: $_lastAction',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  await NotificationService.showNotification(
                    title: 'Take Medicine',
                    body: 'Time to take your medicine!',
                    payload: 'medicine_reminder',
                    useCustomSound: true,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Instant notification shown!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
                child: const Text('Show Now'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await NotificationService.scheduleNotification(
                    title: 'Medicine Reminder',
                    body: 'Did you take your medicine?',
                    duration: const Duration(seconds: 13),
                    payload: 'scheduled_medicine_reminder',
                    useCustomSound: true,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification scheduled in 13 seconds!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
                child: const Text('Schedule in 13s'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
