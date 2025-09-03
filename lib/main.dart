import 'package:flutter/material.dart';
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
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _hasNotificationPermission = false;

  // Custom medicine reminder times
  TimeOfDay _morningTime = const TimeOfDay(hour: 6, minute: 45);
  TimeOfDay _afternoonTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _eveningTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();

    // Set up a callback to receive notification actions
    NotificationService.onNotificationAction = _onNotificationAction;
    // Check notification permissions
    _checkNotificationPermissions();
  }

  Future<void> _checkNotificationPermissions() async {
    final bool hasPermission =
        await NotificationService.requestNotificationPermissions();
    setState(() {
      _hasNotificationPermission = hasPermission;
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
              const SizedBox(height: 20),
              // Permission status
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _hasNotificationPermission
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                    color:
                        _hasNotificationPermission ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _hasNotificationPermission
                        ? 'Notifications Enabled'
                        : 'Notifications Disabled',
                    style: TextStyle(
                      color:
                          _hasNotificationPermission
                              ? Colors.green
                              : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
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
              // Time picker section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Schedule Notification',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Time: ${_selectedTime.format(context)}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () async {
                            final TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: _selectedTime,
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedTime = picked;
                              });
                            }
                          },
                          child: const Text('Pick Time'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        // Calculate the scheduled time
                        final now = DateTime.now();
                        final scheduledTime = DateTime(
                          now.year,
                          now.month,
                          now.day,
                          _selectedTime.hour,
                          _selectedTime.minute,
                        );

                        // If the time has already passed today, schedule for tomorrow
                        DateTime finalScheduledTime = scheduledTime;
                        if (scheduledTime.isBefore(now)) {
                          finalScheduledTime = scheduledTime.add(
                            const Duration(days: 1),
                          );
                        }

                        await NotificationService.scheduleNotificationAtTime(
                          title: 'Medicine Reminder',
                          body: 'Did you take your medicine?',
                          scheduledTime: finalScheduledTime,
                          payload: 'scheduled_medicine_reminder',
                          useCustomSound: true,
                        );

                        final timeString = _selectedTime.format(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Notification scheduled for $timeString!',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(200, 50),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Schedule Notification'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        await NotificationService.cancelScheduledNotification();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Scheduled notification cancelled!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(200, 50),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Cancel Scheduled'),
                    ),
                    const SizedBox(height: 12),
                    // Custom Medicine Reminders Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.purple.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Custom Medicine Reminders',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.purple.shade700),
                          ),
                          const SizedBox(height: 16),
                          // Morning Medicine Time
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Morning:',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              Text(
                                _morningTime.format(context),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () async {
                                  final TimeOfDay? picked =
                                      await showTimePicker(
                                        context: context,
                                        initialTime: _morningTime,
                                      );
                                  if (picked != null) {
                                    setState(() {
                                      _morningTime = picked;
                                    });
                                  }
                                },
                                child: const Text('Set'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Afternoon Medicine Time
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Afternoon:',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              Text(
                                _afternoonTime.format(context),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () async {
                                  final TimeOfDay? picked =
                                      await showTimePicker(
                                        context: context,
                                        initialTime: _afternoonTime,
                                      );
                                  if (picked != null) {
                                    setState(() {
                                      _afternoonTime = picked;
                                    });
                                  }
                                },
                                child: const Text('Set'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Evening Medicine Time
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Evening:',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              Text(
                                _eveningTime.format(context),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () async {
                                  final TimeOfDay? picked =
                                      await showTimePicker(
                                        context: context,
                                        initialTime: _eveningTime,
                                      );
                                  if (picked != null) {
                                    setState(() {
                                      _eveningTime = picked;
                                    });
                                  }
                                },
                                child: const Text('Set'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              // Schedule custom medicine reminders
                              final now = DateTime.now();
                              final notifications = [
                                {
                                  'title': 'Morning Medicine',
                                  'body': 'Time for your morning medicine!',
                                  'scheduledTime': DateTime(
                                    now.year,
                                    now.month,
                                    now.day,
                                    _morningTime.hour,
                                    _morningTime.minute,
                                  ),
                                  'payload': 'morning_medicine',
                                  'useCustomSound': true,
                                },
                                {
                                  'title': 'Afternoon Medicine',
                                  'body': 'Time for your afternoon medicine!',
                                  'scheduledTime': DateTime(
                                    now.year,
                                    now.month,
                                    now.day,
                                    _afternoonTime.hour,
                                    _afternoonTime.minute,
                                  ),
                                  'payload': 'afternoon_medicine',
                                  'useCustomSound': true,
                                },
                                {
                                  'title': 'Evening Medicine',
                                  'body': 'Time for your evening medicine!',
                                  'scheduledTime': DateTime(
                                    now.year,
                                    now.month,
                                    now.day,
                                    _eveningTime.hour,
                                    _eveningTime.minute,
                                  ),
                                  'payload': 'evening_medicine',
                                  'useCustomSound': true,
                                },
                              ];

                              // Adjust times if they've already passed today
                              for (var notification in notifications) {
                                final scheduledTime =
                                    notification['scheduledTime'] as DateTime;
                                if (scheduledTime.isBefore(now)) {
                                  notification['scheduledTime'] = scheduledTime
                                      .add(const Duration(days: 1));
                                }
                              }

                              await NotificationService.scheduleMultipleNotifications(
                                notifications: notifications,
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Medicine reminders scheduled for ${_morningTime.format(context)}, ${_afternoonTime.format(context)}, and ${_eveningTime.format(context)}!',
                                  ),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(200, 50),
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Schedule Custom Reminders'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _morningTime = const TimeOfDay(
                                  hour: 9,
                                  minute: 0,
                                );
                                _afternoonTime = const TimeOfDay(
                                  hour: 14,
                                  minute: 0,
                                );
                                _eveningTime = const TimeOfDay(
                                  hour: 20,
                                  minute: 0,
                                );
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Times reset to default (9:00 AM, 2:00 PM, 8:00 PM)',
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: const Text('Reset to Default Times'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Daily Recurring Notifications Button
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Daily Recurring Notifications',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.green.shade700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'These will repeat EVERY DAY at your set times',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              // Schedule daily recurring notifications
                              final dailyNotifications = [
                                {
                                  'title': 'Morning Medicine',
                                  'body': 'Time for your morning medicine!',
                                  'time': _morningTime,
                                  'payload': 'daily_morning_medicine',
                                  'useCustomSound': true,
                                },
                                {
                                  'title': 'Afternoon Medicine',
                                  'body': 'Time for your afternoon medicine!',
                                  'time': _afternoonTime,
                                  'payload': 'daily_afternoon_medicine',
                                  'useCustomSound': true,
                                },
                                {
                                  'title': 'Evening Medicine',
                                  'body': 'Time for your evening medicine!',
                                  'time': _eveningTime,
                                  'payload': 'daily_evening_medicine',
                                  'useCustomSound': true,
                                },
                              ];

                              await NotificationService.scheduleMultipleDailyNotifications(
                                dailyNotifications: dailyNotifications,
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Daily recurring reminders set for ${_morningTime.format(context)}, ${_afternoonTime.format(context)}, and ${_eveningTime.format(context)}!',
                                  ),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(200, 50),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Set Daily Recurring'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        await NotificationService.cancelAllScheduledNotifications();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'All scheduled notifications cancelled!',
                            ),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(200, 50),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Cancel All'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
