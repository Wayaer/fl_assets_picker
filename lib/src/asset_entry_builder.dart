import 'package:fl_assets_picker/fl_assets_picker.dart';
import 'package:fl_assets_picker/src/extended_image.dart';
import 'package:flutter/material.dart';

class BuildAssetEntry extends StatelessWidget {
  const BuildAssetEntry(this.entry, {Key? key, this.isThumbnail = true})
      : super(key: key);
  final ExtendedAssetEntity entry;
  final bool isThumbnail;

  @override
  Widget build(BuildContext context) {
    switch (entry.type) {
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
  final ExtendedAssetEntity asset;
  final bool isThumbnail;

  @override
  Widget build(BuildContext context) {
    if (asset.type == AssetType.video) {
      Widget? current;
      ImageProvider? imageProvider;
      if (asset.thumbnailDataAsync != null) {
        imageProvider = PickerExtendedImage.assetEntityToImageProvider(asset);
      }
      if (asset.videoCoverPath != null) {
        imageProvider = ExtendedFileImageProvider(asset.videoCoverPath!);
      }
      BoxFit fit = BoxFit.cover;
      if (!isThumbnail) fit = BoxFit.contain;
      if (isThumbnail && imageProvider != null) {
        current = PickerExtendedImage(imageProvider, fit: fit);
      } else {
        current = PickerFlVideoPlayer(
            file: asset.fileAsync,
            path: asset.path,
            url: asset.url,
            cover: current);
      }
      return current;
    }
    return const PreviewSupported();
  }
}

class AssetEntryImageBuild extends StatelessWidget {
  const AssetEntryImageBuild(this.asset, {Key? key, this.isThumbnail = false})
      : super(key: key);
  final ExtendedAssetEntity asset;
  final bool isThumbnail;

  @override
  Widget build(BuildContext context) {
    if (asset.type == AssetType.image) {
      ImageProvider? imageProvider;
      if (asset.thumbnailDataAsync != null) {
        imageProvider = PickerExtendedImage.assetEntityToImageProvider(asset);
      }
      BoxFit fit = BoxFit.cover;
      if (!isThumbnail) fit = BoxFit.contain;
      imageProvider = isThumbnail && imageProvider != null
          ? imageProvider
          : PickerExtendedImage.assetEntityToImageProvider(asset);
      if (imageProvider == null) return const SizedBox();
      return PickerExtendedImage(imageProvider, fit: fit);
    }
    return const PreviewSupported();
  }
}

class AssetEntryOtherBuild extends StatelessWidget {
  const AssetEntryOtherBuild(this.asset, {Key? key, this.isThumbnail = false})
      : super(key: key);
  final ExtendedAssetEntity asset;
  final bool isThumbnail;

  @override
  Widget build(BuildContext context) {
    if (asset.type == AssetType.other || asset.type == AssetType.audio) {
      ImageProvider? thumbnailProvider;
      if (asset.thumbnailDataAsync != null) {
        thumbnailProvider =
            PickerExtendedImage.assetEntityToImageProvider(asset);
      }
      BoxFit fit = BoxFit.cover;
      if (!isThumbnail) fit = BoxFit.contain;

      if (isThumbnail && thumbnailProvider != null) {
        return PickerExtendedImage(thumbnailProvider, fit: fit);
      }
    }
    return const PreviewSupported();
  }
}

class PreviewSupported extends StatelessWidget {
  const PreviewSupported({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Preview not supported'));
}
