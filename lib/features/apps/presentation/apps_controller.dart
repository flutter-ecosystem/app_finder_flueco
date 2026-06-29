import 'package:flutter/foundation.dart';

import '../../search/app_search_engine.dart';
import '../data/installed_apps_repository.dart';
import '../domain/installed_app.dart';

class AppsController extends ChangeNotifier {
  AppsController({required this.repository, required this.searchEngine});

  final InstalledAppsRepository repository;
  final AppSearchEngine searchEngine;

  bool isLoading = false;
  String query = '';
  List<InstalledApp> allApps = [];
  List<AppSearchResult> results = [];

  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    allApps = await repository.loadApps();
    results = searchEngine.search(allApps, query);

    isLoading = false;
    notifyListeners();
  }

  void updateQuery(String value) {
    query = value;
    results = searchEngine.search(allApps, query);
    notifyListeners();
  }

  Future<void> launch(InstalledApp app) => repository.launch(app.packageName);
}
