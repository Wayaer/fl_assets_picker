part of 'asset_picker.dart';

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
      this.margin});

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

typedef PickerWrapBuilder = Widget Function(List<Widget>);

typedef MultiplePickerItemBuilder = Widget Function(
    ExtendedAssetEntity item, int index);

class MultipleAssetPicker extends FlAssetsPicker {
  const MultipleAssetPicker({
    super.key,
    this.onChanged,
    this.controller,
    this.itemBuilder,
    this.wrapConfig = const PickerWrapBuilderConfig(),
    this.wrapBuilder,
    this.initialData = const [],
    this.allowDelete = true,
    super.itemConfig = const AssetsPickerItemConfig(),
    super.enablePicker = true,
    super.maxVideoCount = 0,
    super.maxCount = 9,
    super.actions = defaultPickerActions,
    super.renovate,
    super.pageRouteBuilderForCameraPicker,
    super.pageRouteBuilderForAssetPicker,
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

  /// wrap 自定义
  final PickerWrapBuilder? wrapBuilder;

  /// 资源渲染子元素自定义构造
  final MultiplePickerItemBuilder? itemBuilder;

  @override
  State<MultipleAssetPicker> createState() => _MultipleAssetPickerState();

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

class _MultipleAssetPickerState extends State<MultipleAssetPicker> {
  late AssetsPickerController controller;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() {
    controller = widget.controller ?? AssetsPickerController();
    controller.assetsPicker = widget;
    controller.allEntity.insertAll(0, widget.initialData);
    controller.addListener(listener);
  }

  @override
  void didUpdateWidget(covariant MultipleAssetPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    controller.assetsPicker = widget;
  }

  void listener() {
    widget.onChanged?.call(controller.allEntity);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final children = controller.allEntity
        .asMap()
        .entries
        .map((item) => buildItem(item))
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

  /// 资源预览 item
  Widget buildItem(MapEntry<int, ExtendedAssetEntity> entry) {
    final item = entry.value;
    final config = widget.itemConfig;
    Widget current = FlAssetsPicker.assetBuilder(item, true);
    if (item.type == AssetType.video || item.type == AssetType.audio) {
      current = Stack(children: [
        SizedBox.expand(child: current),
        if (item.type == AssetType.video || item.type == AssetType.audio)
          Align(alignment: Alignment.center, child: config.play),
      ]);
    }
    if (config.color != null) {
      current = ColoredBox(color: config.color!, child: current);
    }
    current = GestureDetector(
        onTap: () => previewAssets(item),
        child: widget.itemBuilder?.call(item, entry.key) ?? current);
    if (widget.allowDelete) {
      current = Stack(children: [
        SizedBox.expand(child: current),
        Positioned(
            right: 2,
            top: 2,
            child: GestureDetector(
              onTap: () =>
                  widget.itemConfig.deletionConfirmation
                      ?.call(item)
                      .then((value) {
                    if (value) controller.delete(item);
                  }) ??
                  controller.delete(item),
              child: widget.itemConfig.delete,
            ))
      ]);
    }
    current = SizedBox.fromSize(size: config.size, child: current);
    if (config.borderRadius != null) {
      current = ClipRRect(borderRadius: config.borderRadius!, child: current);
    }
    return current;
  }

  void previewAssets(ExtendedAssetEntity entity) async {
    final allEntity = controller.allEntity;
    FlAssetsPicker.previewModalPopup(
        context, FlAssetsPicker.previewBuilder(context, entity, allEntity));
  }

  void pickerAsset() async {
    FocusScope.of(context).requestFocus(FocusNode());
    final assetsItem = controller.allEntity;
    if (assetsItem.length >= widget.maxCount) {
      FlAssetsPicker.errorCallback?.call(ErrorDes.maxCount);
      return;
    }
    controller.pickActions(context);
  }

  /// 选择框
  Widget get buildPicker {
    final config = widget.itemConfig;
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
    current = GestureDetector(onTap: pickerAsset, child: current);
    return current;
  }

  @override
  void dispose() {
    super.dispose();
    controller.removeListener(listener);
    controller.dispose();
  }
}

class FlPreviewGesturePageView extends StatelessWidget {
  const FlPreviewGesturePageView({
    super.key,
    required this.pageView,
    this.close,
    this.overlay,
    this.backgroundColor = Colors.black87,
  });

  final Widget pageView;

  /// 关闭按钮
  final Widget? close;

  /// 在图片的上层
  final Widget? overlay;

  /// 背景色
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
        color: backgroundColor,
        child: Stack(children: [
          SizedBox.expand(child: pageView),
          if (overlay != null) SizedBox.expand(child: overlay!),
          Positioned(
              right: 6,
              top: MediaQuery.of(context).viewPadding.top,
              child: close ?? const CloseButton(color: Colors.white)),
        ]));
  }
}
