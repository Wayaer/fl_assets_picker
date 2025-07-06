import 'package:example/main.dart';
import 'package:example/src/fl_video.dart';
import 'package:fl_image_picker/fl_image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ImageBuilder extends StatelessWidget {
  const ImageBuilder(this.xFile, {super.key, this.isThumbnail = true});

  final FlXFile xFile;

  /// 是否优先预览缩略图
  final bool isThumbnail;

  @override
  Widget build(BuildContext context) {
    const unsupported = Center(child: Text('Preview not supported'));
    switch (xFile.type) {
      case AssetType.image:
        final imageProvider = xFile.toImageProvider();
        if (imageProvider != null) {
          return Image(
              image: imageProvider,
              fit: isThumbnail ? BoxFit.cover : BoxFit.contain);
        }
        break;
      case AssetType.video:
        if (isThumbnail) {
          return Container(
              color: Colors.black26,
              width: double.infinity,
              height: double.infinity);
        } else if (supportable) {
          var real = xFile.realValue;
          if (real is String && !isWeb) {
            real = File(real);
          }
          final controller =
              FlVideoPlayerWithImagePicker.buildVideoPlayerController(real);
          if (controller != null) {
            return FlVideoPlayerWithImagePicker(controller: controller);
          }
        }
        break;
      case AssetType.media:
        break;
    }
    return unsupported;
  }

  bool get supportable =>
      kIsWeb ||
      (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS));
}
