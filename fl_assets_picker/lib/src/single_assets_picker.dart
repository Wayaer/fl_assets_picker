part of '../fl_assets_picker.dart';

class SingleAssetsPicker extends FlAssetsPicker {
  const SingleAssetsPicker({
    super.key,
    required super.controller,
    super.disposeController = false,
    super.itemConfig = const FlAssetsPickerItemConfig(),
    this.onChanged,
    this.height = 60,
    this.width = 60,
  });

  /// 资源选择变化
  final ValueChanged<FlAssetEntity?>? onChanged;

  final double height;
  final double width;

  /// [paths] 文件地址转换 `FlAssetEntity` 默认类型为  [AssetType.image]
  static FlAssetEntity? convertPath(String path, {AssetType assetType = AssetType.image}) {
    if (path.isNotEmpty) {
      return FlAssetEntity.fromPreviewed(previewed: path, assetType: assetType);
    }
    return null;
  }

  /// [url] 地址转换 `FlAssetEntity` 默认类型为  [AssetType.image]
  static FlAssetEntity? convertUrl(String url, {AssetType assetType = AssetType.image}) {
    if (url.isNotEmpty) {
      return FlAssetEntity.fromPreviewed(previewed: url, assetType: assetType);
    }
    return null;
  }

  @override
  State<SingleAssetsPicker> createState() => _SingleAssetsPickerState();
}

class _SingleAssetsPickerState extends FlAssetsPickerState<SingleAssetsPicker> {
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
      final asset = entities.first;
      current = buildEntity(asset);
      current = buildVideo(asset, current);
    }
    current = buildBackgroundColor(current);
    current = SizedBox.fromSize(size: Size(widget.width, widget.height), child: current);
    current = buildBorderRadius(current);
    current = buildPickActions(current, reset: true);
    return current;
  }

  Widget buildEntity(FlAssetEntity asset) {
    if (asset.realValue == null) {
      return widget.itemConfig.pick;
    }
    return widget.controller.buildPreview(asset, true);
  }
}
