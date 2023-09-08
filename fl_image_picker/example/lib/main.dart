import 'dart:io';

import 'package:example/previewed.dart';
import 'package:extended_image/extended_image.dart';
import 'package:fl_image_picker/fl_image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_waya/flutter_waya.dart';
import 'package:permission_handler/permission_handler.dart';

bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;

bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;

bool get isMobile => isAndroid || isIOS;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  flImagePickerInit();
  runApp(MaterialApp(
      navigatorKey: GlobalWayUI().navigatorKey,
      scaffoldMessengerKey: GlobalWayUI().scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
          appBar: AppBar(title: const Text('Fl Image Picker')),
          body: const _HomePage())));
}

void flImagePickerInit() {
  FlImagePicker.assetBuilder = (ExtendedXFile entity, bool isThumbnail) =>
      AssetBuilder(entity, isThumbnail: isThumbnail);
  FlImagePicker.checkPermission = (PickerFromType fromType) async {
    if (!isMobile) return true;
    if (fromType == PickerFromType.image || fromType == PickerFromType.video) {
      if (isIOS) {
        return (await Permission.photos.request()).isGranted;
      } else if (isAndroid) {
        bool resultStorage = (await Permission.storage.request()).isGranted;
        return resultStorage;
      }
      return false;
    } else if (fromType == PickerFromType.takePictures ||
        fromType == PickerFromType.recording) {
      final permissionState = await Permission.camera.request();
      return permissionState.isGranted;
    }
    return false;
  };
  FlImagePicker.previewModalPopup = (_, Widget widget) => widget.popupDialog();
  FlImagePicker.previewBuilder = (context, entity, allEntity) {
    return FlPreviewGesturePageView(
        pageView: ExtendedImageGesturePageView.builder(
            itemCount: allEntity.length,
            controller:
                ExtendedPageController(initialPage: allEntity.indexOf(entity)),
            itemBuilder: (_, int index) =>
                FlImagePicker.assetBuilder(allEntity[index], false)));
  };
  FlImagePicker.errorCallback = (String value) {
    showToast(value);
  };
}

const url =
    'https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fc-ssl.duitang.com%2Fuploads%2Fitem%2F201612%2F31%2F20161231205134_uVTex.thumb.400_0.jpeg&refer=http%3A%2F%2Fc-ssl.duitang.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=auto?sec=1666931842&t=44493a6c92d1ddda89367519c6206491';

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Universal(
        padding: const EdgeInsets.all(12),
        isScroll: true,
        children: [
          const Text('单资源选择 仅图片').marginAll(12),
          buildSingleImagePicker(AssetType.image),
          const Text('单资源选择 仅视频').marginAll(12),
          buildSingleImagePicker(AssetType.video),
          const Text('多资源选择 仅图片').marginAll(12),
          buildMultiImagePicker(AssetType.image),
          const Text('多资源选择 仅视频').marginAll(12),
          buildMultiImagePicker(AssetType.video),
        ]);
  }

  Widget buildSingleImagePicker(AssetType assetType) {
    List<PickerFromTypeItem> fromTypes = [
      const PickerFromTypeItem(
          fromType: PickerFromType.cancel, text: Text('取消')),
    ];

    switch (assetType) {
      case AssetType.other:
        break;
      case AssetType.image:
        fromTypes.insertAll(0, const [
          PickerFromTypeItem(
              fromType: PickerFromType.image, text: Text('图库选择')),
          PickerFromTypeItem(
              fromType: PickerFromType.takePictures, text: Text('相机拍照')),
        ]);
        break;
      case AssetType.video:
        fromTypes.insertAll(0, const [
          PickerFromTypeItem(
              fromType: PickerFromType.video, text: Text('图库选择')),
          PickerFromTypeItem(
              fromType: PickerFromType.recording, text: Text('相机拍摄')),
        ]);
        break;
    }

    return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      SingleImagePicker(
          fromTypes: fromTypes,
          renovate: (AssetType assetType, XFile entity) async {
            if (assetType == AssetType.image) {
              return await compressImage(File(entity.path));
            }
            return null;
          },
          initialData: SingleImagePicker.convertUrl(url),
          itemConfig: ImagePickerItemConfig(
              borderRadius: BorderRadius.circular(10),
              color: Colors.amberAccent),
          onChanged: (ExtendedXFile value) {
            log('onChanged ${value.realValueStr}  renovated Type: ${value.renovated.runtimeType}');
          }),
      SingleImagePicker(
          renovate: (AssetType assetType, XFile entity) async {
            if (assetType == AssetType.image) {
              return await compressImage(File(entity.path));
            }
            return null;
          },
          fromTypes: fromTypes,
          initialData: SingleImagePicker.convertUrl(url),
          itemConfig: ImagePickerItemConfig(
              borderRadius: BorderRadius.circular(40),
              color: Colors.amberAccent),
          onChanged: (ExtendedXFile value) {
            log('onChanged ${value.realValueStr}');
          }),
    ]);
  }

  Widget buildMultiImagePicker(AssetType assetType) {
    List<PickerFromTypeItem> fromTypes = [
      const PickerFromTypeItem(
          fromType: PickerFromType.cancel, text: Text('取消')),
    ];

    switch (assetType) {
      case AssetType.other:
        break;
      case AssetType.image:
        fromTypes.insertAll(0, const [
          PickerFromTypeItem(
              fromType: PickerFromType.image, text: Text('图库选择')),
          PickerFromTypeItem(
              fromType: PickerFromType.takePictures, text: Text('相机拍照')),
        ]);
        break;
      case AssetType.video:
        fromTypes.insertAll(0, const [
          PickerFromTypeItem(
              fromType: PickerFromType.video, text: Text('图库选择')),
          PickerFromTypeItem(
              fromType: PickerFromType.recording, text: Text('相机拍摄')),
        ]);
        break;
    }
    return MultipleImagePicker(
        initialData: MultipleImagePicker.convertUrls(url),
        fromTypes: fromTypes,
        renovate: (AssetType assetType, XFile entity) async {
          if (assetType == AssetType.image) {
            return await compressImage(File(entity.path));
          }
          return null;
        },
        itemConfig: ImagePickerItemConfig(
            delete: const DefaultDeleteIcon(backgroundColor: Colors.blue),
            deletionConfirmation: (_) async {
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
                        child: const BText('取消',
                            fontSize: 14, color: Colors.grey)),
                    Universal(
                        height: 45,
                        alignment: Alignment.center,
                        onTap: () {
                          pop(true);
                        },
                        child: const BText('确定',
                            fontSize: 14, color: Colors.grey)),
                  ]).popupCupertinoModal<bool?>();
              return value ?? false;
            }),
        onChanged: (List<ExtendedXFile> value) {
          log('onChanged ${value.builder((item) => item.realValueStr)}');
        });
  }
}

/// 图片压缩
Future<Uint8List?> compressImage(File file) async {
  if (kIsWeb ||
      (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS))) {
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
  }
  return null;
}
