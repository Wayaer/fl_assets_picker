part of 'image_picker.dart';

typedef FlPreviewAssetsModalPopupBuilder = void Function(
    BuildContext context, Widget previewAssets);

typedef FlPreviewAssetsBuilder = Widget Function(
    BuildContext context, ExtendedXFile current, List<ExtendedXFile> entitys);

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

typedef MultiplePickerItemBuilder = Widget Function(
    ExtendedXFile item, int index);

class MultipleImagePicker extends FlImagePicker {
  const MultipleImagePicker({
    super.key,
    this.onChanged,
    this.controller,
    super.itemConfig = const ImagePickerItemConfig(),
    this.itemBuilder,
    this.wrapConfig = const PickerWrapBuilderConfig(),
    this.wrapBuilder,
    this.initialData = const [],
    this.allowDelete = true,
    this.pickerIconBuilder,
    super.enablePicker = true,
    super.maxVideoCount = 1,
    super.maxCount = 9,
    super.fromTypes = defaultPickerFromTypeItem,
    super.renovate,
  });

  /// 是否显示删除按钮
  final bool allowDelete;

  /// 默认初始资源
  final List<ExtendedXFile> initialData;

  /// 资源选择变化
  final ValueChanged<List<ExtendedXFile>>? onChanged;

  /// 资源控制器
  final ImagePickerController? controller;

  /// wrap UI 样式配置
  final PickerWrapBuilderConfig wrapConfig;

  final PickerWrapBuilder? wrapBuilder;

  /// 资源选择 icon 自定义构造
  final PickerIconBuilder? pickerIconBuilder;

  /// 资源渲染子元素自定义构造
  final MultiplePickerItemBuilder? itemBuilder;

  @override
  State<MultipleImagePicker> createState() => _MultipleImagePickerState();

  /// [paths] 文件地址转换 List<ExtendedAssetModel> 默认类型为  [AssetType.image]
  static List<ExtendedXFile> convertPaths(List<String> paths,
      {AssetType assetsType = AssetType.image}) {
    List<ExtendedXFile> list = [];
    for (var element in paths) {
      if (element.isNotEmpty) {
        list.add(ExtendedXFile.fromPreviewed(element, assetsType));
      }
    }
    return list;
  }

  /// [url] 地址转换 List<ExtendedAssetModel> 默认类型为  [AssetType.image]
  static List<ExtendedXFile> convertUrls(String url,
      {AssetType assetsType = AssetType.image, String? splitPattern}) {
    List<ExtendedXFile> list = [];
    if (url.isEmpty) return list;
    if (splitPattern != null && url.contains(splitPattern)) {
      final urls = url.split(splitPattern);
      for (var element in urls) {
        if (element.isNotEmpty) {
          list.add(ExtendedXFile.fromPreviewed(element, assetsType));
        }
      }
    } else {
      list.add(ExtendedXFile.fromPreviewed(url, assetsType));
    }
    return list;
  }

  /// 具体的数据  顺序为 url > path > file
  static List<String> toStringList(List<ExtendedXFile> list) {
    List<String> value = [];
    for (var element in list) {
      if (element.realValueStr != null) {
        value.add(element.realValueStr!);
      }
    }
    return value;
  }

  /// 具体的数据  顺序为 url > path > file
  static List<dynamic> toDynamicList(List<ExtendedXFile> list) {
    List<dynamic> value = [];
    for (var element in list) {
      if (element.realValue != null) {
        value.add(element.realValue!);
      }
    }
    return value;
  }
}

class _MultipleImagePickerState extends State<MultipleImagePicker> {
  late ImagePickerController controller;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() {
    controller = widget.controller ?? ImagePickerController();
    controller.assetsPicker = widget;
    controller.allEntity.insertAll(0, widget.initialData);
    controller.addListener(listener);
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
        .map((item) => buildEntry(item))
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
  Widget buildEntry(MapEntry<int, ExtendedXFile> item) {
    final entity = item.value;
    final config = widget.itemConfig;
    Widget current = FlImagePicker.assetBuilder(entity, true);
    if (entity.type == AssetType.video) {
      current = Stack(children: [
        SizedBox.expand(child: current),
        Align(alignment: Alignment.center, child: config.play),
      ]);
    }
    if (config.color != null) {
      current = ColoredBox(color: config.color!, child: current);
    }
    current = GestureDetector(
        onTap: () => previewAssets(item.value),
        child: widget.itemBuilder?.call(item.value, item.key) ?? current);
    if (widget.allowDelete) {
      current = Stack(children: [
        SizedBox.expand(child: current),
        Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(
              onTap: () =>
                  widget.itemConfig.deletionConfirmation
                      ?.call(entity)
                      .then((value) {
                    if (value) controller.delete(entity);
                  }) ??
                  controller.delete(entity),
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

  /// 全屏预览
  void previewAssets(ExtendedXFile entity) {
    final allEntity = controller.allEntity;
    FlImagePicker.previewModalPopup(
        context, FlImagePicker.previewBuilder(context, entity, allEntity));
  }

  void pickerAsset() async {
    FocusScope.of(context).requestFocus(FocusNode());
    final assetsEntry = controller.allEntity;
    if (assetsEntry.length >= widget.maxCount) {
      FlImagePicker.errorCallback?.call('最多选择${widget.maxCount}个');
      return;
    }
    controller.pickFromType(context, mounted: mounted);
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
