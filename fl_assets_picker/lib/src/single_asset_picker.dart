import 'package:fl_assets_picker/fl_assets_picker.dart';
import 'package:flutter/material.dart';

typedef SinglePickerEntryBuilder = Widget Function(ExtendedAssetEntity entry);

class SingleAssetPicker extends FlAssetsPicker {
  const SingleAssetPicker({
    super.key,
    this.onChanged,
    super.enablePicker = true,
    super.errorCallback,
    super.fromRequestTypes = defaultPickerFromTypeItem,
    super.pageRouteBuilderForCameraPicker,
    super.pageRouteBuilderForAssetPicker,
    super.fromTypesBuilder,
    super.renovate,
    super.checkPermission,
    this.config = const AssetsPickerEntryConfig(),
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
  final AssetsPickerEntryConfig config;

  /// [paths] 文件地址转换 List<ExtendedAssetModel> 默认类型为  [AssetType.image]
  static ExtendedAssetEntity? convertPath(String path,
      {AssetType assetsType = AssetType.image}) {
    if (path.isNotEmpty) {
      return ExtendedAssetEntity.fromPreviewed(
          previewed: path, assetType: assetsType);
    }
    return null;
  }

  /// [url] 地址转换 List<ExtendedAssetModel> 默认类型为  [AssetType.image]
  static ExtendedAssetEntity? convertUrl(String url,
      {AssetType assetsType = AssetType.image}) {
    if (url.isNotEmpty) {
      return ExtendedAssetEntity.fromPreviewed(
          previewed: url, assetType: assetsType);
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
    controller.assetsPicker = widget;
    if (widget.initialData != null) {
      controller.allAssetEntity = [widget.initialData!];
    }
    controller.addListener(listener);
  }

  void listener() {
    if (controller.allAssetEntity.isNotEmpty) {
      widget.onChanged?.call(controller.allAssetEntity.first);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget current = widget.config.pick;
    final allAssetEntity = controller.allAssetEntity;
    final config = widget.config;
    if (allAssetEntity.isNotEmpty) {
      final entity = allAssetEntity.first;
      current = widget.builder?.call(entity) ?? entryBuild(entity);
      if (entity.type == AssetType.video || entity.type == AssetType.audio) {
        current = Stack(children: [
          SizedBox.expand(child: current),
          if (entity.type == AssetType.video || entity.type == AssetType.audio)
            Align(alignment: Alignment.center, child: config.play),
        ]);
      }
    }
    if (config.color != null) {
      current = ColoredBox(color: config.color!, child: current);
    }
    if (widget.enablePicker) {
      current = GestureDetector(onTap: pickerAsset, child: current);
    }
    current = SizedBox.fromSize(size: config.size, child: current);
    if (config.borderRadius != null) {
      current = ClipRRect(borderRadius: config.borderRadius!, child: current);
    }
    return current;
  }

  Widget entryBuild(ExtendedAssetEntity entity) {
    if (entity.previewed == null && entity.fileAsync == null) {
      return widget.config.pick;
    }
    return AssetBuilder(entity, isThumbnail: true, fit: widget.config.fit);
  }

  void pickerAsset() async {
    FocusScope.of(context).requestFocus(FocusNode());
    controller.pickFromType(context);
  }

  @override
  void dispose() {
    super.dispose();
    controller.removeListener(listener);
    controller.dispose();
  }
}