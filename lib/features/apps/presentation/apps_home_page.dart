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
      appBar: AppBar(
        title: const Text('App Finder'),
        actions: [
          PopupMenuButton<AppSortOption>(
            tooltip: 'Trier les apps',
            icon: const Icon(Icons.sort_rounded),
            onSelected: controller.updateSort,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: AppSortOption.nameAsc,
                child: Text('Nom A→Z'),
              ),
              PopupMenuItem(
                value: AppSortOption.nameDesc,
                child: Text('Nom Z→A'),
              ),
              PopupMenuItem(
                value: AppSortOption.dateAsc,
                child: Text('Date ↑'),
              ),
              PopupMenuItem(
                value: AppSortOption.dateDesc,
                child: Text('Date ↓'),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Recharger',
            onPressed: controller.isLoading ? null : controller.load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(
                '${controller.allApps.length} apps détectées · recherche par nom, catégorie ou utilité',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 22),
              NeuContainer(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
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
              const SizedBox(height: 12),
              if (controller.isLoading)
                const Expanded(
                    child: Center(child: CircularProgressIndicator()))
              else if (controller.results.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('Aucune app trouvée. Essaie un autre mot-clé.'),
                  ),
                )
              else
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: controller.results.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      mainAxisExtent: 170,
                    ),
                    itemBuilder: (context, index) {
                      final result = controller.results[index];
                      final app = result.app;
                      return NeuContainer(
                        onTap: () => controller.launch(app),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _AppIcon(icon: app.icon),
                              const SizedBox(height: 10),
                              Flexible(
                                child: Text(
                                  app.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                            ],
                          ),
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
        child: icon == null
            ? const Icon(Icons.apps_rounded)
            : Image.memory(icon!, fit: BoxFit.cover),
      ),
    );
  }
}
