import 'package:flutter/foundation.dart';

import '../../search/app_search_engine.dart';
import '../data/installed_apps_repository.dart';
import '../domain/installed_app.dart';

enum AppSortOption { nameAsc, nameDesc, dateAsc, dateDesc }

class AppsController extends ChangeNotifier {
  AppsController({required this.repository, required this.searchEngine});

  final InstalledAppsRepository repository;
  final AppSearchEngine searchEngine;

  bool isLoading = false;
  String query = '';
  AppSortOption sortOption = AppSortOption.nameAsc;
  List<InstalledApp> allApps = [];
  List<AppSearchResult> results = [];

  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    allApps = await repository.loadApps();
    results = await searchEngine.search(allApps, query);
    _applySort();

    isLoading = false;
    notifyListeners();
  }

  Future<void> updateQuery(String value) async {
    query = value;
    results = await searchEngine.search(allApps, query);
    _applySort();
    notifyListeners();
  }

  void updateSort(AppSortOption option) {
    sortOption = option;
    _applySort();
    notifyListeners();
  }

  void _applySort() {
    results.sort((a, b) {
      switch (sortOption) {
        case AppSortOption.nameAsc:
          return a.app.name.toLowerCase().compareTo(b.app.name.toLowerCase());
        case AppSortOption.nameDesc:
          return b.app.name.toLowerCase().compareTo(a.app.name.toLowerCase());
        case AppSortOption.dateAsc:
          final left = a.app.updatedAt ?? a.app.installedAt;
          final right = b.app.updatedAt ?? b.app.installedAt;
          if (left == null && right == null) {
            return a.app.name.toLowerCase().compareTo(b.app.name.toLowerCase());
          }
          if (left == null) return 1;
          if (right == null) return -1;
          return left.compareTo(right);
        case AppSortOption.dateDesc:
          final left = a.app.updatedAt ?? a.app.installedAt;
          final right = b.app.updatedAt ?? b.app.installedAt;
          if (left == null && right == null) {
            return b.app.name.toLowerCase().compareTo(a.app.name.toLowerCase());
          }
          if (left == null) return 1;
          if (right == null) return -1;
          return right.compareTo(left);
      }
    });
  }

  Future<void> launch(InstalledApp app) => repository.launch(app.packageName);
}
