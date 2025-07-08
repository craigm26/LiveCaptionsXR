// Placeholder for CustomAppBar
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('Live Captions XR'));
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
