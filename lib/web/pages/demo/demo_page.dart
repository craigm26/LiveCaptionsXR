import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubit/web_navigation_cubit.dart';
import 'widgets/hero_section.dart';
import 'widgets/features_section.dart';
import 'widgets/technology_section.dart';
import 'widgets/about_section.dart';
import 'widgets/web_navigation_bar.dart';

class DemoPage extends StatelessWidget {
  const DemoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WebNavigationCubit(),
      child: const _DemoPageContent(),
    );
  }
}

class _DemoPageContent extends StatelessWidget {
  const _DemoPageContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentSection =
        context.watch<WebNavigationCubit>().state.currentSection;

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: WebNavigationBar(),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (currentSection == WebSection.home) const HeroSection(),
            if (currentSection == WebSection.sound) const FeaturesSection(),
            if (currentSection == WebSection.technology) const TechnologySection(),
            if (currentSection == WebSection.about) const AboutSection(),
            // Add other sections as needed
          ],
        ),
      ),
    );
  }
}
