import 'dart:io';

import 'package:fl_assets_picker/fl_assets_picker.dart';
import 'package:flutter/material.dart';

typedef ExtendedImageLoadStateBuilder = Widget Function(ExtendedImageState);

class PickerExtendedImage extends StatelessWidget {
  const PickerExtendedImage(this.image,
      {Key? key,
      this.loading,
      this.error,
      this.width,
      this.height,
      this.fit = BoxFit.cover})
      : super(key: key);

  PickerExtendedImage.asset(String name,
      {Key? key,
      this.loading,
      this.error,
      this.width,
      this.height,
      this.fit = BoxFit.cover})
      : image = ExtendedAssetImageProvider(name, imageCacheName: name),
        super(key: key);

  PickerExtendedImage.file(File file,
      {Key? key,
      this.loading,
      this.error,
      this.width,
      this.height,
      this.fit = BoxFit.cover})
      : image = ExtendedFileImageProvider(file, imageCacheName: file.path),
        super(key: key);

  PickerExtendedImage.network(String url,
      {Key? key,
      this.loading,
      this.error,
      this.width,
      this.height,
      this.fit = BoxFit.cover})
      : image = ExtendedNetworkImageProvider(url, imageCacheName: url),
        super(key: key);

  static ImageProvider? assetEntityToImageProvider(
      ExtendedAssetEntity assetEntity) {
    ImageProvider? provider;
    if (assetEntity.previewPath != null) {
      provider = ExtendedAssetImageProvider(assetEntity.previewPath!);
    } else if (assetEntity.fileAsync != null) {
      provider = ExtendedFileImageProvider(assetEntity.fileAsync!);
    } else if (assetEntity.previewUrl != null) {
      provider = ExtendedNetworkImageProvider(assetEntity.previewUrl!);
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
  Widget build(BuildContext context) => ExtendedImage(
      fit: fit,
      image: image,
      width: width,
      height: height,
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
                    child:
                        error?.call(state) ?? const Icon(Icons.info_outline)));
        }
      });
}
