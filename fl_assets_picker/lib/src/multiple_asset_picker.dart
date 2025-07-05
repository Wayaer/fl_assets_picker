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
    ExtendedAssetEntity item, int index);

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
  final ValueChanged<List<ExtendedAssetEntity>>? onChanged;

  /// wrap UI 样式配置
  final MultipleAssetsPickerListBuilderConfig builderConfig;

  /// wrap 自定义
  final MultipleAssetsPickerListBuilder? builder;

  /// 资源渲染子元素自定义构造
  final MultiplePickerListItemBuilder? itemBuilder;

  @override
  State<MultipleAssetsPicker> createState() => _MultipleAssetsPickerState();

  /// [paths] 文件地址转换 `List<ExtendedAssetModel>` 默认类型为  [AssetType.image]
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

  /// [url] 地址转换 `List<ExtendedAssetModel>` 默认类型为  [AssetType.image]
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

class _MultipleAssetsPickerState extends State<MultipleAssetsPicker> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(listener);
  }

  void listener() {
    widget.onChanged?.call(widget.controller.entities);
    if (mounted) setState(() {});
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

  /// 资源预览 item
  Widget buildEntry(MapEntry<int, ExtendedAssetEntity> item) {
    final entity = item.value;
    final config = widget.itemConfig;
    Widget current = FlAssetsPicker.assetBuilder(entity, true);
    if (entity.type == AssetType.video) {
      current = Stack(children: [
        SizedBox.expand(child: current),
        Align(alignment: Alignment.center, child: config.play),
      ]);
    }
    if (config.backgroundColor != null) {
      current = ColoredBox(color: config.backgroundColor!, child: current);
    }
    current = GestureDetector(
        onTap: () {
          widget.controller.preview(context, initialIndex: item.key);
        },
        child: widget.itemBuilder?.call(item.value, item.key) ?? current);
    if (widget.allowDelete) {
      current = Stack(children: [
        SizedBox.expand(child: current),
        Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(
              onTap: () {
                widget.controller.delete(entity);
              },
              child: widget.itemConfig.delete,
            ))
      ]);
    }
    if (config.borderRadius != null) {
      current = ClipRRect(borderRadius: config.borderRadius!, child: current);
    }
    return current;
  }

  /// 选择框
  Widget get buildPicker {
    final config = widget.itemConfig;
    Widget current = config.pick;
    if (config.backgroundColor != null) {
      current = ColoredBox(color: config.backgroundColor!, child: current);
    }
    if (config.borderRadius != null) {
      current = ClipRRect(borderRadius: config.borderRadius!, child: current);
    }
    return GestureDetector(
        onTap: () {
          widget.controller.pickActions(context);
        },
        child: current);
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.removeListener(listener);
    if (widget.disposeController) widget.controller.dispose();
  }
}
