import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../screens/citizen/notifications_screen.dart';

class NotificationBell extends StatelessWidget {
  final Color? color;

  const NotificationBell({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final unreadCount = appState.notifications.where((n) => !n.isRead).length;

    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_none, color: color ?? Colors.white, size: 28),
          if (unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
      },
    );
  }
}
