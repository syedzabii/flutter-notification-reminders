import 'package:flutter/material.dart';
import '../notification_service.dart';

class ShowScheduledNotificationsUI extends StatefulWidget {
  const ShowScheduledNotificationsUI({super.key});

  @override
  State<ShowScheduledNotificationsUI> createState() =>
      _ShowScheduledNotificationsUIState();
}

class _ShowScheduledNotificationsUIState
    extends State<ShowScheduledNotificationsUI> {
  List<Map<String, dynamic>> _detailedNotifications = [];
  bool _isLoading = false;

  Future<void> _loadScheduledNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifications =
          await NotificationService.getDetailedPendingNotifications();
      setState(() {
        _detailedNotifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading notifications: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatScheduledTime(Map<String, dynamic> notification) {
    try {
      final scheduledTime = notification['scheduledTime'] as String?;
      return scheduledTime ?? 'Time not available';
    } catch (e) {
      return 'Time unavailable';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'Scheduled Notifications',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.blue.shade700),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _loadScheduledNotifications,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 50),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Text('Show Scheduled Notifications'),
          ),
          const SizedBox(height: 16),
          if (_detailedNotifications.isNotEmpty) ...[
            Text(
              'Found ${_detailedNotifications.length} scheduled notification(s):',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _detailedNotifications.length,
                itemBuilder: (context, index) {
                  final notification = _detailedNotifications[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        notification['title'] ?? 'No Title',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notification['body'] ?? 'No Body'),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: Colors.blue.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Scheduled: ${_formatScheduledTime(notification)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: ${notification['id']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (notification['payload'] != null)
                            Text(
                              'Payload: ${notification['payload']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            ),
          ] else if (!_isLoading) ...[
            Text(
              'No scheduled notifications found.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
