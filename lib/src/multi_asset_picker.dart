import 'dart:io';

import 'package:fl_assets_picker/fl_assets_picker.dart';
import 'package:flutter/cupertino.dart';

typedef FlPreviewAssetsModalPopupBuilder = void Function(
    BuildContext context, Widget previewAssets);

typedef FlPreviewAssetsBuilder = Widget Function(
    BuildContext context, List<ExtendedAssetEntity> entitys);

class PickerWrapBuilderConfig {
  const PickerWrapBuilderConfig(
      {this.direction = Axis.horizontal,
      this.alignment = WrapAlignment.start,
      this.crossAxisAlignment = WrapCrossAlignment.start,
      this.verticalDirection = VerticalDirection.down,
      this.runAlignment = WrapAlignment.start,
      this.width = double.infinity,
      this.height,
      this.constraints,
      this.decoration,
      this.spacing = 10,
      this.runSpacing = 10,
      this.margin = const EdgeInsets.all(10)});

  /// [Wrap]
  final double spacing;
  final double runSpacing;
  final WrapCrossAlignment crossAxisAlignment;
  final WrapAlignment alignment;
  final WrapAlignment runAlignment;
  final Axis direction;
  final VerticalDirection verticalDirection;

  /// [Container]
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final Decoration? decoration;
  final EdgeInsetsGeometry? margin;
}

typedef PickerIconBuilder = Widget Function();

typedef PickerWrapBuilder = Widget Function(List<Widget>);

typedef PickerErrorCallback = void Function(String msg);

typedef MultiPickerEntryBuilder = Widget Function(
    ExtendedAssetEntity entry, int index);

class MultiAssetPicker extends FlAssetsPicker {
  const MultiAssetPicker({
    super.key,
    this.onChanged,
    this.controller,
    this.entryConfig = const AssetsPickerEntryConfig(),
    this.entryBuilder,
    this.wrapConfig = const PickerWrapBuilderConfig(),
    this.wrapBuilder,
    this.initialData = const [],
    this.allowDelete = true,
    this.pickerIconBuilder,
    super.enablePicker = true,
    super.errorCallback,
    super.maxVideoCount = 1,
    super.maxCount = 9,
    super.fromRequestTypes = const [
      PickerFromTypeConfig(
          fromType: PickerFromType.assets,
          text: Text('图库选择'),
          requestType: RequestType.common),
      PickerFromTypeConfig(
          fromType: PickerFromType.camera,
          text: Text('相机拍摄'),
          requestType: RequestType.common),
      PickerFromTypeConfig(
          fromType: PickerFromType.cancel,
          text: Text('取消'),
          requestType: RequestType.common),
    ],
    super.renovate,
    super.pageRouteBuilderForCameraPicker,
    super.pageRouteBuilderForAssetPicker,
    super.fromTypesBuilder,
    super.checkPermission,
    this.previewBuilder,
    this.previewModalPopup,
  });

  /// 是否显示删除按钮
  final bool allowDelete;

  /// 默认初始资源
  final List<ExtendedAssetEntity> initialData;

  /// 资源选择变化
  final ValueChanged<List<ExtendedAssetEntity>>? onChanged;

  /// 资源控制器
  final AssetsPickerController? controller;

  /// wrap UI 样式配置
  final PickerWrapBuilderConfig wrapConfig;

  final PickerWrapBuilder? wrapBuilder;

  /// 资源选择 icon 自定义构造
  final PickerIconBuilder? pickerIconBuilder;

  /// 资源渲染子元素自定义构造
  final MultiPickerEntryBuilder? entryBuilder;

  /// entry UI 样式配置
  final AssetsPickerEntryConfig entryConfig;

  /// 弹出预览框 builder
  final FlPreviewAssetsModalPopupBuilder? previewModalPopup;

  /// 预览框 builder
  final FlPreviewAssetsBuilder? previewBuilder;

  @override
  State<MultiAssetPicker> createState() => _MultiAssetPickerState();

  /// [files] 文件地址转换 List<ExtendedAssetModel> 默认类型为  [AssetType.image]
  static List<ExtendedAssetEntity> convertFiles(List<File> files,
      {AssetType assetsType = AssetType.image}) {
    List<ExtendedAssetEntity> list = [];
    for (var element in files) {
      if (element.existsSync()) {
        list.add(
            ExtendedAssetEntity.fromFile(file: element, assetType: assetsType));
      }
    }
    return list;
  }

  /// [paths] 文件地址转换 List<ExtendedAssetModel> 默认类型为  [AssetType.image]
  static List<ExtendedAssetEntity> convertPaths(List<String> paths,
      {AssetType assetsType = AssetType.image}) {
    List<ExtendedAssetEntity> list = [];
    for (var element in paths) {
      if (element.isNotEmpty) {
        list.add(ExtendedAssetEntity.fromPreviewed(
            previewed: element, assetType: assetsType));
      }
    }
    return list;
  }

  /// [url] 地址转换 List<ExtendedAssetModel> 默认类型为  [AssetType.image]
  static List<ExtendedAssetEntity> convertUrls(String url,
      {AssetType assetsType = AssetType.image, String? splitPattern}) {
    List<ExtendedAssetEntity> list = [];
    if (url.isEmpty) return list;
    if (splitPattern != null && url.contains(splitPattern)) {
      final urls = url.split(splitPattern);
      for (var element in urls) {
        if (element.isNotEmpty) {
          list.add(ExtendedAssetEntity.fromPreviewed(
              previewed: element, assetType: assetsType));
        }
      }
    } else {
      list.add(ExtendedAssetEntity.fromPreviewed(
          assetType: assetsType, previewed: url));
    }
    return list;
  }

