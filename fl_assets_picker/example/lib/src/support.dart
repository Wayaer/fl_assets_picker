import 'package:device_info_plus/device_info_plus.dart';
import 'package:fl_assets_picker/fl_assets_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// 示例网络图片
const List<String> sampleImageUrls = <String>[
  'https://picsum.photos/seed/fl_assets_picker_1/1200/1200',
  'https://picsum.photos/seed/fl_assets_picker_2/1200/1200',
  'https://picsum.photos/seed/fl_assets_picker_3/1200/1200',
];

/// 示例网络视频
const String sampleVideoUrl = 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';

bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

bool get isMacOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

/// 图库选择：Android、iOS、macOS
bool get supportGallery => isAndroid || isIOS || isMacOS;

/// 相机拍摄：Android、iOS
bool get supportCamera => isAndroid || isIOS;

/// 权限申请：与 AssetsPickerController.requestPermission 对接
Future<bool> requestAssetsPermission(PickerAction action) async {
  if (action == PickerAction.camera) {
    if (!supportCamera) return false;
    return (await Permission.camera.request()).isGranted;
  }
  if (action == PickerAction.gallery) {
    if (!supportGallery) return false;
    if (isIOS) return (await Permission.photos.request()).isGranted;
    if (isAndroid) {
      final AndroidDeviceInfo info = await DeviceInfoPlugin().androidInfo;
      if (info.version.sdkInt < 33) return (await Permission.storage.request()).isGranted;
      final photos = await Permission.photos.request();
      final videos = await Permission.videos.request();
      return photos.isGranted && videos.isGranted;
    }
    return true;
  }
  return false;
}
