import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  // ============================================================
  // NOTIFICATION STREAM
  // ============================================================

  Stream<QuerySnapshot> _notificationStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
  }

  // ============================================================
  // MARK NOTIFICATION AS READ
  // ============================================================

  Future<void> _markAsRead(
    String notificationId,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .doc(notificationId)
        .update({
      'isRead': true,
    });
  }

  // ============================================================
  // MARK ALL AS READ
  // ============================================================

  Future<void> _markAllAsRead(
    List<QueryDocumentSnapshot> notifications,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final firestore =
        FirebaseFirestore.instance;

    final batch = firestore.batch();

    for (final notification
        in notifications) {
      final data =
          notification.data()
              as Map<String, dynamic>;

      final isRead =
          data['isRead'] ?? false;

      if (!isRead) {
        batch.update(
          notification.reference,
          {
            'isRead': true,
          },
        );
      }
    }

    await batch.commit();
  }

  // ============================================================
  // NOTIFICATION ICON
  // ============================================================

  IconData _getNotificationIcon(
    String type,
  ) {
    switch (type) {
      case 'LOTTERY_WON':
        return Icons.emoji_events;

      case 'LOTTERY_LOST':
        return Icons.sentiment_dissatisfied;

      case 'LOTTERY_COMPLETED':
        return Icons.casino;

      case 'LOTTERY_SOLD_OUT':
        return Icons.confirmation_number;

      default:
        return Icons.notifications;
    }
  }

  // ============================================================
  // NOTIFICATION COLOR
  // ============================================================

  Color _getNotificationColor(
    String type,
  ) {
    switch (type) {
      case 'LOTTERY_WON':
        return Colors.amber.shade700;

      case 'LOTTERY_LOST':
        return Colors.red;

      case 'LOTTERY_COMPLETED':
        return Colors.green;

      case 'LOTTERY_SOLD_OUT':
        return Colors.blue;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(
    dynamic timestamp,
  ) {
    if (timestamp == null) {
      return '';
    }

    DateTime date;

    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return '';
    }

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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF6F7F9),

      appBar: AppBar(
        title: const Text(
          'Notifications',
        ),

        backgroundColor:
            Colors.green,

        foregroundColor:
            Colors.white,

        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: _notificationStream(),

            builder: (
              context,
              snapshot,
            ) {
              if (!snapshot.hasData ||
                  snapshot.data!.docs.isEmpty) {
                return const SizedBox();
              }

              final notifications =
                  snapshot.data!.docs;

              final hasUnread =
                  notifications.any((doc) {
                final data =
                    doc.data()
                        as Map<String, dynamic>;

                return data['isRead'] != true;
              });

              if (!hasUnread) {
                return const SizedBox();
              }

              return IconButton(
                tooltip:
                    'Mark all as read',

                icon: const Icon(
                  Icons.done_all,
                ),

                onPressed: () {
                  _markAllAsRead(
                    notifications,
                  );
                },
              );
            },
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationStream(),

        builder: (
          context,
          snapshot,
        ) {
          // ====================================================
          // NOT LOGGED IN
          // ====================================================

          if (FirebaseAuth
                  .instance
                  .currentUser ==
              null) {
            return const Center(
              child: Text(
                'Please log in to see your notifications.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            );
          }

          // ====================================================
          // LOADING
          // ====================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          // ====================================================
          // ERROR
          // ====================================================

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),

                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  children: [
                    Icon(
                      Icons
                          .error_outline,
                      size: 55,
                      color:
                          Colors.red.shade300,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    const Text(
                      'Could not load notifications.',

                      textAlign:
                          TextAlign.center,

                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      '${snapshot.error}',

                      textAlign:
                          TextAlign.center,

                      style: TextStyle(
                        color: Colors
                            .grey
                            .shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ====================================================
          // NO DATA
          // ====================================================

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return _emptyState();
          }

          final notifications =
              snapshot.data!.docs;

          // ====================================================
          // NOTIFICATION LIST
          // ====================================================

          return ListView.separated(
            padding:
                const EdgeInsets.all(16),

            itemCount:
                notifications.length,

            separatorBuilder:
                (_, __) =>
                    const SizedBox(
              height: 10,
            ),

            itemBuilder:
                (context, index) {
              final notification =
                  notifications[index];

              final data =
                  notification.data()
                      as Map<String, dynamic>;

              return _notificationCard(
                context,
                notification,
                data,
              );
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // NOTIFICATION CARD
  // ============================================================

  Widget _notificationCard(
    BuildContext context,
    QueryDocumentSnapshot notification,
    Map<String, dynamic> data,
  ) {
    final title =
        data['title']?.toString() ??
            'Notification';

    final message =
        data['message']?.toString() ??
            '';

    final type =
        data['type']?.toString() ??
            '';

    final isRead =
        data['isRead'] == true;

    final color =
        _getNotificationColor(type);

    final icon =
        _getNotificationIcon(type);

    final time =
        _formatDate(
      data['createdAt'],
    );

    return GestureDetector(
      onTap: () {
        if (!isRead) {
          _markAsRead(
            notification.id,
          );
        }
      },

      child: AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 200,
        ),

        padding:
            const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: isRead
              ? Colors.white
              : Colors.green.shade50,

          borderRadius:
              BorderRadius.circular(18),

          border: Border.all(
            color: isRead
                ? Colors.transparent
                : Colors.green.shade200,
          ),

          boxShadow: [
            BoxShadow(
              color:
                  Colors.grey.shade200,

              blurRadius: 5,

              offset:
                  const Offset(0, 2),
            ),
          ],
        ),

        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // --------------------------------------------------
            // ICON
            // --------------------------------------------------

            Container(
              width: 50,
              height: 50,

              decoration: BoxDecoration(
                color:
                    color.withOpacity(
                  0.15,
                ),

                shape:
                    BoxShape.circle,
              ),

              child: Icon(
                icon,
                color: color,
                size: 25,
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            // --------------------------------------------------
            // CONTENT
            // --------------------------------------------------

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,

                          style:
                              const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),

                      if (!isRead)
                        Container(
                          width: 9,
                          height: 9,

                          decoration:
                              const BoxDecoration(
                            color:
                                Colors.green,
                            shape:
                                BoxShape.circle,
                          ),
                        ),
                    ],
                  ),

                  if (message.isNotEmpty) ...[
                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      message,

                      style: TextStyle(
                        color: Colors
                            .grey
                            .shade700,

                        fontSize: 14,

                        height: 1.3,
                      ),
                    ),
                  ],

                  if (time.isNotEmpty) ...[
                    const SizedBox(
                      height: 7,
                    ),

                    Text(
                      time,

                      style: TextStyle(
                        color: Colors
                            .grey
                            .shade500,

                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          Container(
            width: 80,
            height: 80,

            decoration:
                BoxDecoration(
              color:
                  Colors.green.shade50,

              shape:
                  BoxShape.circle,
            ),

            child: Icon(
              Icons
                  .notifications_none,

              size: 42,

              color:
                  Colors.green.shade400,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          const Text(
            'No notifications yet',

            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight:
                  FontWeight.w500,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            'Your lottery updates will appear here.',

            style: TextStyle(
              color:
                  Colors.grey.shade500,

              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}