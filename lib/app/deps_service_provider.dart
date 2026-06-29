import 'package:flueco/flueco.dart';
import 'package:flutter/widgets.dart' show GlobalKey, NavigatorState;

///
class DependenciesServiceProvider extends ServiceProvider {
  ///
  DependenciesServiceProvider();
  @override
  Set<Type> dependsOn() {
    return <Type>{};
  }

  @override
  Future<void> initialize(FluecoApp app) async {}

  @override
  Future<void> register(ServiceInjector injector) async {
    injector
      ..lazySingleton<NavigatorKeyProvider>(
        (_) => ExampleNavigationKeyProvider(),
      )
      ..factory<DialogService>(
        (ServiceResolver resolver) => DialogService(
          navigatorKeyProvider: resolver.resolve<NavigatorKeyProvider>(),
        ),
      )
      ..factory<ModalService>(
        (ServiceResolver resolver) => ModalService(
          navigatorKeyProvider: resolver.resolve<NavigatorKeyProvider>(),
        ),
      )
      ..factory<ToastService>(
        (ServiceResolver resolver) => ToastService(
          navigatorKeyProvider: resolver.resolve<NavigatorKeyProvider>(),
        ),
      )
      ..factory<LoggerService>(
        (ServiceResolver resolver) => LoggerService(enable: true),
      )

      /// Dependencies of [MessagingServiceProvider]
      ..lazySingleton<Messaging>((_) => Messaging());
  }

  @override
  Set<Type> registered() {
    return <Type>{
      DialogService,
      ModalService,
      ToastService,
    };
  }
}

/// Implementation of [NavigatorKeyProvider]
final class ExampleNavigationKeyProvider implements NavigatorKeyProvider {
  final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey(debugLabel: 'GlobalNavigationKey');
  @override
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;
}
