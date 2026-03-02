import 'package:flutter/material.dart';

class JsonViewer extends StatelessWidget {
  final String? jsonString;

  const JsonViewer({super.key, this.jsonString});

  @override
  Widget build(BuildContext context) {
    if (jsonString == null || jsonString!.isEmpty) {
      return Text(
        'null',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
          fontFamily: 'monospace',
        ),
      );
    }

    return Text(
      jsonString!,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[800],
        fontFamily: 'monospace',
      ),
    );
  }
}
