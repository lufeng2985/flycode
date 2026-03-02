import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  final bool isAssistant;

  const Avatar({super.key, required this.isAssistant});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isAssistant
          ? Theme.of(context).colorScheme.primary
          : Colors.grey[400],
      child: Icon(
        isAssistant ? Icons.smart_toy : Icons.person,
        size: 16,
        color: Colors.white,
      ),
    );
  }
}
