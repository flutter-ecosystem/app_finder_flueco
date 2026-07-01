import 'dart:convert';

import 'package:diacritic/diacritic.dart';
import 'package:http/http.dart' as http;

import '../apps/domain/installed_app.dart';

typedef AppFilterer = Future<Set<String>> Function(
    String query, List<InstalledApp> apps);

class AppSearchResult {
  const AppSearchResult(
      {required this.app, required this.score, required this.reasons});

  final InstalledApp app;
  final int score;
  final List<String> reasons;
}

class AppSearchEngine {
  AppSearchEngine({AppFilterer? aiFilterer})
      : _aiFilterer = aiFilterer ?? _defaultAiFilterer;

  final AppFilterer _aiFilterer;

  Future<List<AppSearchResult>> search(
      List<InstalledApp> apps, String rawQuery) async {
    final query = _normalize(rawQuery);
    if (query.isEmpty) {
      return apps
          .map((app) => AppSearchResult(app: app, score: 0, reasons: const []))
          .toList();
    }

    final aiFilteredPackageNames = await _aiFilterer(rawQuery, apps);
    final candidateApps = aiFilteredPackageNames.isEmpty
        ? apps
        : apps
            .where((app) => aiFilteredPackageNames.contains(app.packageName))
            .toList();

    final ruleBasedResults = _searchWithRules(candidateApps, query, rawQuery);
    final hasStrongMatch = ruleBasedResults.any(
      (result) => result.reasons
          .any((reason) => reason.startsWith('nom ') || reason == 'package'),
    );
    final isPhraseQuery =
        query.split(RegExp(r'\s+')).where((token) => token.isNotEmpty).length >
            1;
    final semanticIntent = _inferSemanticIntent(query);
    final expandedTerms = _expandQuery(query);
    final semanticTerms = {...semanticIntent, ...expandedTerms};

    final hasSemanticEnrichment =
        semanticIntent.isNotEmpty || aiFilteredPackageNames.isNotEmpty;

    if (ruleBasedResults.isNotEmpty &&
        ruleBasedResults.first.score >= 45 &&
        (hasStrongMatch ||
            (!isPhraseQuery &&
                !hasSemanticEnrichment &&
                semanticTerms.length <= expandedTerms.length))) {
      return ruleBasedResults;
    }

    if (candidateApps.isNotEmpty &&
        aiFilteredPackageNames.isNotEmpty &&
        ruleBasedResults.isEmpty) {
      return candidateApps
          .map((app) => AppSearchResult(
              app: app, score: 0, reasons: const ['filtrage IA']))
          .toList();
    }

    return _searchWithSemanticFallback(
      candidateApps,
      query,
      rawQuery,
      ruleBasedResults,
      semanticTerms,
    );
  }

  List<AppSearchResult> _searchWithRules(
      List<InstalledApp> apps, String query, String rawQuery) {
    final expandedTerms = _expandQuery(query);
    final results = <AppSearchResult>[];

    for (final app in apps) {
      final appName = _normalize(app.name);
      final packageName = _normalize(app.packageName);
      final category = _normalize(app.category);
      final tags = app.utilityTags.map(_normalize).toList();
      final searchableText = _normalize(app.searchableText);

      var score = 0;
      final reasons = <String>[];

      if (appName == query) {
        score += 140;
        reasons.add('nom exact');
      } else if (appName.startsWith(query)) {
        score += 95;
        reasons.add('nom commence par "$rawQuery"');
      } else if (appName.contains(query)) {
        score += 75;
        reasons.add('nom contient "$rawQuery"');
      }

      final queryTokens = _tokenize(query);
      for (final token in queryTokens) {
        if (appName.contains(token)) {
          score += 24;
        }
        if (packageName.contains(token)) {
          score += 12;
        }
        if (searchableText.contains(token)) {
          score += 8;
        }
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
        results.add(AppSearchResult(
            app: app, score: score, reasons: reasons.toSet().toList()));
      }
    }

    _sortResults(results);
    return results;
  }

