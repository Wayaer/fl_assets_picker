import 'package:assets_picker/assets_picker.dart';
import 'package:assets_picker/src/extended_image.dart';
import 'package:flutter/material.dart';

class AssetEntryVideoPlayerBuild extends StatelessWidget {
  const AssetEntryVideoPlayerBuild(this.asset,
      {Key? key, this.isThumbnail = false})
      : super(key: key);
  final AssetOriginModel asset;
  final bool isThumbnail;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class AssetEntryImageBuild extends StatelessWidget {
  const AssetEntryImageBuild(this.asset, {Key? key, this.isThumbnail = false})
      : super(key: key);
  final AssetOriginModel asset;
  final bool isThumbnail;

  @override
  Widget build(BuildContext context) {
    ImageProvider? thumbnailProvider;
    if (asset.thumbnail != null) {
      thumbnailProvider =
          PickerExtendedImage.getImageProvider(asset.thumbnail!);
    }
    return PickerExtendedImage(
        isThumbnail && thumbnailProvider != null
            ? thumbnailProvider
            : PickerExtendedImage.getImageProvider(asset),
        fit: BoxFit.cover);
  }
}

class AssetEntryOtherBuild extends StatelessWidget {
  const AssetEntryOtherBuild(this.asset, {Key? key, this.isThumbnail = false})
      : super(key: key);
  final AssetOriginModel asset;
  final bool isThumbnail;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
