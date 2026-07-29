import 'package:flutter/material.dart';
import '../../../models/lottery_model.dart';
import '../../buy_ticket/buy_ticket_screen.dart';

class ExploreLotteryCard extends StatelessWidget {
  final Lottery lottery;

  const ExploreLotteryCard({
    super.key,
    required this.lottery,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),

      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BuyTicketScreen(
              lottery: lottery,
            ),
          ),
        );
      },

      child: Card(
        elevation: 4,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            //-----------------------
            // IMAGE
            //-----------------------

            Expanded(
              flex: 5,

              child: ClipRRect(

                borderRadius:
                    const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),

                child: lottery.imageUrl != null

                    ? Image.network(
                        lottery.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )

                    : Container(

                        width: double.infinity,

                        color: Color(
                          lottery.themeColor,
                        ),

                        child: const Icon(
                          Icons.emoji_events,
                          size: 55,
                          color: Colors.white,
                        ),

                      ),
              ),
            ),

            //-----------------------
            // DETAILS
            //-----------------------

            Expanded(
              flex: 6,

              child: Padding(

                padding:
                    const EdgeInsets.all(10),

                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(
                      lottery.title,

                      maxLines: 2,

                      overflow:
                          TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      "👤 ${lottery.creatorName}",

                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      lottery.category,

                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "\$${lottery.jackpot}",

                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(

                      children: [

                        const Icon(
                          Icons.schedule,
                          size: 16,
                        ),

                        const SizedBox(width: 4),

                        Expanded(

                          child: Text(

                            lottery.lotteryType ==
                                    "oneTime"

                                ? "One Time"

                                : lottery.drawFrequency,

                            style: const TextStyle(
                              fontSize: 12,
                            ),

                            overflow:
                                TextOverflow.ellipsis,

                          ),

                        ),

                      ],

                    ),

                    const SizedBox(height: 6),

                    Text(
                      "🎟 \$${lottery.pricePerTicket}/ticket",

                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const Spacer(),

                    LinearProgressIndicator(

                      value: lottery.progress,

                      minHeight: 6,

                      borderRadius:
                          BorderRadius.circular(10),

                      backgroundColor:
                          Colors.grey.shade300,

                      valueColor:
                          AlwaysStoppedAnimation(
                        Color(
                          lottery.themeColor,
                        ),
                      ),

                    ),

                    const SizedBox(height: 4),

                    Text(

                      "${lottery.ticketsSold}/${lottery.totalTickets} Tickets Sold",

                      style: const TextStyle(
                        fontSize: 11,
                      ),

                    ),

                  ],

                ),

              ),

            ),

          ],

        ),

      ),

    );
  }
}