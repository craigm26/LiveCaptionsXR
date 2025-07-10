// Placeholder for AlertDialogs
import 'package:flutter/material.dart';

class AlertDialogs {
  static Future<void> showInfo(BuildContext context, String message) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Info'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }
} 