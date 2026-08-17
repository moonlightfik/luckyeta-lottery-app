import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/notification_model.dart';
import '../../services/notification_service.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view notifications.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),

      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,

        actions: [
          TextButton(
            onPressed: () async {
              await NotificationService().markAllAsRead(
                userId: user.uid,
              );
            },
            child: const Text(
              "Read all",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.green,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load notifications.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 70,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "No notifications yet",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,

            separatorBuilder: (_, __) =>
                const SizedBox(height: 12),

            itemBuilder: (context, index) {
              final doc = docs[index];

              final notification =
                  AppNotification.fromFirestore(
                doc.id,
                doc.data() as Map<String, dynamic>,
              );

              return _notificationCard(
                context,
                notification,
                user.uid,
              );
            },
          );
        },
      ),
    );
  }

  Widget _notificationCard(
    BuildContext context,
    AppNotification notification,
    String userId,
  ) {
    final isWinner =
        notification.type == 'winner';

    final isLoser =
        notification.type == 'loser';

    final isSoldOut =
        notification.type == 'sold_out';

    final isDrawComplete =
        notification.type == 'draw_complete';

    IconData icon = Icons.notifications;
    Color color = Colors.green;

    if (isWinner) {
      icon = Icons.emoji_events;
      color = Colors.amber.shade700;
    } else if (isLoser) {
      icon = Icons.sentiment_dissatisfied;
      color = Colors.red;
    } else if (isSoldOut) {
      icon = Icons.confirmation_num;
      color = Colors.green;
    } else if (isDrawComplete) {
      icon = Icons.casino;
      color = Colors.purple;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(18),

      onTap: () async {
        if (!notification.isRead) {
          await NotificationService().markAsRead(
            userId: userId,
            notificationId: notification.id,
          );
        }
      },

      child: Container(
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : Colors.green.withOpacity(.06),

          borderRadius: BorderRadius.circular(18),

          border: Border.all(
            color: notification.isRead
                ? Colors.transparent
                : Colors.green.withOpacity(.25),
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(.12),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  color.withOpacity(.15),

              child: Icon(
                icon,
                color: color,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),

                      if (!notification.isRead)
                        Container(
                          width: 9,
                          height: 9,
                          decoration:
                              const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(
                    notification.message,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _formatDate(
                      notification.createdAt,
                    ),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();

    final difference =
        now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    return '${date.day}/${date.month}/${date.year}';
  }
}