  List<AppSearchResult> _searchWithSemanticFallback(
    List<InstalledApp> apps,
    String query,
    String rawQuery,
    List<AppSearchResult> initialResults,
    Set<String> semanticTerms,
  ) {
    final expandedTerms = _expandQuery(query);
    final results = <AppSearchResult>[];

    for (final app in apps) {
      final appName = _normalize(app.name);
      final category = _normalize(app.category);
      final tags = app.utilityTags.map(_normalize).toList();
      final searchableText = _normalize(app.searchableText);

      var score = 0;
      final reasons = <String>[];

      if (initialResults
          .any((result) => result.app.packageName == app.packageName)) {
        score += 5;
      }

      for (final concept in semanticTerms) {
        final conceptMatches = searchableText.contains(concept) ||
            tags.any((tag) => tag.contains(concept) || concept.contains(tag));
        if (conceptMatches) {
          score += 38;
          reasons.add('concept ${_displayConcept(concept)}');
        }
      }

      for (final term in expandedTerms) {
        if (appName.contains(term)) {
          score += 30;
        }
        if (category.contains(term)) {
          score += 35;
          reasons.add('catégorie ${app.category}');
        }
        if (tags.any((tag) => tag.contains(term) || term.contains(tag))) {
          score += 32;
          reasons.add('utilité liée à "$rawQuery"');
        }
      }

      if (semanticTerms.any((term) => tags.contains(term))) {
        score += 45;
        reasons.add('intention sémantique');
      }

      if (searchableText.contains(query)) {
        score += 20;
      }

      if (score > 0) {
        results.add(AppSearchResult(
            app: app, score: score, reasons: reasons.toSet().toList()));
      }
    }

    _sortResults(results);
    return results;
  }

  Set<String> _inferSemanticIntent(String query) {
    final normalized = _normalize(query);
    final intent = <String>{};

    final intentMap = <String, List<String>>{
      'video': [
        'watch',
        'watching',
        'video',
        'videos',
        'movie',
        'film',
        'stream',
        'streaming',
        'youtube',
        'netflix'
      ],
      'audio': [
        'music',
        'musique',
        'audio',
        'song',
        'songs',
        'podcast',
        'playlist',
        'listen',
        'hear',
        'sound'
      ],
      'message': [
        'message',
        'messages',
        'chat',
        'discussion',
        'messagerie',
        'sms',
        'talk',
        'social'
      ],
      'navigation': [
        'navigation',
        'map',
        'maps',
        'carte',
        'gps',
        'route',
        'itineraire',
        'travel',
        'directions'
      ],
      'finance': [
        'bank',
        'banque',
        'finance',
        'argent',
        'payment',
        'paiement',
        'money'
      ],
      'photo': [
        'photo',
        'photos',
        'image',
        'images',
        'camera',
        'gallery',
        'edit',
        'edition'
      ],
      'productivity': [
        'work',
        'travail',
        'productivite',
        'agenda',
        'note',
        'notes',
        'task',
        'tasks',
        'todo'
      ],
    };

    for (final entry in intentMap.entries) {
      if (entry.value.any((token) => normalized.contains(token))) {
        intent.add(entry.key);
      }
    }

    return intent;
  }

