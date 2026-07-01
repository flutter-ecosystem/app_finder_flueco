import 'package:easy_localization/easy_localization.dart';
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
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        theme: buildNightNeumorphicTheme(),
        home: const AppsHomePage(),
      ),
    );
  }
}
