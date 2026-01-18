import 'package:flutter/material.dart';
import '../../models/lottery_model.dart';

class BuyTicketScreen extends StatefulWidget {
  final Lottery lottery;
  const BuyTicketScreen({super.key, required this.lottery});

  @override
  State<BuyTicketScreen> createState() => _BuyTicketScreenState();
}

class _BuyTicketScreenState extends State<BuyTicketScreen> {
  final Set<int> selectedTickets = {};

  @override
  Widget build(BuildContext context) {
    final maxTickets = widget.lottery.maxTicketsPerUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lottery.title),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ===== Lottery Info Header =====
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jackpot Prize',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${widget.lottery.jackpot}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select up to $maxTickets tickets',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),

          // ===== Selected Tickets Summary =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selected: ${selectedTickets.length} / $maxTickets',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (selectedTickets.isNotEmpty)
                  Text(
                    selectedTickets.join(', '),
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ===== Ticket Grid =====
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: widget.lottery.totalTickets,
                itemBuilder: (context, index) {
                  final ticket = index + 1;
                  final isSelected = selectedTickets.contains(ticket);
                  final isDisabled =
                      !isSelected && selectedTickets.length >= maxTickets;

                  return GestureDetector(
                    onTap: isDisabled
                        ? null
                        : () {
                            setState(() {
                              if (isSelected) {
                                selectedTickets.remove(ticket);
                              } else {
                                selectedTickets.add(ticket);
                              }
                            });
                          },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.green
                            : isDisabled
                                ? Colors.grey.shade200
                                : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        ticket.toString(),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ===== Buy Button =====
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedTickets.isEmpty
                    ? null
                    : () {
                        // TODO: handle purchase logic
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  selectedTickets.isEmpty
                      ? 'Select Tickets'
                      : 'Buy ${selectedTickets.length} Ticket(s)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
