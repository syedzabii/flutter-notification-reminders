import 'package:flutter/material.dart';
import '../notification_service.dart';

class CustomMedicineRemindersUI extends StatefulWidget {
  const CustomMedicineRemindersUI({super.key});

  @override
  State<CustomMedicineRemindersUI> createState() =>
      _CustomMedicineRemindersUIState();
}

class _CustomMedicineRemindersUIState extends State<CustomMedicineRemindersUI> {
  // Custom medicine reminder times
  TimeOfDay _morningTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _afternoonTime = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay _eveningTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.purple.shade700,
                ),
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
                      final TimeOfDay? picked = await showTimePicker(
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
                      final TimeOfDay? picked = await showTimePicker(
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
                      final TimeOfDay? picked = await showTimePicker(
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
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _morningTime = const TimeOfDay(hour: 9, minute: 0);
                    _afternoonTime = const TimeOfDay(hour: 14, minute: 0);
                    _eveningTime = const TimeOfDay(hour: 20, minute: 0);
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.green.shade700),
              ),
              const SizedBox(height: 8),
              Text(
                'These will repeat EVERY DAY at your set times',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  // Check permissions first
                  final bool hasPermission =
                      await NotificationService.requestNotificationPermissions();
                  if (!hasPermission) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification permissions not granted!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  // Schedule daily recurring notifications
                  final dailyNotifications = [
                    {
                      'title': 'Morning Medicine',
                      'body': 'Time for your morning medicine!',
                      'time': _morningTime,
                      'payload':
                          'daily_morning_medicine|${_morningTime.format(context)}',
                      'useCustomSound': true,
                    },
                    {
                      'title': 'Afternoon Medicine',
                      'body': 'Time for your afternoon medicine!',
                      'time': _afternoonTime,
                      'payload':
                          'daily_afternoon_medicine|${_afternoonTime.format(context)}',
                      'useCustomSound': true,
                    },
                    {
                      'title': 'Evening Medicine',
                      'body': 'Time for your evening medicine!',
                      'time': _eveningTime,
                      'payload':
                          'daily_evening_medicine|${_eveningTime.format(context)}',
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
                content: Text('All scheduled notifications cancelled!'),
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
    );
  }
}
