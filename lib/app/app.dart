import 'package:flueco/flueco.dart';
import 'package:flutter/material.dart';
import '../features/apps/presentation/apps_home_page.dart';
import '../theme/neumorphic_theme.dart';

class AppFinderApp extends StatelessWidget {
  const AppFinderApp({super.key, required FluecoKernel fluecoKernel})
      : _fluecoKernel = fluecoKernel;

  final FluecoKernel _fluecoKernel;

  @override
  Widget build(BuildContext context) {
    return Flueco(
      kernel: _fluecoKernel,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'App Finder',
        theme: buildNightNeumorphicTheme(),
        home: const AppsHomePage(),
      ),
    );
  }
}
