import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
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
        title: Text('app_title'.tr()),
        actions: [
          PopupMenuButton<AppSortOption>(
            tooltip: 'sort_apps'.tr(),
            icon: const Icon(Icons.sort_rounded),
            onSelected: controller.updateSort,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: AppSortOption.nameAsc,
                child: Text('sort_name_asc'.tr()),
              ),
              PopupMenuItem(
                value: AppSortOption.nameDesc,
                child: Text('sort_name_desc'.tr()),
              ),
              PopupMenuItem(
                value: AppSortOption.dateAsc,
                child: Text('sort_date_asc'.tr()),
              ),
              PopupMenuItem(
                value: AppSortOption.dateDesc,
                child: Text('sort_date_desc'.tr()),
              ),
            ],
          ),
          IconButton(
            tooltip: 'refresh'.tr(),
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
                '${'apps_detected'.tr(namedArgs: {
                      'count': controller.allApps.length.toString()
                    })} · ${'search_description'.tr()}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 22),
              NeuContainer(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                borderRadius: 22,
                child: TextField(
                  onChanged: controller.updateQuery,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(Icons.search_rounded),
                    hintText: 'search_hint'.tr(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 12),
              if (controller.isLoading)
                const Expanded(
                    child: Center(child: CircularProgressIndicator()))
              else if (controller.results.isEmpty)
                Expanded(
                  child: Center(
                    child: Text('empty_state'.tr()),
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
