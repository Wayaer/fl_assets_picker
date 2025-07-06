part of '../fl_assets_picker.dart';

class MultipleAssetsPickerListBuilderConfig {
  const MultipleAssetsPickerListBuilderConfig({
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 10,
    this.mainAxisSpacing = 10,
    this.maxCrossAxisExtent,
    this.crossAxisCount = 4,
  });

  /// 列数
  final int crossAxisCount;

  /// 最大列宽 [maxCrossAxisExtent] > [crossAxisCount]
  final double? maxCrossAxisExtent;

  /// 主轴间距
  final double mainAxisSpacing;

  /// 交叉轴间距
  final double crossAxisSpacing;

  /// 子元素宽高比
  final double childAspectRatio;
}

typedef MultipleAssetsPickerListBuilder = Widget Function(List<Widget> images);

typedef MultiplePickerListItemBuilder = Widget Function(
    FlAssetEntity asset, int index);

class MultipleAssetsPicker extends FlAssetsPicker {
  const MultipleAssetsPicker({
    super.key,
    required super.controller,
    super.disposeController = false,
    this.onChanged,
    super.itemConfig = const FlAssetsPickerItemConfig(),
    this.itemBuilder,
    this.builderConfig = const MultipleAssetsPickerListBuilderConfig(),
    this.builder,
    this.allowDelete = true,
  });

  /// 是否显示删除按钮
  final bool allowDelete;

  /// 资源选择变化
  final ValueChanged<List<FlAssetEntity>>? onChanged;

  /// wrap UI 样式配置
  final MultipleAssetsPickerListBuilderConfig builderConfig;

  /// wrap 自定义
  final MultipleAssetsPickerListBuilder? builder;

  /// 资源渲染子元素自定义构造
  final MultiplePickerListItemBuilder? itemBuilder;

  @override
  State<MultipleAssetsPicker> createState() => _MultipleAssetsPickerState();

  /// [paths] 文件地址转换 `List<ExtendedAssetModel>` 默认类型为  [AssetType.image]
  static List<FlAssetEntity> convertPaths(List<String> paths,
      {AssetType assetsType = AssetType.image}) {
    List<FlAssetEntity> list = [];
    for (var element in paths) {
      if (element.isNotEmpty) {
        list.add(FlAssetEntity.fromPreviewed(
            previewed: element, assetType: assetsType));
      }
    }
    return list;
  }

  /// [url] 地址转换 `List<ExtendedAssetModel>` 默认类型为  [AssetType.image]
  static List<FlAssetEntity> convertUrls(String url,
      {AssetType assetsType = AssetType.image, String? splitPattern}) {
    List<FlAssetEntity> list = [];
    if (url.isEmpty) return list;
    if (splitPattern != null && url.contains(splitPattern)) {
      final urls = url.split(splitPattern);
      for (var element in urls) {
        if (element.isNotEmpty) {
          list.add(FlAssetEntity.fromPreviewed(
              previewed: element, assetType: assetsType));
        }
      }
    } else {
      list.add(
          FlAssetEntity.fromPreviewed(assetType: assetsType, previewed: url));
    }
    return list;
  }

  /// 具体的数据  顺序为 url > path > file
  static List<String> toStringList(List<FlAssetEntity> list) {
    List<String> value = [];
    for (var element in list) {
      if (element.realValueStr != null) {
        value.add(element.realValueStr!);
      }
    }
    return value;
  }

  /// 具体的数据  顺序为 url > path > file
  static List<dynamic> toDynamicList(List<FlAssetEntity> list) {
    List<dynamic> value = [];
    for (var element in list) {
      if (element.realValue != null) {
        value.add(element.realValue!);
      }
    }
    return value;
  }
}

class _MultipleAssetsPickerState
    extends FlAssetsPickerState<MultipleAssetsPicker> {
  @override
  void listener() {
    widget.onChanged?.call(widget.controller.entities);
    super.listener();
  }

  @override
  Widget build(BuildContext context) {
    final children =
        widget.controller.entities.asMap().entries.map(buildEntry).toList();
    if (widget.controller.allowPick) children.add(buildPicker);
    if (widget.builder != null) return widget.builder!(children);
    final builderConfig = widget.builderConfig;
    SliverGridDelegate gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: builderConfig.crossAxisCount,
        mainAxisSpacing: builderConfig.mainAxisSpacing,
        crossAxisSpacing: builderConfig.crossAxisSpacing,
        childAspectRatio: builderConfig.childAspectRatio);
    if (builderConfig.maxCrossAxisExtent != null) {
      gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: builderConfig.maxCrossAxisExtent!,
          mainAxisSpacing: builderConfig.mainAxisSpacing,
          crossAxisSpacing: builderConfig.crossAxisSpacing,
          childAspectRatio: builderConfig.childAspectRatio);
    }
    return GridView(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: gridDelegate,
        children: children);
  }

  /// 资源预览 asset
  Widget buildEntry(MapEntry<int, FlAssetEntity> asset) {
    final entity = asset.value;
    Widget current = FlAssetsPicker.assetBuilder(entity, true);
    current = buildVideo(entity, current);
    current = buildBackgroundColor(current);
    current = GestureDetector(
        onTap: () {
          widget.controller.preview(context, initialIndex: asset.key);
        },
        child: widget.itemBuilder?.call(asset.value, asset.key) ?? current);
    current = buildDelete(entity, current);
    current = buildBorderRadius(current);
    return current;
  }

  Widget buildDelete(FlAssetEntity asset, Widget current) {
    if (widget.allowDelete) {
      current = Stack(children: [
        SizedBox.expand(child: current),
        Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(
              onTap: () {
                widget.controller.delete(asset);
              },
              child: widget.itemConfig.delete,
            ))
      ]);
    }
    return current;
  }

  /// 选择框
  Widget get buildPicker {
    Widget current = widget.itemConfig.pick;
    current = buildBackgroundColor(current);
    current = buildBorderRadius(current);
    current = buildPickActions(current);
    return current;
  }
}
