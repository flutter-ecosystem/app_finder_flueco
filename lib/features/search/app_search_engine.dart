import 'package:diacritic/diacritic.dart';

import '../apps/domain/installed_app.dart';

class AppSearchResult {
  const AppSearchResult({required this.app, required this.score, required this.reasons});

  final InstalledApp app;
  final int score;
  final List<String> reasons;
}

class AppSearchEngine {
  List<AppSearchResult> search(List<InstalledApp> apps, String rawQuery) {
    final query = _normalize(rawQuery);
    if (query.isEmpty) {
      return apps.map((app) => AppSearchResult(app: app, score: 0, reasons: const [])).toList();
    }

    final expandedTerms = _expandQuery(query);
    final results = <AppSearchResult>[];

    for (final app in apps) {
      final appName = _normalize(app.name);
      final packageName = _normalize(app.packageName);
      final category = _normalize(app.category);
      final tags = app.utilityTags.map(_normalize).toList();

      var score = 0;
      final reasons = <String>[];

      if (appName == query) {
        score += 120;
        reasons.add('nom exact');
      } else if (appName.startsWith(query)) {
        score += 90;
        reasons.add('nom commence par "$rawQuery"');
      } else if (appName.contains(query)) {
        score += 70;
        reasons.add('nom contient "$rawQuery"');
      }

      if (packageName.contains(query)) {
        score += 35;
        reasons.add('package');
      }

      for (final term in expandedTerms) {
        if (category.contains(term)) {
          score += 45;
          reasons.add('catégorie ${app.category}');
        }
        if (tags.any((tag) => tag.contains(term) || term.contains(tag))) {
          score += 40;
          reasons.add('utilité liée à "$rawQuery"');
        }
      }

      if (score > 0) {
        results.add(AppSearchResult(app: app, score: score, reasons: reasons.toSet().toList()));
      }
    }

    results.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.app.name.toLowerCase().compareTo(b.app.name.toLowerCase());
    });

    return results;
  }

  Set<String> _expandQuery(String query) {
    final terms = query.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toSet();
    final expanded = <String>{query, ...terms};

    const synonyms = <String, List<String>>{
      'musique': ['audio', 'son', 'playlist', 'podcast', 'ecouter', 'listen', 'music'],
      'audio': ['musique', 'son', 'podcast', 'music'],
      'video': ['streaming', 'film', 'serie', 'youtube', 'netflix'],
      'film': ['video', 'streaming', 'serie'],
      'message': ['chat', 'discussion', 'communication', 'social'],
      'navigation': ['maps', 'carte', 'gps', 'itineraire', 'transport'],
      'transport': ['maps', 'navigation', 'taxi', 'gps'],
      'banque': ['finance', 'argent', 'paiement'],
      'photo': ['image', 'camera', 'edition'],
      'travail': ['productivite', 'agenda', 'note', 'tache'],
      'jeu': ['game', 'gaming'],
    };

    for (final term in List<String>.from(expanded)) {
      expanded.addAll(synonyms[term] ?? const []);
    }
    return expanded;
  }

  String _normalize(String value) {
    return removeDiacritics(value.toLowerCase().trim());
  }
}