  Set<String> _inferConcepts(String query) {
    final concepts = <String>{};
    final normalized = query;

    final conceptMap = <String, List<String>>{
      'video': [
        'video',
        'videos',
        'movie',
        'film',
        'stream',
        'streaming',
        'watch',
        'watching',
        'youtube',
        'netflix',
        'serie',
        'series'
      ],
      'audio': [
        'audio',
        'music',
        'musique',
        'song',
        'songs',
        'podcast',
        'playlist',
        'listen',
        'hear',
        'sound'
      ],
      'message': [
        'message',
        'messages',
        'chat',
        'discussion',
        'messagerie',
        'sms',
        'talk',
        'social'
      ],
      'navigation': [
        'navigation',
        'map',
        'maps',
        'carte',
        'gps',
        'route',
        'itineraire',
        'travel',
        'directions'
      ],
      'finance': [
        'bank',
        'banque',
        'finance',
        'argent',
        'payment',
        'paiement',
        'money'
      ],
      'photo': [
        'photo',
        'photos',
        'image',
        'images',
        'camera',
        'gallery',
        'edit',
        'edition'
      ],
      'productivity': [
        'work',
        'travail',
        'productivite',
        'agenda',
        'note',
        'notes',
        'task',
        'tasks',
        'todo'
      ],
    };

    for (final entry in conceptMap.entries) {
      if (entry.value.any((token) => normalized.contains(token))) {
        concepts.add(entry.key);
      }
    }

    if (concepts.isEmpty) {
      final tokens = _tokenize(normalized);
      if (tokens.isNotEmpty) {
        concepts.addAll(tokens.take(3));
      }
    }

    return concepts;
  }

  Set<String> _expandQuery(String query) {
    final terms =
        query.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toSet();
    final expanded = <String>{query, ...terms};

    const synonyms = <String, List<String>>{
      'musique': [
        'audio',
        'son',
        'playlist',
        'podcast',
        'ecouter',
        'listen',
        'music'
      ],
      'audio': ['musique', 'son', 'podcast', 'music'],
      'video': ['streaming', 'film', 'serie', 'youtube', 'netflix'],
      'film': ['video', 'streaming', 'serie'],
      'message': [
        'chat',
        'discussion',
        'communication',
        'social',
        'messagerie'
      ],
      'navigation': ['maps', 'carte', 'gps', 'itineraire', 'transport'],
      'transport': ['maps', 'navigation', 'taxi', 'gps'],
      'banque': ['finance', 'argent', 'paiement'],
      'photo': ['image', 'camera', 'edition'],
      'travail': ['productivite', 'agenda', 'note', 'tache'],
      'jeu': ['game', 'gaming'],
      'messagerie': ['message', 'messages', 'chat', 'communication', 'social'],
      'watch': ['video', 'streaming', 'film', 'youtube'],
      'videos': ['video', 'streaming', 'film', 'youtube'],
      'send': ['message', 'messagerie', 'chat'],
      'messages': ['message', 'messagerie', 'chat'],
      'vaccin': ['vaccination', 'covid', 'sante', 'sanitaire', 'protection'],
      'vaccination': ['vaccin', 'covid', 'sante', 'sanitaire', 'protection'],
      'covid': ['vaccin', 'vaccination', 'sante', 'sanitaire', 'protection'],
    };

    for (final term in List<String>.from(expanded)) {
      expanded.addAll(synonyms[term] ?? const []);
    }

    return expanded.where((entry) => entry.isNotEmpty).toSet();
  }

  static Future<Set<String>> _defaultAiFilterer(
      String query, List<InstalledApp> apps) async {
    final appCatalog = apps
        .map((app) => {
              'name': app.name,
              'package': app.packageName,
              'category': app.category,
            })
        .toList();

    final aiMatches = await _defaultAiEnricher(query, appCatalog);
    if (aiMatches.isEmpty) {
      return const <String>{};
    }

    return aiMatches;
  }

  static Set<String> _fallbackAiTerms(String query) {
    final normalized = _normalizeStatic(query);
    final terms = <String>{};

    if (normalized.contains('vaccin') ||
        normalized.contains('vaccination') ||
        normalized.contains('covid')) {
      terms.addAll({
        'vaccin',
        'vaccination',
        'covid',
        'sante',
        'sanitaire',
        'protection'
      });
    }

    if (normalized.contains('message') ||
        normalized.contains('chat') ||
        normalized.contains('discussion')) {
      terms.addAll({'message', 'chat', 'discussion', 'communication'});
    }

    if (normalized.contains('video') ||
        normalized.contains('film') ||
        normalized.contains('watch')) {
      terms.addAll({'video', 'film', 'streaming', 'youtube'});
    }

    if (normalized.contains('musique') ||
        normalized.contains('audio') ||
        normalized.contains('son')) {
      terms.addAll({'audio', 'musique', 'son', 'podcast'});
    }

    if (terms.isEmpty) {
      terms.addAll(_tokenize(normalized).take(4));
    }

    return terms;
  }

