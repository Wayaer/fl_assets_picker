import 'dart:io';

import 'package:fl_assets_picker/fl_assets_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PickerAssetEntryBuilderConfig {
  const PickerAssetEntryBuilderConfig(
      {this.decoration,
      this.size = const Size(65, 65),
      this.pickerIcon =
          const Icon(Icons.add, size: 30, color: Color(0x804D4D4D)),
      this.color,
      this.borderColor = const Color(0x804D4D4D),
      this.overlay,
      this.playIcon = const Icon(Icons.play_circle_outline,
          size: 30, color: Color(0x804D4D4D)),
      this.radius});

  final Decoration? decoration;
  final Size size;
  final Color? color;
  final Color borderColor;
  final double? radius;
  final Icon playIcon;
  final Widget? overlay;
  final Icon pickerIcon;
}

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

typedef PickerFromRequestTypesBuilder = Widget Function(
    BuildContext context, List<FlAssetPickerFromRequestTypes> fromTypes);

typedef PickerErrorCallback = void Function(String msg);

typedef PickerEntryBuilder = Widget Function(
    ExtendedAssetEntity entry, int index);

enum FlAssetPickerFromType {
  /// 从图库中选择
  assets,

  /// 从相机拍摄
  camera,
}

class FlAssetPickerFromRequestTypes {
  const FlAssetPickerFromRequestTypes(
      {required this.fromType, required this.text, this.requestType});

  final FlAssetPickerFromType fromType;
  final String text;

  /// [FlAssetPickerFromType.values];
  final RequestType? requestType;
}

class FlAssetPickerView extends StatefulWidget {
  const FlAssetPickerView({
    Key? key,
    this.onChanged,
    this.controller,
    this.enablePicker = true,
    this.pickerIconBuilder,
    this.entryBuilder,
    this.errorCallback,
    this.maxVideoCount = 1,
    this.maxCount = 9,
    this.wrapConfig = const PickerWrapBuilderConfig(),
    this.wrapBuilder,
    this.fromRequestTypes = const [
      FlAssetPickerFromRequestTypes(
          fromType: FlAssetPickerFromType.assets,
          text: '图库选择',
          requestType: RequestType.common),
      FlAssetPickerFromRequestTypes(
          fromType: FlAssetPickerFromType.camera,
          text: '相机拍摄',
          requestType: RequestType.common),
    ],
    this.pageRouteBuilderForCameraPicker,
    this.pageRouteBuilderForAssetPicker,
    this.fromRequestTypesBuilder,
    this.entryConfig = const PickerAssetEntryBuilderConfig(),
    this.initialData = const [],
    this.allowDelete = true,
  }) : super(key: key);

  /// 是否显示删除按钮
  final bool allowDelete;

  /// 默认初始资源
  final List<ExtendedAssetEntity> initialData;

  /// 请求类型
  final List<FlAssetPickerFromRequestTypes> fromRequestTypes;

  /// 资源选择变化
  final ValueChanged<List<ExtendedAssetEntity>>? onChanged;

  /// 资源控制器
  final FlAssetsPickerController? controller;

  final PickerWrapBuilderConfig wrapConfig;

  final PickerWrapBuilder? wrapBuilder;

  /// 是否开始 资源选择
  final bool enablePicker;

  /// 资源选择 icon 自定义构造
  final PickerIconBuilder? pickerIconBuilder;

  /// 资源渲染子元素自定义构造
  final PickerEntryBuilder? entryBuilder;

  ///
  final PickerAssetEntryBuilderConfig entryConfig;

  /// 错误消息回调
  final PickerErrorCallback? errorCallback;

  /// 最大选择视频数量
  final int maxVideoCount;

  /// 最多选择几个资源
  final int maxCount;

  final PickerFromRequestTypesBuilder? fromRequestTypesBuilder;
  final bool useRootNavigator = true;
  final CameraPickerPageRoute<AssetEntity> Function(Widget picker)?
      pageRouteBuilderForCameraPicker;
  final AssetPickerPageRouteBuilder<List<AssetEntity>>?
      pageRouteBuilderForAssetPicker;

  @override
  State<FlAssetPickerView> createState() => _FlAssetPickerViewState();

