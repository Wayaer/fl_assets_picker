import 'package:fl_assets_picker/fl_assets_picker.dart';
import 'package:fl_assets_picker/src/extended_image.dart';
import 'package:flutter/material.dart';

class AssetsPickerEntryBuild extends StatelessWidget {
  const AssetsPickerEntryBuild(this.entry,
      {super.key, this.isThumbnail = true});

  final ExtendedAssetEntity entry;

  /// 是否优先预览缩略图
  final bool isThumbnail;

  @override
  Widget build(BuildContext context) {
    switch (entry.type) {
      case AssetType.other:
        return _AssetEntryOtherBuild(entry, isThumbnail: isThumbnail);
      case AssetType.image:
        return _AssetEntryImageBuild(entry, isThumbnail: isThumbnail);
      case AssetType.video:
        return _AssetEntryVideoBuild(entry, isThumbnail: isThumbnail);
      case AssetType.audio:
        return _AssetEntryOtherBuild(entry, isThumbnail: isThumbnail);
    }
  }
}

class _AssetEntryVideoBuild extends StatelessWidget {
  const _AssetEntryVideoBuild(this.asset, {this.isThumbnail = false});

  final ExtendedAssetEntity asset;
  final bool isThumbnail;

  @override
  Widget build(BuildContext context) {
    if (asset.type == AssetType.video) {
      Widget? current;
      ImageProvider? imageProvider;
      if (asset.thumbnailDataAsync != null) {
        imageProvider = PickerExtendedImage.assetEntityToImageProvider(asset);
      } else if (asset.videoCoverFile != null) {
        imageProvider = ExtendedFileImageProvider(asset.videoCoverFile!);
      }
      BoxFit fit = BoxFit.cover;
      if (!isThumbnail) fit = BoxFit.contain;
      if (isThumbnail && imageProvider != null) {
        current = PickerExtendedImage(imageProvider, fit: fit);
      } else {
        current = FlVideoPlayerWithAssetsPicker(
            file: asset.fileAsync,
            path: asset.previewPath,
            url: asset.previewUrl,
            cover: current);
      }
      return current;
    }
    return const _PreviewSupported();
  }
}

class _AssetEntryImageBuild extends StatelessWidget {
  const _AssetEntryImageBuild(this.asset, {this.isThumbnail = false});

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
    return const _PreviewSupported();
  }
}

class _AssetEntryOtherBuild extends StatelessWidget {
  const _AssetEntryOtherBuild(this.asset, {this.isThumbnail = false});

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
    return const _PreviewSupported();
  }
}

class _PreviewSupported extends StatelessWidget {
  const _PreviewSupported();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Preview not supported'));
}
