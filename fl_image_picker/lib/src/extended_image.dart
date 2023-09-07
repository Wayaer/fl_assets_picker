import 'dart:io';

import 'package:fl_assets_picker/fl_assets_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef ExtendedImageLoadStateBuilder = Widget Function(ExtendedImageState);

class ExtendedImageWithAssetsPicker extends ExtendedImage {
  ExtendedImageWithAssetsPicker(ImageProvider image,
      {super.key,
      this.loading,
      this.failed,
      super.width,
      super.height,
      super.mode,
      super.initGestureConfigHandler,
      super.fit = BoxFit.cover})
      : super(
            image: image,
            enableLoadState: true,
            loadStateChanged:
                _buildLoadStateChanged(failed: failed, loading: loading));

  ExtendedImageWithAssetsPicker.asset(String name,
      {super.key,
      this.loading,
      this.failed,
      super.width,
      super.height,
      super.mode,
      super.initGestureConfigHandler,
      super.fit = BoxFit.cover})
      : super.asset(name,
            imageCacheName: name,
            enableLoadState: true,
            loadStateChanged:
                _buildLoadStateChanged(failed: failed, loading: loading));

  ExtendedImageWithAssetsPicker.file(File file,
      {super.key,
      this.loading,
      this.failed,
      super.width,
      super.height,
      super.mode,
      super.initGestureConfigHandler,
      super.fit = BoxFit.cover})
      : super.file(file,
            imageCacheName: file.path,
            enableLoadState: true,
            loadStateChanged:
                _buildLoadStateChanged(failed: failed, loading: loading));

  ExtendedImageWithAssetsPicker.network(String url,
      {super.key,
      this.loading,
      this.failed,
      super.width,
      super.height,
      super.mode,
      super.initGestureConfigHandler,
      super.fit = BoxFit.cover})
      : super.network(url,
            imageCacheName: url,
            enableLoadState: true,
            loadStateChanged:
                _buildLoadStateChanged(failed: failed, loading: loading));

  ExtendedImageWithAssetsPicker.memory(Uint8List bytes,
      {super.key,
      this.loading,
      this.failed,
      super.width,
      super.height,
      super.mode,
      super.initGestureConfigHandler,
      super.fit = BoxFit.cover})
      : super.memory(bytes,
            imageCacheName: bytes.hashCode.toString(),
            enableLoadState: true,
            loadStateChanged:
                _buildLoadStateChanged(failed: failed, loading: loading));

  final ExtendedImageLoadStateBuilder? loading;
  final ExtendedImageLoadStateBuilder? failed;

  static LoadStateChanged _buildLoadStateChanged(
          {ExtendedImageLoadStateBuilder? loading,
          ExtendedImageLoadStateBuilder? failed}) =>
      (ExtendedImageState state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            return Center(child: loading?.call(state) ?? const SizedBox());
          case LoadState.completed:
            return null;
          case LoadState.failed:
            return GestureDetector(
                onTap: state.reLoadImage,
                child: Center(
                    child:
                        failed?.call(state) ?? const Icon(Icons.info_outline)));
        }
      };

  /// fileAsync > previewUrl > previewPath
  static ImageProvider? assetEntityToImageProvider(
      ExtendedXFile assetEntity) {
    ImageProvider? provider;
    if (assetEntity.renovated != null) {
      provider = ExtendedImageWithAssetsPicker.buildImageProvider(
          assetEntity.renovated);
    } else if (assetEntity.fileAsync != null) {
      provider = ExtendedFileImageProvider(assetEntity.fileAsync!);
    } else if (assetEntity.previewed != null) {
      final previewed = assetEntity.previewed!;
      if (previewed.startsWith('http')) {
        provider = ExtendedNetworkImageProvider(previewed);
      } else {
        provider = ExtendedAssetImageProvider(previewed);
      }
    }
    return provider;
  }

  static ImageProvider? buildImageProvider(dynamic value) {
    if (value is File) {
      return ExtendedFileImageProvider(value);
    } else if (value is String && value.startsWith('http')) {
      return ExtendedNetworkImageProvider(value);
    } else if (value is Uint8List) {
      return ExtendedMemoryImageProvider(value);
    }
    return null;
  }
}
