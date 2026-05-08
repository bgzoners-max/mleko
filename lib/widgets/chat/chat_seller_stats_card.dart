import 'package:flutter/material.dart';
import '../../models/message_reaction_model.dart';

class ChatSellerStatsCard extends StatelessWidget {
  final SellerResponseStats stats;
  const ChatSellerStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            'Obično odgovara za ${stats.medianLabel}',
            style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
          ),
        ],
      ),
    );
  }
}