  /// [paths] 文件地址转换 List<ExtendedAssetModel> 默认类型为  [AssetType.image]
  static List<ExtendedAssetEntity> convertFiles(List<File> paths,
      {AssetType assetsType = AssetType.image}) {
    List<ExtendedAssetEntity> list = [];
    for (var element in paths) {
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
        list.add(
            ExtendedAssetEntity.fromPath(path: element, assetType: assetsType));
      }
    }
    return list;
  }

  /// [url] 地址转换 List<ExtendedAssetModel> 默认类型为  [AssetType.image]
  static List<ExtendedAssetEntity> convertUrls(String url,
      {AssetType assetsType = AssetType.image}) {
    List<ExtendedAssetEntity> list = [];
    if (url.isEmpty) return list;
    if (url.contains(',')) {
      final urls = url.split(',');
      for (var element in urls) {
        if (element.isNotEmpty) {
          list.add(
              ExtendedAssetEntity.fromUrl(url: element, assetType: assetsType));
        }
      }
    } else {
      list.add(ExtendedAssetEntity.fromUrl(assetType: assetsType, url: url));
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

class _FlAssetPickerViewState extends State<FlAssetPickerView> {
  late FlAssetsPickerController controller;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() {
    controller = widget.controller ?? FlAssetsPickerController();
    controller.setWidget(widget);
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
        .map((entry) => entryBuilder(entry))
        .toList();
    if (widget.enablePicker) children.add(pickerBuilder);
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

  Widget entryBuilder(MapEntry<int, ExtendedAssetEntity> entry) {
    final assetEntry = entry.value;
    Widget builder = BuildAssetEntry(assetEntry);
    final config = widget.entryConfig;
    if (config.overlay != null ||
        assetEntry.type == AssetType.video ||
        assetEntry.type == AssetType.audio) {
      builder = Stack(children: [
        builder,
        if (config.overlay != null) config.overlay!,
        Align(alignment: Alignment.center, child: config.playIcon),
      ]);
    }
    builder = Container(
        width: config.size.width,
        height: config.size.height,
        decoration: config.decoration,
        child: builder);
    if (config.color != null) {
      builder = ColoredBox(color: config.color!, child: builder);
    }
    if (config.radius != null) {
      builder = ClipRRect(
          borderRadius: BorderRadius.circular(config.radius!), child: builder);
    }

    builder = GestureDetector(
        onTap: () => previewAssets(entry.value),
        child: widget.entryBuilder?.call(entry.value, entry.key) ?? builder);
    if (widget.allowDelete) {
      builder = Stack(children: [
        builder,
        Positioned(
            right: 2,
            top: 2,
            child: GestureDetector(
              onTap: () => controller.deleteAsset(assetEntry.id),
              child: Container(
                  decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      shape: BoxShape.circle),
                  padding: const EdgeInsets.all(2),
                  child:
                      const Icon(Icons.clear, size: 12, color: Colors.white)),
            ))
      ]);
    }
    return builder;
  }

  void previewAssets(ExtendedAssetEntity asset) async {
    final currentAssetsEntry = controller.allAssetEntity;
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) => FlPreviewAssets(
              itemCount: currentAssetsEntry.length,
              controller: ExtendedPageController(
                  initialPage: currentAssetsEntry.indexOf(asset)),
              itemBuilder: (_, int index) => Center(
                  child: BuildAssetEntry(currentAssetsEntry[index],
                      isThumbnail: false)),
            ));
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

  Widget get pickerBuilder {
    final config = widget.entryConfig;
    Widget icon = Container(
        width: config.size.width,
        height: config.size.height,
        decoration: config.decoration ??
            BoxDecoration(
                borderRadius: BorderRadius.circular(config.radius ?? 0),
                border: Border.all(color: config.borderColor)),
        child: config.pickerIcon);
    if (config.color != null) {
      icon = ColoredBox(color: config.color!, child: icon);
    }
    if (config.radius != null) {
      icon = ClipRRect(
          borderRadius: BorderRadius.circular(config.radius!), child: icon);
    }
    return GestureDetector(
        onTap: pickerAsset, child: widget.pickerIconBuilder?.call() ?? icon);
  }

  @override
  void dispose() {
    super.dispose();
    controller.removeListener(listener);
    controller.dispose();
  }
}

class PickFromTypeBuild extends StatelessWidget {
  const PickFromTypeBuild(this.list, {Key? key}) : super(key: key);

  final List<FlAssetPickerFromRequestTypes> list;

  @override
  Widget build(BuildContext context) {
    final actions = list
        .map((entry) => CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).maybePop(entry),
            isDefaultAction: true,
            child: Text(entry.text,
                style: const TextStyle(fontWeight: FontWeight.normal))))
        .toList();
    return CupertinoActionSheet(
        cancelButton: CupertinoActionSheetAction(
            onPressed: Navigator.of(context).maybePop,
            isDefaultAction: true,
            child: const Text('取消',
                style: TextStyle(
                    fontWeight: FontWeight.normal, color: Colors.red))),
        actions: actions);
  }
}
