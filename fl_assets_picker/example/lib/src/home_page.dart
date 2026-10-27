import 'package:example/src/media_builder.dart';
import 'package:example/src/support.dart';
import 'package:fl_assets_picker/fl_assets_picker.dart';
import 'package:flutter/material.dart';

/// 示例主页面：单选、多选、预览与清空
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final AssetsPickerController singleController = _DemoAssetsPickerController(
    assetConfig: const AssetPickerConfig(maxAssets: 1),
    // 选中后取回文件，才能用于回显与预览
    getFileAsync: true,
  );

  late final AssetsPickerController multipleController = _DemoAssetsPickerController(
    assetConfig: const AssetPickerConfig(maxAssets: 9),
    cameraConfig: const CameraPickerConfig(enableRecording: true),
    getFileAsync: true,
    entities: <FlAssetEntity>[
      ...MultipleAssetsPicker.convertUrls(sampleImageUrls.join(','), splitPattern: ','),
      ...MultipleAssetsPicker.convertUrls(sampleVideoUrl, assetType: AssetType.video),
    ],
  );

  @override
  void dispose() {
    singleController.dispose();
    multipleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('FlAssetsPicker')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('SingleAssetsPicker', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SingleAssetsPicker(controller: singleController, width: 88, height: 88),
          const SizedBox(height: 24),
          Row(
            children: <Widget>[
              Expanded(child: Text('MultipleAssetsPicker', style: Theme.of(context).textTheme.titleMedium)),
              ListenableBuilder(
                listenable: multipleController,
                builder: (BuildContext context, Widget? child) => Text('${multipleController.entities.length} 个'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          MultipleAssetsPicker(
            controller: multipleController,
            builderConfig: const MultipleAssetsPickerListBuilderConfig(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemConfig: FlAssetsPickerItemConfig(backgroundColor: scheme.surfaceContainerHighest),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.icon(
                onPressed: () => multipleController.pickActions(context),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('选择'),
              ),
              OutlinedButton.icon(
                onPressed: () => multipleController.preview(context),
                icon: const Icon(Icons.fullscreen),
                label: const Text('预览'),
              ),
              TextButton.icon(
                onPressed: () => multipleController.entities = <FlAssetEntity>[],
                icon: const Icon(Icons.clear_all),
                label: const Text('清空'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DemoAssetsPickerController extends AssetsPickerController {
  _DemoAssetsPickerController({super.entities, super.assetConfig, super.cameraConfig, super.getFileAsync});

  @override
  Widget buildPreview(FlAssetEntity asset, bool isThumbnail) => DemoAssetBuilder(asset, isThumbnail: isThumbnail);

  @override
  Future<bool> requestPermission(PickerAction action) => requestAssetsPermission(action);
}
