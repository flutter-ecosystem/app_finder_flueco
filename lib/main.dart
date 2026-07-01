import 'package:app_finder_flueco/app/deps_service_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flueco/flueco.dart';

import 'app/app.dart';
import 'app/app_service_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final kernel = FluecoKernel(
    container: GetItServiceContainer(),
    serviceProviders: <ServiceProvider>{
      DependenciesServiceProvider(),
      AppServiceProvider(),
      MessagingServiceProvider(),
    },
  );

  await kernel.bootstrap();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('fr')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: AppFinderApp(
        fluecoKernel: kernel,
      ),
    ),
  );
}
