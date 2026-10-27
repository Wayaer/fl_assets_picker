import 'package:device_info_plus/device_info_plus.dart';
import 'package:fl_image_picker/fl_image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// 示例网络图片
const List<String> sampleImageUrls = <String>[
  'https://picsum.photos/seed/fl_image_picker_1/1200/1200',
  'https://picsum.photos/seed/fl_image_picker_2/1200/1200',
  'https://picsum.photos/seed/fl_image_picker_3/1200/1200',
];

/// 示例网络视频
const String sampleVideoUrl = 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';

bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

bool get isMobile => isAndroid || isIOS;

/// 权限申请：与 ImagePickerController.requestPermission 对接
Future<bool> requestPickerPermission(PickerAction action) async {
  if (!isMobile) return true;
  if (action == PickerAction.takePicture || action == PickerAction.cameraRecording) {
    return (await Permission.camera.request()).isGranted;
  }
  if (action == PickerAction.media || action == PickerAction.multiMedia) return true;
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
