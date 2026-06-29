import 'package:flueco/flueco.dart';

import '../features/apps/data/installed_apps_repository.dart';
import '../features/apps/presentation/apps_controller.dart';
import '../features/search/app_search_engine.dart';

class AppServiceProvider extends ServiceProvider {
  @override
  Future<void> register(ServiceInjector injector) async {
    injector
        .singleton<InstalledAppsRepository>((_) => InstalledAppsRepository());
    injector.singleton<AppSearchEngine>((_) => AppSearchEngine());
    injector.singleton<AppsController>(
      (resolver) => AppsController(
        repository: resolver.resolve<InstalledAppsRepository>(),
        searchEngine: resolver.resolve<AppSearchEngine>(),
      ),
    );
  }

  @override
  Set<Type> dependsOn() {
    return {};
  }

  @override
  Future<void> initialize(FluecoApp app) async {}

  @override
  Set<Type> registered() {
    return {};
  }
}
