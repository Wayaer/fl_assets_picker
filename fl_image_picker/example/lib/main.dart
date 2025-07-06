import 'package:device_info_plus/device_info_plus.dart';
import 'package:example/src/previewed.dart';
import 'package:fl_extended/fl_extended.dart';
import 'package:fl_image_picker/fl_image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:permission_handler/permission_handler.dart';

bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;

bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;

bool get isMobile => isAndroid || isIOS;

bool get isWeb => kIsWeb;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  flImagePickerInit();
  runApp(MaterialApp(
      navigatorKey: FlExtended().navigatorKey,
      scaffoldMessengerKey: FlExtended().scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
          appBar: AppBar(title: const Text('Fl Image Picker')),
          body: const _HomePage())));
}

void flImagePickerInit() {
  FlImagePicker.imageBuilder = (entity, bool isThumbnail) =>
      ImageBuilder(entity, isThumbnail: isThumbnail);
  FlImagePicker.checkPermission = (PickerAction action) async {
    if (isWeb || !isMobile) return true;
    if (action == PickerAction.takePicture ||
        action == PickerAction.cameraRecording) {
      final permissionState = await Permission.camera.request();
      return permissionState.isGranted;
    } else if (action == PickerAction.video ||
        action == PickerAction.multiImage ||
        action == PickerAction.image) {
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
    } else if (action == PickerAction.media ||
        action == PickerAction.multiMedia) {
      return true;
    }
    return false;
  };
}

const url =
    'https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fc-ssl.duitang.com%2Fuploads%2Fitem%2F201612%2F31%2F20161231205134_uVTex.thumb.400_0.jpeg&refer=http%3A%2F%2Fc-ssl.duitang.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=auto?sec=1666931842&t=44493a6c92d1ddda89367519c6206491';

/// 自定义 ImagePickerController
class CustomImagePickerController extends ImagePickerController {
  CustomImagePickerController(
      {super.actions,
      super.allowPick = true,
      super.entities,
      super.options = const ImagePickerOptions()});

  @override
  Future<void> pick(PickerAction action, {bool reset = false}) async {
    log('Start Pick');
    super.pick(action, reset: reset);
  }

  @override
  Future<void> pickActions(BuildContext context,
      {bool requestFocus = true, bool reset = false}) async {
    log('Start Pick Actions');
    super.pickActions(context, reset: reset, requestFocus: requestFocus);
  }

  @override
  FlXFileRenovate? get onRenovate => (AssetType type, XFile file) async {
        if (type == AssetType.image) {
          return await compressImage(file);
        }
        return null;
      };

  @override
  Future<void> delete(FlXFile file) async {
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
    if (value == true) return super.delete(file);
  }

  @override
  Future<T?> preview<T>(BuildContext context, {int initialIndex = 0}) async {
    final builder = FlImagePickerPreviewPageView(
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
  CustomImagePickerController singlePickerController =
      CustomImagePickerController();
  CustomImagePickerController multiplePickerController =
      CustomImagePickerController();

  @override
  void initState() {
    super.initState();
    final initialData = SingleImagePicker.convertUrl(url);
    if (initialData != null) {
      singlePickerController.entities = [initialData];
    }
    multiplePickerController.entities = MultipleImagePicker.convertUrls(url);
  }

  @override
  Widget build(BuildContext context) {
    return Universal(
        padding: const EdgeInsets.all(12),
        isScroll: true,
        spacing: 12,
        children: [
          const Text('SingleImagePicker'),
          buildSingleImagePicker(singlePickerController),
          const Text('MultipleImagePicker'),
          buildMultiImagePicker(multiplePickerController),
        ]);
  }

  Widget buildSingleImagePicker(ImagePickerController controller) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      SingleImagePicker(
          controller: controller,
          itemConfig: FlImagePickerItemConfig(
              borderRadius: BorderRadius.circular(10),
              backgroundColor: Colors.amberAccent),
          onChanged: (FlXFile? value) {
            'onChanged ${value?.realValueStr}  renovated Type: ${value?.renovated.runtimeType}'
                .log();
          }),
      SingleImagePicker(
          controller: controller,
          itemConfig: FlImagePickerItemConfig(
              borderRadius: BorderRadius.circular(40),
              backgroundColor: Colors.amberAccent),
          onChanged: (FlXFile? value) {
            'onChanged ${value?.realValueStr}  renovated Type: ${value?.renovated.runtimeType}'
                .log();
          }),
    ]);
  }

  Widget buildMultiImagePicker(ImagePickerController controller) {
    return MultipleImagePicker(
        controller: controller,
        itemConfig: FlImagePickerItemConfig(
            delete:
                const FlImagePickerDeleteIcon(backgroundColor: Colors.blue)),
        onChanged: (List<FlXFile> value) {
          'onChanged ${value.builder((item) => item.realValueStr)}'.log();
        });
  }
}

/// 图片压缩
Future<Uint8List?> compressImage(XFile file) async {
  if (isWeb || (!isWeb && isMobile)) {
    final fileName = file.path.removePrefix(file.path);
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
  }
  return null;
}
