import 'package:flutter/material.dart';
import '../notification_service.dart';

class ShowNowUI extends StatelessWidget {
  const ShowNowUI({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
          style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
          child: const Text('Show Now'),
        ),
      ],
    );
  }
}
