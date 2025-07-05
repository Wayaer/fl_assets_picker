import 'package:example/main.dart';
import 'package:example/src/extended_image.dart';
import 'package:example/src/fl_video.dart';
import 'package:fl_assets_picker/fl_assets_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AssetBuilder extends StatelessWidget {
  const AssetBuilder(this.entity, {super.key, this.isThumbnail = true});

  final ExtendedAssetEntity entity;

  /// 是否优先预览缩略图
  final bool isThumbnail;

  @override
  Widget build(BuildContext context) {
    const unsupported = Center(child: Text('Preview not supported'));
    switch (entity.type) {
      case AssetType.other:
        break;
      case AssetType.image:
        final imageProvider =
            ExtendedImageWithImagePicker.assetEntityToImageProvider(entity);
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
      case AssetType.video:
        if (isThumbnail) {
          return Container(
              color: Colors.black26,
              width: double.infinity,
              height: double.infinity);
        } else if (supportable) {
          final controller =
              FlVideoPlayerWithImagePicker.buildVideoPlayerController(
                  entity.previewed ?? entity.fileAsync);
          if (controller != null) {
            return FlVideoPlayerWithImagePicker(controller: controller);
          }
        }
        break;
      case AssetType.audio:
        break;
    }
    return unsupported;
  }

  bool get supportable =>
      kIsWeb ||
      (!kIsWeb && (isMobile || defaultTargetPlatform == TargetPlatform.macOS));
}
