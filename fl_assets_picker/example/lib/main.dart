import 'package:device_info_plus/device_info_plus.dart';
import 'package:example/src/previewed.dart';
import 'package:fl_assets_picker/fl_assets_picker.dart';
import 'package:fl_extended/fl_extended.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:permission_handler/permission_handler.dart';

const url =
    'https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fc-ssl.duitang.com%2Fuploads%2Fitem%2F201612%2F31%2F20161231205134_uVTex.thumb.400_0.jpeg&refer=http%3A%2F%2Fc-ssl.duitang.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=auto?sec=1666931842&t=44493a6c92d1ddda89367519c6206491';

bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;

bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;

bool get isFuchsia => defaultTargetPlatform == TargetPlatform.fuchsia;

bool get isMobile => isAndroid || isIOS;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  flAssetsPickerInit();
  runApp(MaterialApp(
      navigatorKey: FlExtended().navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
          appBar: AppBar(title: const Text('Fl Assets Picker')),
          body: const _HomePage())));
}

void flAssetsPickerInit() {
  FlAssetsPicker.assetBuilder = (entity, bool isThumbnail) =>
      AssetBuilder(entity, isThumbnail: isThumbnail);
  FlAssetsPicker.checkPermission = (PickerAction action) async {
    if (!isMobile) return true;
    if (action == PickerAction.gallery) {
      if (isIOS) {
        return (await Permission.photos.request()).isGranted;
      } else if (isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt < 33) {
          return (await Permission.storage.request()).isGranted;
        }
        return (await Permission.photos.request()).isGranted &&
            (await Permission.videos.request()).isGranted;
      }
      return false;
    } else if (action == PickerAction.camera) {
      final permissionState = await Permission.camera.request();
      return permissionState.isGranted;
    }
    return false;
  };
}

/// 自定义 AssetsPickerController
class CustomAssetsPickerController extends AssetsPickerController {
  CustomAssetsPickerController({
    super.actions,
    super.allowPick = true,
    super.entities,
    super.assetConfig = const AssetPickerConfig(),
    super.cameraConfig = const CameraPickerConfig(),
    super.useRootNavigator = true,
    super.pageRouteBuilderForAssetPicker,
    super.pageRouteBuilderForCameraPicker,
    super.getFileAsync = true,
    super.getThumbnailDataAsync = true,
  });

  @override
  Future<void> pickAssets(BuildContext context, {bool reset = false}) {
    log('Start Pick Assets');
    return super.pickAssets(context, reset: reset);
  }

  @override
  Future<void> pickFromCamera(BuildContext context, {bool reset = false}) {
    log('Start Pick From Camera');
    return super.pickFromCamera(context, reset: reset);
  }

  @override
  Future<void> pickActions(BuildContext context,
      {bool unfocus = true, bool reset = false}) async {
    log('Start Pick Actions');
    super.pickActions(context, reset: reset, unfocus: unfocus);
  }

  @override
  FlAssetEntityRenovate? get onRenovate => (AssetEntity asset) async {
        if (asset.type == AssetType.image) {
          final file = await asset.file;
          if (file != null) return await compressImage(file);
        }
        return null;
      };

  @override
  Future<void> delete(FlAssetEntity asset) async {
    final value = await CupertinoAlertDialog(
        content: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            constraints: const BoxConstraints(maxHeight: 100),
            child: const Text('确定要删除么')),
        actions: [
          Universal(
              height: 45,
              alignment: Alignment.center,
              onTap: () {
                pop(false);
              },
              child: const BText('取消', fontSize: 14, color: Colors.grey)),
          Universal(
              height: 45,
              alignment: Alignment.center,
              onTap: () {
                pop(true);
              },
              child: const BText('确定', fontSize: 14, color: Colors.grey)),
        ]).popupCupertinoModal<bool?>();
    if (value == true) return super.delete(asset);
  }

  @override
  Future<T?> preview<T>(BuildContext context, {int initialIndex = 0}) async {
    final builder = FlAssetsPickerPreviewPageView(
        entities: entities, initialIndex: initialIndex);
    if (context.mounted) return await builder.popupDialog<T>();
    return null;
  }
}

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  CustomAssetsPickerController singlePickerController =
      CustomAssetsPickerController();
  CustomAssetsPickerController multiplePickerController =
      CustomAssetsPickerController();

  @override
  void initState() {
    super.initState();
    final initialData = SingleAssetsPicker.convertUrl(url);
    if (initialData != null) {
      singlePickerController.entities = [initialData];
    }
    multiplePickerController.entities = MultipleAssetsPicker.convertUrls(url);
  }

  @override
  Widget build(BuildContext context) {
    return Universal(
        padding: const EdgeInsets.all(12),
        isScroll: true,
        spacing: 12,
        children: [
          const Text('单资源选择'),
          buildSingleAssetsPicker(singlePickerController),
          const Text('多资源选择 混选'),
          buildMultipleAssetPicker(multiplePickerController),
        ]);
  }

  Widget buildSingleAssetsPicker(AssetsPickerController controller) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      SingleAssetsPicker(
          controller: controller,
          itemConfig: FlAssetsPickerItemConfig(
              borderRadius: BorderRadius.circular(10),
              backgroundColor: Colors.amberAccent),
          onChanged: (FlAssetEntity? value) {
            'onChanged ${value?.realValueStr}  realValue Type: ${value?.realValue?.runtimeType}'
                .log();
          }),
      SingleAssetsPicker(
          controller: controller,
          itemConfig: FlAssetsPickerItemConfig(
              borderRadius: BorderRadius.circular(40),
              backgroundColor: Colors.amberAccent),
          onChanged: (FlAssetEntity? value) {
            'onChanged ${value?.realValueStr}  realValue Type: ${value?.realValue?.runtimeType}'
                .log();
          }),
    ]);
  }

  Widget buildMultipleAssetPicker(AssetsPickerController controller) =>
      MultipleAssetsPicker(
          controller: controller,
          onChanged: (List<FlAssetEntity> value) {
            'onChanged ${value.builder((item) => item.realValueStr)}'.log();
          });
}

/// 图片压缩
Future<Uint8List?> compressImage(File file) async {
  final fileName = file.path.removePrefix(file.parent.path);
  final suffix = fileName.split('.').last.toLowerCase();
  CompressFormat? format;
  if (suffix == 'jpg' || suffix == 'jpeg') {
    format = CompressFormat.jpeg;
  } else if (suffix == 'png') {
    format = CompressFormat.png;
  } else if (suffix == 'webp') {
    format = CompressFormat.webp;
  } else if (suffix == 'heic') {
    format = CompressFormat.heic;
  }
  if (format != null) {
    return await FlutterImageCompress.compressWithFile(file.path,
        format: format, minWidth: 480, minHeight: 480, quality: 80);
  }
  return null;
}
