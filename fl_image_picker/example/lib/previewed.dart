import 'package:example/extended_image.dart';
import 'package:example/fl_video.dart';
import 'package:extended_image/extended_image.dart';
import 'package:fl_image_picker/fl_image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FlPreviewAssets extends StatelessWidget {
  const FlPreviewAssets({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
  });

  final int? itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ExtendedPageController? controller;

  @override
  Widget build(BuildContext context) {
    return FlPreviewGesturePageView(
        pageView: ExtendedImageGesturePageView.builder(
            controller: controller,
            itemCount: itemCount,
            itemBuilder: itemBuilder));
  }
}

class AssetBuilder extends StatelessWidget {
  const AssetBuilder(this.xFile, {super.key, this.isThumbnail = true});

  final ExtendedXFile xFile;

  /// 是否优先预览缩略图
  final bool isThumbnail;

  @override
  Widget build(BuildContext context) {
    const unsupported = Center(child: Text('Preview not supported'));
    switch (xFile.assetType) {
      case AssetType.other:
        break;
      case AssetType.image:
        final imageProvider =
            ExtendedImageWithImagePicker.assetEntityToImageProvider(xFile);
        if (imageProvider != null) {
          return ExtendedImageWithImagePicker(imageProvider,
              mode: isThumbnail
                  ? ExtendedImageMode.gesture
                  : ExtendedImageMode.none,
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
      case AssetType.video:
        if (isThumbnail) {
          return Container(
              color: Colors.black26,
              width: double.infinity,
              height: double.infinity);
        } else if (supportable) {
          final controller =
              FlVideoPlayerWithImagePicker.buildVideoPlayerController(
                  xFile.previewed ?? xFile.fileAsync);
          if (controller != null) {
            return FlVideoPlayerWithImagePicker(controller: controller);
          }
        }
    }
    return unsupported;
  }

  bool get supportable =>
      kIsWeb ||
      (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS));
}
