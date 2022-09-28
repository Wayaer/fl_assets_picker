import 'dart:io';

import 'package:fl_assets_picker/fl_assets_picker.dart';
import 'package:flutter/material.dart';

typedef ExtendedImageLoadStateBuilder = Widget Function(ExtendedImageState);

class PickerExtendedImage extends StatelessWidget {
  const PickerExtendedImage(this.image,
      {super.key,
      this.loading,
      this.error,
      this.width,
      this.height,
      this.fit = BoxFit.cover});

  PickerExtendedImage.asset(String name,
      {super.key,
      this.loading,
      this.error,
      this.width,
      this.height,
      this.fit = BoxFit.cover})
      : image = ExtendedAssetImageProvider(name, imageCacheName: name);

  PickerExtendedImage.file(File file,
      {super.key,
      this.loading,
      this.error,
      this.width,
      this.height,
      this.fit = BoxFit.cover})
      : image = ExtendedFileImageProvider(file, imageCacheName: file.path);

  PickerExtendedImage.network(String url,
      {super.key,
      this.loading,
      this.error,
      this.width,
      this.height,
      this.fit = BoxFit.cover})
      : image = ExtendedNetworkImageProvider(url, imageCacheName: url);

  /// fileAsync > previewUrl > previewPath
  static ImageProvider? assetEntityToImageProvider(
      ExtendedAssetEntity assetEntity) {
    ImageProvider? provider;
    if (assetEntity.fileAsync != null) {
      provider = ExtendedFileImageProvider(assetEntity.fileAsync!);
    } else if (assetEntity.previewUrl != null) {
      provider = ExtendedNetworkImageProvider(assetEntity.previewUrl!);
    } else if (assetEntity.previewPath != null) {
      provider = ExtendedAssetImageProvider(assetEntity.previewPath!);
    }
    return provider;
  }

  final ImageProvider image;
  final ExtendedImageLoadStateBuilder? loading;
  final ExtendedImageLoadStateBuilder? error;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return ExtendedImage(
        fit: fit,
        image: image,
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        loadStateChanged: (ExtendedImageState state) {
          switch (state.extendedImageLoadState) {
            case LoadState.loading:
              return Center(child: loading?.call(state) ?? const SizedBox());
            case LoadState.completed:
              return ExtendedRawImage(
                  width: width,
                  height: height,
                  image: state.extendedImageInfo?.image,
                  fit: fit);
            case LoadState.failed:
              return GestureDetector(
                  onTap: state.reLoadImage,
                  child: Center(
                      child: error?.call(state) ??
                          const Icon(Icons.info_outline)));
          }
        });
  }
}
