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
  final ValueChanged<FlXFile?>? onChanged;

  /// [size] > [height]、[width]
  final double? size;
  final double height;
  final double width;

  /// [paths] 文件地址转换 `List<ExtendedImageModel>` 默认类型为  [AssetType.image]
  static FlXFile? convertPaths(String path,
      {AssetType assetsType = AssetType.image}) {
    if (path.isNotEmpty) {
      return FlXFile.fromPreviewed(path, assetsType);
    }
    return null;
  }

  /// [url] 地址转换 `List<ExtendedImageModel>` 默认类型为  [AssetType.image]
  static FlXFile? convertUrl(String url,
      {AssetType assetsType = AssetType.image}) {
    if (url.isNotEmpty) {
      return FlXFile.fromPreviewed(url, assetsType);
    }
    return null;
  }

  @override
  State<SingleImagePicker> createState() => _SingleImagePickerState();
}

class _SingleImagePickerState extends FlImagePickerState<SingleImagePicker> {
  @override
  void listener() {
    widget.onChanged?.call(widget.controller.entities.firstOrNull);
    super.listener();
  }

  @override
  Widget build(BuildContext context) {
    Widget current = widget.itemConfig.pick;
    final entities = widget.controller.entities;
    if (entities.isNotEmpty) {
      final file = entities.first;
      current = buildEntity(file);
      current = buildVideo(file, current);
    }
    current = buildBackgroundColor(current);
    current = SizedBox.fromSize(
        size: Size(widget.size ?? widget.width, widget.size ?? widget.height),
        child: current);
    current = buildBorderRadius(current);
    current = buildPickActions(current, reset: true);
    return current;
  }

  Widget buildEntity(FlXFile file) {
    if (file.realValue == null) {
      return widget.itemConfig.pick;
    }
    return FlImagePicker.imageBuilder(file, true);
  }
}
