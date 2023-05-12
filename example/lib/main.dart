import 'dart:io';

import 'package:fl_assets_picker/fl_assets_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_curiosity/flutter_curiosity.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_waya/flutter_waya.dart';
import 'package:permission_handler/permission_handler.dart';

String? currentCacheDir;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appPath = await Curiosity().native.appPath;
  if (appPath != null) {
    if (isAndroid) {
      currentCacheDir = '${appPath.externalCacheDir!}/';
    } else if (isIOS) {
      currentCacheDir = appPath.temporaryDirectory;
    } else if (isMacOS) {
      currentCacheDir = appPath.temporaryDirectory;
    }
  }
  runApp(const ExtendedWidgetsApp(home: _HomePage()));
}

const url =
    'https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fc-ssl.duitang.com%2Fuploads%2Fitem%2F201612%2F31%2F20161231205134_uVTex.thumb.400_0.jpeg&refer=http%3A%2F%2Fc-ssl.duitang.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=auto?sec=1666931842&t=44493a6c92d1ddda89367519c6206491';

class _HomePage extends StatelessWidget {
  const _HomePage();

  Future<bool> checkPermission(PickerFromType fromType) async {
    if (!isMobile) return true;
    switch (fromType) {
      case PickerFromType.assets:
        final permission = isIOS ? Permission.photos : Permission.storage;
        final permissionState = await permission.request();
        return permissionState.isGranted;
      case PickerFromType.camera:
        final permissionState = await Permission.camera.request();
        return permissionState.isGranted;
      case PickerFromType.cancel:
        break;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return ExtendedScaffold(
        appBar: AppBar(title: const Text('Assets Picker')),
        padding: const EdgeInsets.all(12),
        isScroll: true,
        children: [
          const Text('单资源选择 混选').marginAll(12),
          buildSingleAssetPicker(RequestType.common),
          const Text('单资源选择 仅图片').marginAll(12),
          buildSingleAssetPicker(RequestType.image),
          const Text('单资源选择 仅视频').marginAll(12),
          buildSingleAssetPicker(RequestType.video),
          const Text('多资源选择 混选').marginAll(12),
          buildMultiAssetPicker(RequestType.common),
          const Text('多资源选择 仅图片').marginAll(12),
          buildMultiAssetPicker(RequestType.image),
          const Text('多资源选择 仅视频').marginAll(12),
          buildMultiAssetPicker(RequestType.video),
        ]);
  }

  Widget buildSingleAssetPicker(RequestType requestType) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        SingleAssetPicker(
            fromRequestTypes: [
              PickerFromTypeConfig(
                  fromType: PickerFromType.assets,
                  requestType: requestType,
                  text: const Text('图库选择')),
              PickerFromTypeConfig(
                  fromType: PickerFromType.camera,
                  requestType: requestType,
                  text: const Text('相机拍摄')),
              const PickerFromTypeConfig(
                  fromType: PickerFromType.cancel, text: Text('取消')),
            ],
            errorCallback: (String value) {
              showToast(value);
            },
            renovate: (AssetEntity entity) async {
              final file = await entity.file;
              if (file != null) return await compressImage(file);
              return null;
            },
            checkPermission: checkPermission,
            initialData: SingleAssetPicker.convertUrl(url),
            config: PickerAssetEntryBuilderConfig(
                borderRadius: BorderRadius.circular(10),
                color: Colors.amberAccent),
            onChanged: (ExtendedAssetEntity value) {
              log('onChanged ${value.realValueStr}  renovated Type: ${value.renovated.runtimeType}');
            }),
        SingleAssetPicker(
            errorCallback: (String value) {
              showToast(value);
            },
            fromRequestTypes: [
              PickerFromTypeConfig(
                  fromType: PickerFromType.assets,
                  text: const Text('图库选择'),
                  requestType: requestType),
              PickerFromTypeConfig(
                  fromType: PickerFromType.camera,
                  text: const Text('相机拍摄'),
                  requestType: requestType),
              const PickerFromTypeConfig(
                  fromType: PickerFromType.cancel, text: Text('取消')),
            ],
            checkPermission: checkPermission,
            initialData: SingleAssetPicker.convertUrl(url),
            config: PickerAssetEntryBuilderConfig(
                borderRadius: BorderRadius.circular(40),
                color: Colors.amberAccent),
            onChanged: (ExtendedAssetEntity value) {
              log('onChanged ${value.realValueStr}');
            }),
      ]);

  Widget buildMultiAssetPicker(RequestType requestType) => MultiAssetPicker(
      initialData: MultiAssetPicker.convertUrls(url),
      fromRequestTypes: [
        PickerFromTypeConfig(
            fromType: PickerFromType.assets,
            text: const Text('图库选择'),
            requestType: requestType),
        PickerFromTypeConfig(
            fromType: PickerFromType.camera,
            text: const Text('相机拍摄'),
            requestType: requestType),
        const PickerFromTypeConfig(
            fromType: PickerFromType.cancel, text: Text('取消')),
      ],
      previewSheetRouteBuilder: (_, Widget previewAssets) =>
          previewAssets.popupDialog(),
      errorCallback: (String value) {
        showToast(value);
      },
      checkPermission: checkPermission,
      entryConfig: PickerAssetEntryBuilderConfig(
          borderRadius: BorderRadius.circular(10), color: Colors.amberAccent),
      onChanged: (List<ExtendedAssetEntity> value) {
        log('onChanged ${value.builder((item) => item.realValueStr)}');
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
