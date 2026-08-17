
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/lottery_model.dart';
import '../buy_ticket/buy_ticket_screen.dart';

class LotteryDetails extends StatelessWidget {
  final String lotteryId;

  const LotteryDetails({
    super.key,
    required this.lotteryId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('lotteries')
          .doc(lotteryId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.green,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Lottery'),
            ),
            body: Center(
              child: Text(
                'Something went wrong.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Lottery'),
            ),
            body: const Center(
              child: Text('Lottery not found.'),
            ),
          );
        }

        final data = snapshot.data!.data();

        if (data == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Lottery'),
            ),
            body: const Center(
              child: Text(
                'Lottery data is unavailable.',
              ),
            ),
          );
        }

        final lottery = Lottery.fromFirestore(
          lotteryId,
          data,
        );

        return _buildPage(
          context,
          lottery,
        );
      },
    );
  }

  // ============================================================
  // MAIN PAGE
  // ============================================================

  Widget _buildPage(
    BuildContext context,
    Lottery lottery,
  ) {
    final user = FirebaseAuth.instance.currentUser;

    final String title = lottery.title;

    final String description =
        lottery.description;

    final String status =
        lottery.status;

    final int jackpot =
        lottery.jackpot.toInt();

    final int pricePerTicket =
        lottery.pricePerTicket.toInt();

    final int totalTickets =
        lottery.totalTickets;

    final int ticketsSold =
        lottery.ticketsSold;

    final int remainingTickets =
        lottery.remainingTickets;

    final int maxTicketsPerUser =
        lottery.maxTicketsPerUser;

    final int numberOfWinners =
        lottery.numberOfWinners;

    final String imageUrl =
        lottery.imageUrl ?? '';

    final String creatorName =
        lottery.creatorName;

    final DateTime? nextDrawAt =
        lottery.nextDrawAt;

    final List<int> winningNumbers =
        lottery.winningTicketNumbers;

    final List<String> winnerIds =
        lottery.winnerIds;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lottery Details',
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: user == null
            ? const Stream.empty()
            : FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('tickets')
                .where(
                  'lotteryID',
                  isEqualTo: lotteryId,
                )
                .snapshots(),
        builder: (context, ticketSnapshot) {
          final tickets =
              ticketSnapshot.data?.docs ?? [];

          final userTickets =
              tickets.map((doc) {
            final data =
                doc.data()
                    as Map<String, dynamic>;

            return data;
          }).toList();

          final int userTicketCount =
              userTickets.length;

          final bool reachedLimit =
              userTicketCount >=
                  maxTicketsPerUser;

          final bool noTicketsLeft =
              remainingTickets <= 0;

          final bool canBuy =
              status == 'ACTIVE' &&
              !reachedLimit &&
              !noTicketsLeft;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ==================================================
                // IMAGE
                // ==================================================

                _buildImage(imageUrl),

                const SizedBox(height: 18),

                // ==================================================
                // TITLE + CREATOR + STATUS
                // ==================================================

                _buildTitleSection(
                  title: title,
                  creatorName: creatorName,
                  status: status,
                ),

                const SizedBox(height: 16),

                // ==================================================
                // PRIZE
                // ==================================================

                _buildPrizeCard(
                  jackpot: jackpot,
                  numberOfWinners:
                      numberOfWinners,
                ),

                const SizedBox(height: 16),

                // ==================================================
                // LOTTERY INFORMATION
                // ==================================================

                _buildExtraLotteryInfo(
                  lottery,
                ),

                const SizedBox(height: 16),

                // ==================================================
                // TICKET INFORMATION
                // ==================================================

                _buildInfoCard(
                  pricePerTicket:
                      pricePerTicket,
                  ticketsSold:
                      ticketsSold,
                  totalTickets:
                      totalTickets,
                  remainingTickets:
                      remainingTickets,
                  maxTicketsPerUser:
                      maxTicketsPerUser,
                  userTicketCount:
                      userTicketCount,
                ),

                const SizedBox(height: 16),

                // ==================================================
                // DESCRIPTION
                // ==================================================

                if (description.isNotEmpty)
                  _buildDescription(
                    description,
                  ),

                if (description.isNotEmpty)
                  const SizedBox(height: 16),

                // ==================================================
                // RESULT / BUY SECTION
                // ==================================================

                if (status == 'COMPLETED')
                  _buildCompletedResult(
                    context: context,
                    lottery: lottery,
                    userTickets:
                        userTickets,
                    winningNumbers:
                        winningNumbers,
                    winnerIds:
                        winnerIds,
                  )
                else if (status == 'DRAWING')
                  _buildDrawingCard()
                else
                  _buildActiveSection(
                    context: context,
                    lottery: lottery,
                    userTickets:
                        userTickets,
                    userTicketCount:
                        userTicketCount,
                    maxTicketsPerUser:
                        maxTicketsPerUser,
                    canBuy: canBuy,
                    reachedLimit:
                        reachedLimit,
                    noTicketsLeft:
                        noTicketsLeft,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // IMAGE
  // ============================================================

  Widget _buildImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius:
              BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.local_activity,
          size: 70,
          color: Colors.green,
        ),
      );
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(20),
      child: Image.network(
        imageUrl,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) {
          return Container(
            height: 220,
            color: Colors.grey.shade200,
            child: const Icon(
              Icons.image_not_supported,
              size: 60,
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // TITLE
  // ============================================================

  Widget _buildTitleSection({
    required String title,
    required String creatorName,
    required String status,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Created by $creatorName',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        _statusBadge(status),
      ],
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _statusBadge(String status) {
    Color color;

    switch (status) {
      case 'COMPLETED':
        color = Colors.green;
        break;

      case 'DRAWING':
        color = Colors.green;
        break;

      case 'SOLD_OUT':
        color = Colors.green;
        break;

      default:
        color = Colors.green;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight:
              FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // ============================================================
  // PRIZE
  // ============================================================

  Widget _buildPrizeCard({
    required int jackpot,
    required int numberOfWinners,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(20),
        color: Colors.green.withOpacity(.08),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.workspace_premium,
            color: Colors.green,
            size: 45,
          ),
          const SizedBox(height: 8),
          const Text(
            'JACKPOT',
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$jackpot ETB',
            style: const TextStyle(
              fontSize: 28,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$numberOfWinners winner(s)',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TICKET INFORMATION
  // ============================================================

  Widget _buildInfoCard({
    required int pricePerTicket,
    required int ticketsSold,
    required int totalTickets,
    required int remainingTickets,
    required int maxTicketsPerUser,
    required int userTicketCount,
  }) {
    final double progress =
        totalTickets <= 0
            ? 0
            : (ticketsSold / totalTickets)
                .clamp(0.0, 1.0);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _infoRow(
              'Ticket price',
              '$pricePerTicket ETB',
            ),
            _infoRow(
              'Tickets sold',
              '$ticketsSold / $totalTickets',
            ),
            _infoRow(
              'Remaining',
              '$remainingTickets',
            ),
            _infoRow(
              'Your tickets',
              '$userTicketCount / '
                  '$maxTicketsPerUser',
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius:
                  BorderRadius.circular(10),
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        children: [
          Text(title),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOTTERY INFORMATION
  // ============================================================

  Widget _buildExtraLotteryInfo(
    Lottery lottery,
  ) {
    return Card(
      elevation: 1,
      color: Colors.green.withOpacity(.04),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.green.withOpacity(.15),
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Lottery Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 14),

            _greenInfoRow(
              Icons.calendar_today,
              'Created',
              _formatDate(
                lottery.createdAt,
              ),
            ),

            _greenInfoRow(
              Icons.schedule,
              'Draw time',
              lottery.nextDrawAt != null
                  ? _formatDate(
                      lottery.nextDrawAt!,
                    )
                  : 'Not set',
            ),

            _greenInfoRow(
              Icons.emoji_events,
              'Number of winners',
              '${lottery.numberOfWinners}',
            ),

            _greenInfoRow(
              Icons.repeat,
              'Draw frequency',
              lottery.drawFrequency ??
                  'One time',
            ),
          ],
        ),
      ),
    );
  }

  Widget _greenInfoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 14,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color:
                  Colors.green.withOpacity(.10),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.green,
              size: 19,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color:
                    Colors.grey.shade700,
              ),
            ),
          ),

          Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight:
                  FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DESCRIPTION
  // ============================================================

  Widget _buildDescription(
    String description,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'About this lottery',
          style: TextStyle(
            fontSize: 18,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            color: Colors.grey.shade700,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ACTIVE LOTTERY
  // ============================================================

  Widget _buildActiveSection({
    required BuildContext context,
    required Lottery lottery,
    required List<Map<String, dynamic>>
        userTickets,
    required int userTicketCount,
    required int maxTicketsPerUser,
    required bool canBuy,
    required bool reachedLimit,
    required bool noTicketsLeft,
  }) {
    if (userTickets.isNotEmpty) {
      return _buildUserTickets(
        userTickets,
        maxTicketsPerUser,
      );
    }

    if (noTicketsLeft) {
      return _messageCard(
        icon: Icons.block,
        color: Colors.orange,
        title: 'Tickets Sold Out',
        message:
            'All tickets have been purchased. '
            'Good luck to everyone in the draw! 🍀',
      );
    }

    if (reachedLimit) {
      return _messageCard(
        icon: Icons.check_circle,
        color: Colors.green,
        title: 'Ticket Limit Reached',
        message:
            'You have reached your ticket limit '
            'for this lottery.\n\nGood luck! 🍀',
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canBuy
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BuyTicketScreen(
                          lottery: lottery,
                        ),
                      ),
                    );
                  }
                : null,
            style:
                ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(
                vertical: 16,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'Choose Tickets',
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          'Choose your lucky numbers and '
          'try your luck! 🍀',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ============================================================
  // USER TICKETS
  // ============================================================

  Widget _buildUserTickets(
    List<Map<String, dynamic>> tickets,
    int maxTicketsPerUser,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              '🎟 Your Lucky Tickets',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              '${tickets.length} / '
              '$maxTicketsPerUser tickets',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children:
                  tickets.map((ticket) {
                final number =
                    ticket['ticketNumber'];

                final ticketStatus =
                    ticket['status']
                            ?.toString() ??
                        'ACTIVE';

                return _ticketChip(
                  number: number,
                  status: ticketStatus,
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            const Text(
              '🍀 Good luck! Waiting for the draw...',
              style: TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ticketChip({
    required dynamic number,
    required String status,
  }) {
    Color color = Colors.green;

    if (status == 'WON') {
      color = Colors.amber.shade700;
    } else if (status == 'LOST') {
      color = Colors.red;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(.4),
        ),
      ),
      child: Column(
        children: [
          Text(
            '#$number',
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
              color: color,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DRAWING
  // ============================================================

  Widget _buildDrawingCard() {
    return _messageCard(
      icon: Icons.hourglass_top,
      color: Colors.orange,
      title: 'Draw in Progress',
      message:
          'The lottery draw is currently '
          'being processed.\n\n'
          'Please wait for the results. 🍀',
    );
  }

  // ============================================================
  // COMPLETED RESULT
  // ============================================================

  Widget _buildCompletedResult({
    required BuildContext context,
    required Lottery lottery,
    required List<Map<String, dynamic>>
        userTickets,
    required List<int> winningNumbers,
    required List<String> winnerIds,
  }) {
    final user =
        FirebaseAuth.instance.currentUser;

    final bool currentUserWon =
        user != null &&
        winnerIds.contains(user.uid);

    if (currentUserWon) {
      return _winnerCard(
        userTickets: userTickets,
        winningNumbers:
            winningNumbers,
        lottery: lottery,
      );
    }

    return Column(
      children: [
        _loserCard(userTickets),

        const SizedBox(height: 16),

        _winningResultCard(
          lottery: lottery,
          winningNumbers:
              winningNumbers,
          winnerIds: winnerIds,
        ),
      ],
    );
  }

  // ============================================================
  // WINNER
  // ============================================================

  Widget _winnerCard({
    required List<Map<String, dynamic>>
        userTickets,
    required List<int> winningNumbers,
    required Lottery lottery,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color:
            Colors.amber.withOpacity(.12),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color:
              Colors.amber.withOpacity(.4),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events,
            color: Colors.amber,
            size: 65,
          ),
          const SizedBox(height: 10),
          const Text(
            'YOU WON! 🎉',
            style: TextStyle(
              fontSize: 26,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Congratulations!',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Winning ticket(s): '
            '${winningNumbers.map((e) => '#$e').join(', ')}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Prize: '
            '${lottery.jackpot.toInt()} ETB',
            style: const TextStyle(
              fontWeight:
                  FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOSER
  // ============================================================

  Widget _loserCard(
    List<Map<String, dynamic>> tickets,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color:
            Colors.red.withOpacity(.07),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.sentiment_dissatisfied,
            color: Colors.red,
            size: 55,
          ),
          const SizedBox(height: 10),
          const Text(
            '🍀 Better Luck Next Time',
            style: TextStyle(
              fontSize: 21,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            tickets.isEmpty
                ? 'This lottery has ended.'
                : 'None of your tickets were '
                  'selected this time.',
            textAlign: TextAlign.center,
          ),
          if (tickets.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children:
                  tickets.map((ticket) {
                return _ticketChip(
                  number:
                      ticket['ticketNumber'],
                  status:
                      ticket['status']
                              ?.toString() ??
                          'LOST',
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Your next win could be waiting '
            'for you! 💚',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WINNING RESULT
  // ============================================================

  Widget _winningResultCard({
    required Lottery lottery,
    required List<int> winningNumbers,
    required List<String> winnerIds,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              '🏆 Lottery Result',
              style: TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Winning ticket(s)',
              style: TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children:
                  winningNumbers.map(
                (number) {
                  return _ticketChip(
                    number: number,
                    status: 'WINNER',
                  );
                },
              ).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              winnerIds.isEmpty
                  ? 'Winner information unavailable.'
                  : '${winnerIds.length} '
                    'winner(s) selected.',
              style: TextStyle(
                color:
                    Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE CARD
  // ============================================================

  Widget _messageCard({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 48,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign:
                TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _formatDate(DateTime date) {
    final hour =
        date.hour.toString().padLeft(2, '0');

    final minute =
        date.minute.toString().padLeft(2, '0');

    return '${date.day}/${date.month}/${date.year} '
        '$hour:$minute';
  }
}

