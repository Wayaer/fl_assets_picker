part of '../fl_image_picker.dart';

class SingleImagePicker extends FlImagePicker {
  const SingleImagePicker({
    super.key,
    required super.controller,
    super.disposeController = false,
    super.itemConfig = const FlImagePickerItemConfig(),
    this.onChanged,
    this.size = 60,
    this.height = 60,
    this.width = 60,
  });

  /// 资源选择变化
  final ValueChanged<ExtendedXFile?>? onChanged;

  /// [size] > [height]、[width]
  final double? size;
  final double height;
  final double width;

  /// [paths] 文件地址转换 `List<ExtendedImageModel>` 默认类型为  [AssetType.image]
  static ExtendedXFile? convertPaths(String path,
      {AssetType assetsType = AssetType.image}) {
    if (path.isNotEmpty) {
      return ExtendedXFile.fromPreviewed(path, assetsType);
    }
    return null;
  }

  /// [url] 地址转换 `List<ExtendedImageModel>` 默认类型为  [AssetType.image]
  static ExtendedXFile? convertUrl(String url,
      {AssetType assetsType = AssetType.image}) {
    if (url.isNotEmpty) {
      return ExtendedXFile.fromPreviewed(url, assetsType);
    }
    return null;
  }

  @override
  State<SingleImagePicker> createState() => _SingleImagePickerState();
}

class _SingleImagePickerState extends State<SingleImagePicker> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(listener);
  }

  void listener() {
    widget.onChanged?.call(widget.controller.entities.firstOrNull);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Widget current = widget.itemConfig.pick;
    final entities = widget.controller.entities;
    final config = widget.itemConfig;
    if (entities.isNotEmpty) {
      final entity = entities.first;
      current = buildEntity(entity);
      if (entity.type == AssetType.video) {
        current = Stack(children: [
          SizedBox.expand(child: current),
          Align(alignment: Alignment.center, child: config.play),
        ]);
      }
    }
    if (config.backgroundColor != null) {
      current = ColoredBox(color: config.backgroundColor!, child: current);
    }
    if (widget.controller.allowPick) {
      current = GestureDetector(
          onTap: () {
            widget.controller.pickActions(context, reset: true);
          },
          child: current);
    }
    current = SizedBox.fromSize(
        size: Size(widget.size ?? widget.width, widget.size ?? widget.height),
        child: current);
    if (config.borderRadius != null) {
      current = ClipRRect(borderRadius: config.borderRadius!, child: current);
    }
    return current;
  }

  Widget buildEntity(ExtendedXFile entity) {
    if (entity.realValue == null) {
      return widget.itemConfig.pick;
    }
    return FlImagePicker.imageBuilder(entity, true);
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.removeListener(listener);
    if (widget.disposeController) widget.controller.dispose();
  }
}
