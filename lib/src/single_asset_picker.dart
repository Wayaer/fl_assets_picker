import 'dart:io';

import 'package:fl_assets_picker/fl_assets_picker.dart';
import 'package:flutter/material.dart';

typedef SinglePickerEntryBuilder = Widget Function(ExtendedAssetEntity entry);

class SingleAssetPicker extends FlAssetsPicker {
  const SingleAssetPicker({
    super.key,
    this.onChanged,
    super.enablePicker = true,
    super.errorCallback,
    super.fromRequestTypes = const [
      PickerFromTypeConfig(
          fromType: PickerFromType.assets,
          text: Text('图库选择'),
          requestType: RequestType.image),
      PickerFromTypeConfig(
          fromType: PickerFromType.camera,
          text: Text('相机拍摄'),
          requestType: RequestType.image),
      PickerFromTypeConfig(fromType: PickerFromType.cancel, text: Text('取消')),
    ],
    super.pageRouteBuilderForCameraPicker,
    super.pageRouteBuilderForAssetPicker,
    super.fromTypesBuilder,
    super.renovate,
    this.config = const PickerAssetEntryBuilderConfig(),
    this.builder,
    this.initialData,
    this.allowDelete = true,
  }) : super(maxCount: 1, maxVideoCount: 0);

  /// 是否显示删除按钮
  final bool allowDelete;

  /// 默认初始资源
  final ExtendedAssetEntity? initialData;

  /// 资源选择变化
  final ValueChanged<ExtendedAssetEntity>? onChanged;

  /// 资源渲染子元素自定义构造
  final SinglePickerEntryBuilder? builder;

  ///
  final PickerAssetEntryBuilderConfig config;

  /// [paths] 文件地址转换 [ExtendedAssetModel] 默认类型为  [AssetType.image]
  static ExtendedAssetEntity? convertFiles(File file,
      {AssetType assetsType = AssetType.image}) {
    if (file.existsSync()) {
      return ExtendedAssetEntity.fromFile(file: file, assetType: assetsType);
    }
    return null;
  }

  /// [paths] 文件地址转换 List<ExtendedAssetModel> 默认类型为  [AssetType.image]
  static ExtendedAssetEntity? convertPaths(String path,
      {AssetType assetsType = AssetType.image}) {
    if (path.isNotEmpty) {
      return ExtendedAssetEntity.fromPath(
          previewPath: path, assetType: assetsType);
    }
    return null;
  }

  /// [url] 地址转换 List<ExtendedAssetModel> 默认类型为  [AssetType.image]
  static ExtendedAssetEntity? convertUrl(String url,
      {AssetType assetsType = AssetType.image}) {
    if (url.isNotEmpty) {
      return ExtendedAssetEntity.fromUrl(
          previewUrl: url, assetType: assetsType);
    }
    return null;
  }

  @override
  State<SingleAssetPicker> createState() => _SingleAssetPickerState();
}

class _SingleAssetPickerState extends State<SingleAssetPicker> {
  late AssetsPickerController controller;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() {
    controller = AssetsPickerController();
    controller.setWidget(widget);
    if (widget.initialData != null) {
      controller.allAssetEntity = [widget.initialData!];
    }
    controller.addListener(listener);
  }

  void listener() {
    widget.onChanged?.call(controller.allAssetEntity.first);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Widget current = const SizedBox();
    final allAssetEntity = controller.allAssetEntity;
    final config = widget.config;
    if (allAssetEntity.isNotEmpty) {
      final entity = allAssetEntity.first;
      current = widget.builder?.call(entity) ?? entryBuild(entity);
      if (config.overlay != null ||
          entity.type == AssetType.video ||
          entity.type == AssetType.audio) {
        current = Stack(children: [
          current,
          if (config.overlay != null) config.overlay!,
          Align(alignment: Alignment.center, child: config.playIcon),
        ]);
      }
    } else {
      current = widget.config.pickerIcon;
    }
    if (config.color != null) {
      current = ColoredBox(color: config.color!, child: current);
    }
    if (widget.enablePicker) {
      current = GestureDetector(onTap: pickerAsset, child: current);
    }
    current = SizedBox.fromSize(size: config.size, child: current);
    if (config.borderRadius != null) {
      current = ClipRRect(borderRadius: config.borderRadius, child: current);
    }
    return current;
  }

  Widget entryBuild(ExtendedAssetEntity entity) {
    if (entity.previewUrl == null &&
        entity.previewPath == null &&
        entity.fileAsync == null) {
      return widget.config.pickerIcon;
    }
    return AssetsPickerEntryBuild(entity,
        isThumbnail: true, fit: widget.config.fit);
  }

  void pickerAsset() async {
    FocusScope.of(context).requestFocus(FocusNode());
    controller.pickFromType(context, mounted: mounted);
  }

  @override
  void dispose() {
    super.dispose();
    controller.removeListener(listener);
    controller.dispose();
  }
}
