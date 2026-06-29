import 'package:app_finder_flueco/features/apps/domain/installed_app.dart';
import 'package:app_finder_flueco/features/search/app_search_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSearchEngine', () {
    test('ranks direct name matches first', () async {
      final engine = AppSearchEngine();
      final apps = [
        const InstalledApp(
          name: 'Spotify',
          packageName: 'com.spotify.music',
          category: 'audio',
          utilityTags: ['music', 'podcast'],
        ),
        const InstalledApp(
          name: 'Maps',
          packageName: 'com.google.android.apps.maps',
          category: 'maps',
          utilityTags: ['navigation', 'gps'],
        ),
      ];

      final results = await engine.search(apps, 'spotify');

      expect(results.first.app.name, 'Spotify');
      expect(results.first.reasons, contains('nom exact'));
    });

    test('uses semantic fallback for phrase queries', () async {
      final engine = AppSearchEngine();
      final apps = [
        const InstalledApp(
          name: 'YouTube',
          packageName: 'com.google.android.youtube',
          category: 'video',
          utilityTags: ['streaming', 'watch', 'entertainment'],
        ),
        const InstalledApp(
          name: 'Signal',
          packageName: 'org.thoughtcrime.securesms',
          category: 'communication',
          utilityTags: ['chat', 'messaging'],
        ),
      ];

      final results = await engine.search(apps, 'watch videos');

      expect(results, isNotEmpty);
      expect(results.first.app.name, 'YouTube');
      expect(results.first.reasons, contains('concept vidéo'));
    });

    test('finds messaging apps for a vague request', () async {
      final engine = AppSearchEngine();
      final apps = [
        const InstalledApp(
          name: 'Signal',
          packageName: 'org.thoughtcrime.securesms',
          category: 'communication',
          utilityTags: ['chat', 'messaging'],
        ),
        const InstalledApp(
          name: 'Spotify',
          packageName: 'com.spotify.music',
          category: 'audio',
          utilityTags: ['music', 'podcast'],
        ),
      ];

      final results = await engine.search(apps, 'send messages');

      expect(results.first.app.name, 'Signal');
      expect(results.first.reasons, contains('concept chat'));
    });

    test('uses ai filtering to shortlist vaccine-related apps', () async {
      final engine = AppSearchEngine(
        aiFilterer: (query, apps) async {
          final normalized = query.toLowerCase();
          if (!normalized.contains('vaccin') &&
              !normalized.contains('vaccination')) {
            return const <String>{};
          }

          return apps
              .where((app) => app.utilityTags.any((tag) =>
                  tag.toLowerCase().contains('vaccin') ||
                  tag.toLowerCase().contains('covid')))
              .map((app) => app.packageName)
              .toSet();
        },
      );
      final apps = [
        const InstalledApp(
          name: 'AntiCovid',
          packageName: 'fr.gouv.anticovid',
          category: 'health',
          utilityTags: ['sante', 'vaccin', 'covid'],
        ),
        const InstalledApp(
          name: 'Spotify',
          packageName: 'com.spotify.music',
          category: 'audio',
          utilityTags: ['music', 'podcast'],
        ),
      ];

      final results = await engine.search(apps, 'vaccination');

      expect(results.first.app.name, 'AntiCovid');
      expect(results.first.reasons, contains('concept vaccin'));
    });
  });
}