  /// 具体的数据  顺序为 url > path > file
  static List<String> toStringList(List<ExtendedAssetEntity> list) {
    List<String> value = [];
    for (var element in list) {
      if (element.realValueStr != null) {
        value.add(element.realValueStr!);
      }
    }
    return value;
  }

  /// 具体的数据  顺序为 url > path > file
  static List<dynamic> toDynamicList(List<ExtendedAssetEntity> list) {
    List<dynamic> value = [];
    for (var element in list) {
      if (element.realValue != null) {
        value.add(element.realValue!);
      }
    }
    return value;
  }
}

class _MultiAssetPickerState extends State<MultiAssetPicker> {
  late AssetsPickerController controller;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() {
    controller = widget.controller ?? AssetsPickerController();
    controller.assetsPicker = widget;
    controller.allAssetEntity.insertAll(0, widget.initialData);
    controller.addListener(listener);
  }

  void listener() {
    widget.onChanged?.call(controller.allAssetEntity);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final children = controller.allAssetEntity
        .asMap()
        .entries
        .map((entry) => buildEntry(entry))
        .toList();
    if (widget.enablePicker) children.add(buildPicker);
    if (widget.wrapBuilder != null) return widget.wrapBuilder!(children);
    final wrapConfig = widget.wrapConfig;
    return Container(
        margin: wrapConfig.margin,
        width: wrapConfig.width,
        height: wrapConfig.height,
        decoration: wrapConfig.decoration,
        constraints: wrapConfig.constraints,
        child: Wrap(
            direction: wrapConfig.direction,
            alignment: wrapConfig.alignment,
            crossAxisAlignment: wrapConfig.crossAxisAlignment,
            verticalDirection: wrapConfig.verticalDirection,
            runSpacing: wrapConfig.runSpacing,
            spacing: wrapConfig.spacing,
            children: children));
  }

  /// 资源预览 entry
  Widget buildEntry(MapEntry<int, ExtendedAssetEntity> entry) {
    final assetEntry = entry.value;
    final config = widget.entryConfig;
    Widget current = AssetBuilder(assetEntry, fit: config.fit);
    if (assetEntry.type == AssetType.video ||
        assetEntry.type == AssetType.audio) {
      current = Stack(children: [
        SizedBox.expand(child: current),
        if (assetEntry.type == AssetType.video ||
            assetEntry.type == AssetType.audio)
          Align(alignment: Alignment.center, child: config.play),
      ]);
    }
    if (config.color != null) {
      current = ColoredBox(color: config.color!, child: current);
    }
    current = GestureDetector(
        onTap: () => previewAssets(entry.value),
        child: widget.entryBuilder?.call(entry.value, entry.key) ?? current);
    if (widget.allowDelete) {
      current = Stack(children: [
        SizedBox.expand(child: current),
        Positioned(
            right: 2,
            top: 2,
            child: GestureDetector(
              onTap: () =>
                  widget.entryConfig.deletionConfirmation
                      ?.call(assetEntry)
                      .then((value) {
                    if (value) controller.deleteAsset(assetEntry.id);
                  }) ??
                  controller.deleteAsset(assetEntry.id),
              child: widget.entryConfig.delete,
            ))
      ]);
    }
    current = SizedBox.fromSize(size: config.size, child: current);
    if (config.borderRadius != null) {
      current = ClipRRect(borderRadius: config.borderRadius!, child: current);
    }
    return current;
  }

  void previewAssets(ExtendedAssetEntity asset) async {
    final currentAssetsEntry = controller.allAssetEntity;
    final previewAssets = FlPreviewAssets(
        itemCount: currentAssetsEntry.length,
        controller: ExtendedPageController(
            initialPage: currentAssetsEntry.indexOf(asset)),
        itemBuilder: (_, int index) => Center(
            child: AssetBuilder(currentAssetsEntry[index],
                enableGesture: true,
                isThumbnail: false,
                fit: widget.entryConfig.previewFit)));

    if (widget.previewModalPopup == null) {
      showCupertinoModalPopup(
          context: context,
          builder: (BuildContext context) =>
              widget.previewBuilder?.call(context, currentAssetsEntry) ??
              previewAssets);
    } else {
      widget.previewModalPopup?.call(context, previewAssets);
    }
  }

  void pickerAsset() async {
    FocusScope.of(context).requestFocus(FocusNode());
    final assetsEntry = controller.allAssetEntity;
    if (assetsEntry.length >= widget.maxCount) {
      widget.errorCallback?.call('最多选择${widget.maxCount}个');
      return;
    }
    controller.pickFromType(context, mounted: mounted);
  }

  /// 选择框
  Widget get buildPicker {
    final config = widget.entryConfig;
    Widget current = SizedBox(
        width: config.size.width,
        height: config.size.height,
        child: config.pick);
    if (config.color != null) {
      current = ColoredBox(color: config.color!, child: current);
    }
    if (config.borderRadius != null) {
      current = ClipRRect(borderRadius: config.borderRadius!, child: current);
    }
    current = GestureDetector(
        onTap: pickerAsset, child: widget.pickerIconBuilder?.call() ?? current);
    return current;
  }

  @override
  void dispose() {
    super.dispose();
    controller.removeListener(listener);
    controller.dispose();
  }
}
