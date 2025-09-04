import 'package:flutter/material.dart';
import '../notification_service.dart';

class ScheduleRemindersUI extends StatefulWidget {
  const ScheduleRemindersUI({super.key});

  @override
  State<ScheduleRemindersUI> createState() => _ScheduleRemindersUIState();
}

class _ScheduleRemindersUIState extends State<ScheduleRemindersUI> {
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    return Container(
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
                finalScheduledTime = scheduledTime.add(const Duration(days: 1));
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
                  content: Text('Notification scheduled for $timeString!'),
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
        ],
      ),
    );
  }
}
