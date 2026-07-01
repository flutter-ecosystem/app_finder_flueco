import 'dart:typed_data';
import 'package:flutter/services.dart';

import '../domain/installed_app.dart';

class InstalledAppsRepository {
  static const MethodChannel _channel =
      MethodChannel('app_finder_flueco/installed_apps');

  Future<List<InstalledApp>> loadApps() async {
    final rawApps =
        await _channel.invokeListMethod<dynamic>('getInstalledApps') ??
            const <dynamic>[];

    final apps = rawApps
        .whereType<Map<dynamic, dynamic>>()
        .map(_mapNativeApp)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return apps;
  }

  Future<void> launch(String packageName) async {
    await _channel.invokeMethod<bool>('launchApp', <String, Object?>{
      'packageName': packageName,
    });
  }

  InstalledApp _mapNativeApp(Map<dynamic, dynamic> app) {
    final name = (app['name'] as String?) ?? '';
    final packageName = (app['packageName'] as String?) ?? '';
    final category = (app['category'] as String?) ?? 'undefined';
    final icon = app['icon'];
    final installedAtMillis = app['installedAtMillis'] as int?;
    final updatedAtMillis = app['updatedAtMillis'] as int?;

    return InstalledApp(
      name: name,
      packageName: packageName,
      category: category,
      icon: icon is Uint8List ? icon : null,
      isSystemApp: (app['isSystemApp'] as bool?) ?? false,
      installedAt: installedAtMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(installedAtMillis)
          : null,
      updatedAt: updatedAtMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(updatedAtMillis)
          : null,
      utilityTags: _inferUtilityTags(name, packageName, category),
    );
  }

  List<String> _inferUtilityTags(
      String name, String packageName, String category) {
    final normalizedCategory = category.toLowerCase();
    final text = '$name $packageName $normalizedCategory'.toLowerCase();
    final tags = <String>{
      if (normalizedCategory != 'undefined') normalizedCategory
    };

    void addIf(bool condition, List<String> values) {
      if (condition) tags.addAll(values);
    }

    addIf(
      text.contains('spotify') ||
          text.contains('deezer') ||
          text.contains('music') ||
          text.contains('podcast') ||
          normalizedCategory == 'audio',
      [
        'musique',
        'audio',
        'son',
        'playlist',
        'podcast',
        'écouter',
        'streaming audio'
      ],
    );
    addIf(
      text.contains('youtube') ||
          text.contains('netflix') ||
          text.contains('prime') ||
          text.contains('disney') ||
          normalizedCategory == 'video',
      ['vidéo', 'streaming', 'film', 'série', 'divertissement'],
    );
    addIf(
      text.contains('maps') ||
          text.contains('waze') ||
          text.contains('uber') ||
          text.contains('bolt') ||
          normalizedCategory == 'maps',
      ['carte', 'navigation', 'transport', 'itinéraire', 'gps'],
    );
    addIf(
      text.contains('whatsapp') ||
          text.contains('telegram') ||
          text.contains('signal') ||
          text.contains('messenger') ||
          text.contains('discord') ||
          normalizedCategory == 'social',
      ['message', 'chat', 'discussion', 'communication', 'social'],
    );
    addIf(
      text.contains('bank') ||
          text.contains('banque') ||
          text.contains('paypal') ||
          text.contains('revolut') ||
          text.contains('boursorama') ||
          text.contains('fortuneo'),
      ['finance', 'banque', 'argent', 'paiement', 'budget'],
    );
    addIf(
      text.contains('photo') ||
          text.contains('camera') ||
          text.contains('gallery') ||
          normalizedCategory == 'image',
      ['photo', 'image', 'caméra', 'édition', 'galerie'],
    );
    addIf(
      text.contains('calendar') ||
          text.contains('agenda') ||
          text.contains('todo') ||
          text.contains('notion') ||
          text.contains('notes') ||
          normalizedCategory == 'productivity',
      ['productivité', 'agenda', 'tâche', 'note', 'travail'],
    );
    addIf(normalizedCategory == 'game', ['jeu', 'gaming', 'divertissement']);
    addIf(normalizedCategory == 'news', ['actualité', 'news', 'information']);

    return tags.toList(growable: false);
  }
}
