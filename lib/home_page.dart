import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed('/features'),
              child: const Text('Go to Features'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed('/demo'),
              child: const Text('Go to Demo'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed('/technology'),
              child: const Text('Go to Technology'),
            ),
          ],
        ),
      ),
    );
  }
} 