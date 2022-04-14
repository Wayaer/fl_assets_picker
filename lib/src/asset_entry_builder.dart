import 'package:assets_picker/assets_picker.dart';
import 'package:assets_picker/src/extended_image.dart';
import 'package:assets_picker/src/video_player.dart';
import 'package:flutter/material.dart';

class BuildAssetEntry extends StatelessWidget {
  const BuildAssetEntry(this.entry, {Key? key, this.isThumbnail = true})
      : super(key: key);
  final ExtendedAssetModel entry;
  final bool isThumbnail;

  @override
  Widget build(BuildContext context) {
    switch (entry.assetType) {
      case AssetType.other:
        return AssetEntryOtherBuild(entry, isThumbnail: isThumbnail);
      case AssetType.image:
        return AssetEntryImageBuild(entry, isThumbnail: isThumbnail);
      case AssetType.video:
        return AssetEntryVideoBuild(entry, isThumbnail: isThumbnail);
      case AssetType.audio:
        return AssetEntryOtherBuild(entry, isThumbnail: isThumbnail);
    }
  }
}

class AssetEntryVideoBuild extends StatelessWidget {
  const AssetEntryVideoBuild(this.asset, {Key? key, this.isThumbnail = false})
      : super(key: key);
  final ExtendedAssetModel asset;
  final bool isThumbnail;

  @override
  Widget build(BuildContext context) {
    Widget? current;
    ImageProvider? imageProvider;
    if (asset.thumbnail != null) {
      imageProvider = PickerExtendedImage.getImageProvider(asset.thumbnail!);
    }
    if (asset.videoCoverPath != null) {
      imageProvider = ExtendedFileImageProvider(asset.videoCoverPath!);
    }
    BoxFit fit = BoxFit.cover;
    if (!isThumbnail) fit = BoxFit.contain;
    if (isThumbnail && imageProvider != null) {
      current = PickerExtendedImage(imageProvider, fit: fit);
    } else {
      current = PickerVideoPlayer(
          file: asset.file, path: asset.path, url: asset.url, cover: current);
    }
    return current;
  }
}

class AssetEntryImageBuild extends StatelessWidget {
  const AssetEntryImageBuild(this.asset, {Key? key, this.isThumbnail = false})
      : super(key: key);
  final ExtendedAssetModel asset;
  final bool isThumbnail;

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (asset.thumbnail != null) {
      imageProvider = PickerExtendedImage.getImageProvider(asset.thumbnail!);
    }
    BoxFit fit = BoxFit.cover;
    if (!isThumbnail) fit = BoxFit.contain;

    return PickerExtendedImage(
        isThumbnail && imageProvider != null
            ? imageProvider
            : PickerExtendedImage.getImageProvider(asset),
        fit: fit);
  }
}

class AssetEntryOtherBuild extends StatelessWidget {
  const AssetEntryOtherBuild(this.asset, {Key? key, this.isThumbnail = false})
      : super(key: key);
  final ExtendedAssetModel asset;
  final bool isThumbnail;

  @override
  Widget build(BuildContext context) {
    ImageProvider? thumbnailProvider;
    if (asset.thumbnail != null) {
      thumbnailProvider =
          PickerExtendedImage.getImageProvider(asset.thumbnail!);
    }
    BoxFit fit = BoxFit.cover;
    if (!isThumbnail) fit = BoxFit.contain;

    if (isThumbnail && thumbnailProvider != null) {
      return PickerExtendedImage(thumbnailProvider, fit: fit);
    }

    return const Center(child: Text('无法预览'));
  }
}
