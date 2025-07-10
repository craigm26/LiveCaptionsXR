import 'package:flutter/material.dart';

/// Simple wrapper widget for web routes.
class AppShellWeb extends StatelessWidget {
  final Widget child;
  const AppShellWeb({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
