import 'dart:typed_data';

import 'package:flueco/flueco.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/neumorphic_theme.dart';
import 'apps_controller.dart';

class AppsHomePage extends StatefulWidget {
  const AppsHomePage({super.key});

  @override
  State<AppsHomePage> createState() => _AppsHomePageState();
}

class _AppsHomePageState extends State<AppsHomePage> {
  AppsController? controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller ??= FluecoSR.of(context).resolve<AppsController>()..load();
  }

  @override
  Widget build(BuildContext context) {
    final controller = this.controller!;
    return ChangeNotifierProvider<AppsController>.value(
      value: controller,
      child: const _AppsHomeView(),
    );
  }
}

class _AppsHomeView extends StatelessWidget {
  const _AppsHomeView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppsController>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'App Finder',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Recharger',
                    onPressed: controller.isLoading ? null : controller.load,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${controller.allApps.length} apps détectées · recherche par nom, catégorie ou utilité',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 22),
              NeuContainer(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                borderRadius: 22,
                child: TextField(
                  onChanged: controller.updateQuery,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(Icons.search_rounded),
                    hintText: 'Ex: Spot, musique, navigation, banque...',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (controller.isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (controller.results.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('Aucune app trouvée. Essaie un autre mot-clé.'),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: controller.results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final result = controller.results[index];
                      final app = result.app;
                      return NeuContainer(
                        onTap: () => controller.launch(app),
                        child: Row(
                          children: [
                            _AppIcon(icon: app.icon),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(app.name, style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 4),
                                  Text(app.packageName, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      if (app.category != 'undefined') _Chip(app.category),
                                      ...result.reasons.take(2).map(_Chip.new),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.north_east_rounded, size: 18),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.icon});

  final Uint8List? icon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 54,
        height: 54,
        color: const Color(0xFF0A1426),
        child: icon == null ? const Icon(Icons.apps_rounded) : Image.memory(icon!, fit: BoxFit.cover),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x332C7DDA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x224EA1FF)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFFBBD6FF))),
    );
  }
}
