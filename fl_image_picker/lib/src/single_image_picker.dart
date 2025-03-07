part of 'image_picker.dart';

class SingleImagePicker extends FlImagePicker {
  const SingleImagePicker({
    super.key,
    super.enablePicker = true,
    super.actions = defaultPickerActions,
    super.renovate,
    super.itemConfig = const ImagePickerItemConfig(),
    this.onChanged,
    this.initialData,
  }) : super(maxCount: 1, maxVideoCount: 1);

  /// 默认初始资源
  final ExtendedXFile? initialData;

  /// 资源选择变化
  final ValueChanged<ExtendedXFile>? onChanged;

  /// [paths] 文件地址转换 `List<ExtendedImageModel>` 默认类型为  [ImageType.image]
  static ExtendedXFile? convertPaths(String path,
      {ImageType assetsType = ImageType.image}) {
    if (path.isNotEmpty) {
      return ExtendedXFile.fromPreviewed(path, assetsType);
    }
    return null;
  }

  /// [url] 地址转换 `List<ExtendedImageModel>` 默认类型为  [ImageType.image]
  static ExtendedXFile? convertUrl(String url,
      {ImageType assetsType = ImageType.image}) {
    if (url.isNotEmpty) {
      return ExtendedXFile.fromPreviewed(url, assetsType);
    }
    return null;
  }

  @override
  State<SingleImagePicker> createState() => _SingleImagePickerState();
}

class _SingleImagePickerState extends State<SingleImagePicker> {
  late ImagePickerController controller;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() {
    controller = ImagePickerController();
    controller.imagePicker = widget;
    if (widget.initialData != null) {
      controller.allEntity = [widget.initialData!];
    }
    controller.addListener(listener);
  }

  @override
  void didUpdateWidget(covariant SingleImagePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    controller.imagePicker = widget;
  }

  void listener() {
    if (controller.allEntity.isNotEmpty) {
      widget.onChanged?.call(controller.allEntity.first);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget current = widget.itemConfig.pick;
    final allEntity = controller.allEntity;
    final config = widget.itemConfig;
    if (allEntity.isNotEmpty) {
      final entity = allEntity.first;
      current = buildEntity(entity);
      if (entity.type == ImageType.video) {
        current = Stack(children: [
          SizedBox.expand(child: current),
          Align(alignment: Alignment.center, child: config.play),
        ]);
      }
    }
    if (config.color != null) {
      current = ColoredBox(color: config.color!, child: current);
    }
    if (widget.enablePicker) {
      current = GestureDetector(onTap: pickImage, child: current);
    }
    current = SizedBox.fromSize(size: config.size, child: current);
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

  void pickImage() async {
    FocusScope.of(context).requestFocus(FocusNode());
    controller.pickActions(context);
  }

  @override
  void dispose() {
    super.dispose();
    controller.removeListener(listener);
    controller.dispose();
  }
}
