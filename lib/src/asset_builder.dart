import 'package:fl_assets_picker/fl_assets_picker.dart';
import 'package:flutter/material.dart';

class FlPreviewAssets extends StatelessWidget {
  const FlPreviewAssets(
      {super.key,
      required this.itemCount,
      required this.itemBuilder,
      this.controller,
      this.close,
      this.overlay,
      this.pageSnapping = true,
      this.reverse = false,
      this.scrollDirection = Axis.horizontal,
      this.canScrollPage,
      this.physics,
      this.onPageChanged});

  final int? itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ExtendedPageController? controller;
  final bool pageSnapping;
  final bool reverse;
  final Axis scrollDirection;
  final CanScrollPage? canScrollPage;
  final ScrollPhysics? physics;
  final ValueChanged<int>? onPageChanged;

  /// 关闭按钮
  final Widget? close;

  /// 在图片的上层
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.black.withOpacity(0.9),
        child: Stack(children: [
          SizedBox.expand(
              child: ExtendedImageGesturePageView.builder(
                  controller: controller,
                  itemCount: itemCount,
                  itemBuilder: itemBuilder,
                  physics: physics,
                  scrollDirection: scrollDirection,
                  reverse: reverse,
                  pageSnapping: pageSnapping,
                  onPageChanged: onPageChanged,
                  canScrollPage: canScrollPage)),
          close ??
              Positioned(
                  right: 6,
                  top: MediaQuery.of(context).viewPadding.top,
                  child: const CloseButton(color: Colors.white)),
          if (overlay != null) overlay!,
        ]));
  }
}

class AssetPickIcon extends StatelessWidget {
  const AssetPickIcon(
      {super.key,
      this.borderRadius = const BorderRadius.all(Radius.circular(8)),
      this.borderColor = const Color(0x804D4D4D),
      this.iconColor = const Color(0x804D4D4D),
      this.backgroundColor,
      this.icon,
      this.size = 30});

  final BorderRadiusGeometry? borderRadius;
  final Color? borderColor;
  final Color iconColor;
  final Color? backgroundColor;
  final double size;
  final Widget? icon;

  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          border: borderColor == null ? null : Border.all(color: borderColor!),
          borderRadius: borderRadius),
      child: icon ?? Icon(Icons.add, size: size, color: iconColor));
}

class AssetDeleteIcon extends StatelessWidget {
  const AssetDeleteIcon(
      {super.key,
      this.icon,
      this.iconColor = Colors.white,
      this.backgroundColor = Colors.redAccent,
      this.size = 12});

  final Widget? icon;
  final Color iconColor;
  final Color backgroundColor;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      padding: const EdgeInsets.all(2),
      child: icon ?? Icon(Icons.clear, size: size, color: iconColor));
}

class AssetBuilder extends StatelessWidget {
  const AssetBuilder(this.entry,
      {super.key,
      this.isThumbnail = true,
      required this.fit,
      this.enableGesture = false});

  final ExtendedAssetEntity entry;

  /// 是否优先预览缩略图
  final bool isThumbnail;
  final BoxFit fit;
  final bool enableGesture;

  @override
  Widget build(BuildContext context) {
    switch (entry.type) {
      case AssetType.other:
        return _AssetOtherBuilder(entry, isThumbnail: isThumbnail, fit: fit);
      case AssetType.image:
        return _AssetImageBuilder(entry,
            isThumbnail: isThumbnail, fit: fit, enableGesture: enableGesture);
      case AssetType.video:
        return _AssetVideoBuilder(entry, isThumbnail: isThumbnail, fit: fit);
      case AssetType.audio:
        return _AssetOtherBuilder(entry, isThumbnail: isThumbnail, fit: fit);
    }
  }
}

class _AssetVideoBuilder extends StatelessWidget {
  const _AssetVideoBuilder(this.asset,
      {this.isThumbnail = false, required this.fit});

  final ExtendedAssetEntity asset;
  final bool isThumbnail;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (asset.type == AssetType.video) {
      Widget current = const SizedBox();
      ImageProvider? imageProvider;
      if (asset.thumbnailDataAsync != null) {
        imageProvider = ExtendedMemoryImageProvider(asset.thumbnailDataAsync!);
      } else if (asset.renovated != null) {
        imageProvider =
            ExtendedImageWithAssetsPicker.buildImageProvider(asset.renovated);
      }
      if (isThumbnail && imageProvider != null) {
        current = ExtendedImageWithAssetsPicker(imageProvider, fit: fit);
      } else {
        final controller =
            FlVideoPlayerWithAssetsPicker.buildVideoPlayerController(
                asset.previewed ?? asset.fileAsync);
        if (controller != null) {
          current = FlVideoPlayerWithAssetsPicker(
              controller: controller, cover: current);
        }
      }
      return current;
    }
    return const _PreviewSupported();
  }
}

class _AssetImageBuilder extends StatelessWidget {
  const _AssetImageBuilder(this.asset,
      {this.isThumbnail = false,
      required this.fit,
      this.enableGesture = false});

  final ExtendedAssetEntity asset;
  final bool isThumbnail;
  final BoxFit fit;
  final bool enableGesture;

  @override
  Widget build(BuildContext context) {
    if (asset.type == AssetType.image) {
      ImageProvider? imageProvider;
      if (asset.thumbnailDataAsync != null) {
        imageProvider =
            ExtendedImageWithAssetsPicker.assetEntityToImageProvider(asset);
      }
      imageProvider = isThumbnail && imageProvider != null
          ? imageProvider
          : ExtendedImageWithAssetsPicker.assetEntityToImageProvider(asset);
      if (imageProvider == null) return const SizedBox();
      return ExtendedImageWithAssetsPicker(imageProvider,
          mode: enableGesture
              ? ExtendedImageMode.gesture
              : ExtendedImageMode.none,
          initGestureConfigHandler: !enableGesture
              ? null
              : (ExtendedImageState state) => GestureConfig(
                  inPageView: true,
                  initialScale: 1.0,
                  maxScale: 5.0,
                  animationMaxScale: 6.0,
                  initialAlignment: InitialAlignment.center),
          fit: fit);
    }
    return const _PreviewSupported();
  }
}

class _AssetOtherBuilder extends StatelessWidget {
  const _AssetOtherBuilder(this.asset,
      {this.isThumbnail = false, required this.fit});

  final ExtendedAssetEntity asset;
  final bool isThumbnail;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (asset.type == AssetType.other || asset.type == AssetType.audio) {
      ImageProvider? thumbnailProvider;
      if (asset.thumbnailDataAsync != null) {
        thumbnailProvider =
            ExtendedImageWithAssetsPicker.assetEntityToImageProvider(asset);
      }
      if (isThumbnail && thumbnailProvider != null) {
        return ExtendedImageWithAssetsPicker(thumbnailProvider, fit: fit);
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