  static Future<Set<String>> _defaultAiEnricher(
      String query, List<Map<String, dynamic>> appCatalog) async {
    final apiKey = const String.fromEnvironment('AI_API_KEY', defaultValue: '');
    final apiUrl = const String.fromEnvironment(
      'AI_API_URL',
      defaultValue: 'https://api.openai.com/v1/chat/completions',
    );
    final model =
        const String.fromEnvironment('AI_MODEL', defaultValue: 'gpt-4o-mini');

    if (apiKey.isEmpty) {
      return _fallbackAiMatches(query, appCatalog);
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are an app search router. Given a user query and a list of installed apps with name, package and category, return ONLY the matching package names as a JSON array. Return an empty array if none match.'
            },
            {
              'role': 'user',
              'content': jsonEncode({
                'query': query,
                'apps': appCatalog,
              }),
            },
          ],
          'temperature': 0.2,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          final choices = data['choices'];
          if (choices is List && choices.isNotEmpty) {
            final firstChoice = choices.first;
            if (firstChoice is Map<String, dynamic>) {
              final message = firstChoice['message'];
              if (message is Map<String, dynamic>) {
                final content = message['content'];
                if (content is String) {
                  return _parseAiMatches(content, appCatalog);
                }
              }
            }
          }
        }
      }
    } catch (_) {}

    return _fallbackAiMatches(query, appCatalog);
  }

  static Set<String> _parseAiMatches(
      String content, List<Map<String, dynamic>> appCatalog) {
    try {
      final parsed = jsonDecode(content);
      if (parsed is List) {
        return parsed
            .whereType<String>()
            .where(
                (package) => appCatalog.any((app) => app['package'] == package))
            .toSet();
      }
    } catch (_) {}

    final fallback = _fallbackAiMatches('', appCatalog);
    if (fallback.isNotEmpty) {
      return fallback;
    }

    return const <String>{};
  }

  static Set<String> _fallbackAiMatches(
      String query, List<Map<String, dynamic>> appCatalog) {
    final normalized = _normalizeStatic(query);
    if (normalized.isEmpty) {
      return const <String>{};
    }

    final matchingPackages = <String>{};
    for (final app in appCatalog) {
      final name = _normalizeStatic(app['name']?.toString() ?? '');
      final category = _normalizeStatic(app['category']?.toString() ?? '');
      final haystack = '$name $category';
      if (haystack.contains(normalized)) {
        matchingPackages.add(app['package']?.toString() ?? '');
      }
    }

    return matchingPackages.where((value) => value.isNotEmpty).toSet();
  }

  static String _normalizeStatic(String value) {
    return removeDiacritics(value.toLowerCase().trim());
  }

  static List<String> _tokenize(String value) {
    return value
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.isNotEmpty)
        .toList();
  }

  String _displayConcept(String concept) {
    switch (concept) {
      case 'audio':
        return 'audio';
      case 'video':
        return 'vidéo';
      case 'message':
        return 'messagerie';
      case 'navigation':
        return 'navigation';
      case 'finance':
        return 'finance';
      case 'photo':
        return 'photo';
      case 'productivity':
        return 'productivité';
      default:
        return concept;
    }
  }

  void _sortResults(List<AppSearchResult> results) {
    results.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.app.name.toLowerCase().compareTo(b.app.name.toLowerCase());
    });
  }

  String _normalize(String value) {
    return AppSearchEngine._normalizeStatic(value);
  }
}
