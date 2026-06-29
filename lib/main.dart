import 'package:app_finder_flueco/app/deps_service_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flueco/flueco.dart';

import 'app/app.dart';
import 'app/app_service_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final kernel = FluecoKernel(
    container: GetItServiceContainer(),
    serviceProviders: <ServiceProvider>{
      DependenciesServiceProvider(),
      AppServiceProvider(),
      MessagingServiceProvider(),
    },
  );

  await kernel.bootstrap();
  runApp(AppFinderApp(
    fluecoKernel: kernel,
  ));
}
