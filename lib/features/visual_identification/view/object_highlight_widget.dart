// Placeholder for ObjectHighlightWidget
import 'package:flutter/material.dart';

class ObjectHighlightWidget extends StatelessWidget {
  const ObjectHighlightWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: const Text('Object'),
    );
  }
} 