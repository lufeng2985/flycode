import 'package:flutter/material.dart';

class ReasoningWidget extends StatelessWidget {
  final dynamic reasoning;

  const ReasoningWidget({super.key, required this.reasoning});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, size: 14, color: Colors.purple[700]),
              const SizedBox(width: 6),
              Text(
                'Reasoning',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            reasoning.text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.purple[900],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
