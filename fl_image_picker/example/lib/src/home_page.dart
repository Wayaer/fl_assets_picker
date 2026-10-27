import 'package:example/src/media_builder.dart';
import 'package:example/src/support.dart';
import 'package:fl_image_picker/fl_image_picker.dart';
import 'package:flutter/material.dart';

/// 示例主页面：单选、多选、预览与清空
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ImagePickerController singleController = _DemoImagePickerController();

  late final ImagePickerController multipleController = _DemoImagePickerController(
    options: const FlImagePickerOptions(limit: 9),
    entities: <FlXFile>[
      ...MultipleImagePicker.convertUrls(sampleImageUrls.join(','), splitPattern: ','),
      ...MultipleImagePicker.convertUrls(sampleVideoUrl, assetType: AssetType.video),
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
      appBar: AppBar(title: const Text('FlImagePicker')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('SingleImagePicker', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SingleImagePicker(controller: singleController, width: 88, height: 88),
          const SizedBox(height: 24),
          Row(
            children: <Widget>[
              Expanded(child: Text('MultipleImagePicker', style: Theme.of(context).textTheme.titleMedium)),
              ListenableBuilder(
                listenable: multipleController,
                builder: (BuildContext context, Widget? child) => Text('${multipleController.entities.length} 个'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          MultipleImagePicker(
            controller: multipleController,
            builderConfig: const MultipleImagePickerListBuilderConfig(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemConfig: FlImagePickerItemConfig(backgroundColor: scheme.surfaceContainerHighest),
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
                onPressed: () => multipleController.entities = <FlXFile>[],
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

class _DemoImagePickerController extends ImagePickerController {
  _DemoImagePickerController({super.entities, super.options});

  @override
  Widget buildPreview(FlXFile file, bool isThumbnail) => DemoImageBuilder(file, isThumbnail: isThumbnail);

  @override
  Future<bool> requestPermission(PickerAction action) => requestPickerPermission(action);
}
