import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'widgets/web_navigation_bar.dart';
import 'widgets/hero_section.dart';
import 'widgets/features_section.dart';
import 'widgets/technology_section.dart';
import 'widgets/demo_section.dart';
import 'widgets/about_section.dart';

class WebDemoScreen extends StatelessWidget {
  const WebDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const WebNavigationBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: const [
                  HeroSection(),
                  FeaturesSection(),
                  TechnologySection(),
                  DemoSection(),
                  AboutSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}