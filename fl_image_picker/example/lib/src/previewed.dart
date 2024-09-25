import 'package:example/src/extended_image.dart';
import 'package:example/src/fl_video.dart';
import 'package:extended_image/extended_image.dart';
import 'package:fl_image_picker/fl_image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ImageBuilder extends StatelessWidget {
  const ImageBuilder(this.xFile, {super.key, this.isThumbnail = true});

  final ExtendedXFile xFile;

  /// 是否优先预览缩略图
  final bool isThumbnail;

  @override
  Widget build(BuildContext context) {
    const unsupported = Center(child: Text('Preview not supported'));
    switch (xFile.type) {
      case ImageType.other:
        break;
      case ImageType.image:
        final imageProvider =
            ExtendedImageWithImagePicker.imageEntityToImageProvider(xFile);
        if (imageProvider != null) {
          return ExtendedImageWithImagePicker(imageProvider,
              mode: isThumbnail
                  ? ExtendedImageMode.none
                  : ExtendedImageMode.gesture,
              initGestureConfigHandler: !isThumbnail
                  ? null
                  : (ExtendedImageState state) => GestureConfig(
                      inPageView: true,
                      initialScale: 1.0,
                      maxScale: 5.0,
                      animationMaxScale: 6.0,
                      initialAlignment: InitialAlignment.center),
              fit: isThumbnail ? BoxFit.cover : BoxFit.contain);
        }
        break;
      case ImageType.video:
        if (isThumbnail) {
          return Container(
              color: Colors.black26,
              width: double.infinity,
              height: double.infinity);
        } else if (supportable) {
          final controller =
              FlVideoPlayerWithImagePicker.buildVideoPlayerController(
                  xFile.realValue);
          if (controller != null) {
            return FlVideoPlayerWithImagePicker(controller: controller);
          }
        }
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
