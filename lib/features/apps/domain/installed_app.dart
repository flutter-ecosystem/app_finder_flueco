import 'dart:typed_data';

class InstalledApp {
  const InstalledApp({
    required this.name,
    required this.packageName,
    required this.category,
    required this.utilityTags,
    this.icon,
    this.isSystemApp = false,
    this.installedAt,
    this.updatedAt,
  });

  final String name;
  final String packageName;
  final String category;
  final List<String> utilityTags;
  final Uint8List? icon;
  final bool isSystemApp;
  final DateTime? installedAt;
  final DateTime? updatedAt;

  String get searchableText => [
        name,
        packageName,
        category,
        ...utilityTags,
      ].join(' ');
}
