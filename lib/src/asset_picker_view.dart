import 'dart:io';
import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:fl_assets_picker/src/asset_entry_builder.dart';
import 'package:fl_assets_picker/src/controller.dart';
import 'package:fl_assets_picker/src/preview.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

class AssetModel {
  AssetModel(
      {required this.assetType, this.path, this.file, this.url, this.bytes})
      : assert(path != null || file != null || url != null || bytes != null);

  /// [path]>[file]>[bytes]>[url]

  /// 本地资源路径
  final String? path;

  /// 内置存储文件路径
  final File? file;

  /// 网络链接
  final String? url;

  /// bytes 数组 仅支持图片预览
  final Uint8List? bytes;

  /// 资源类型  [AssetType.image]、[AssetType.video]、[AssetType.audio]、[AssetType.other]
  final AssetType assetType;
}

class ExtendedAssetModel extends AssetModel {
  ExtendedAssetModel({
    this.thumbnail,
    this.originFile,
    this.compressPath,
    this.videoCoverPath,
    this.imageCropPath,
    required this.id,
    required AssetType assetType,
    String? path,
    File? file,
    String? url,
    Uint8List? bytes,
  }) : super(
            assetType: assetType,
            path: path,
            file: file,
            url: url,
            bytes: bytes);
  final String id;

  /// 缩略图
  final AssetModel? thumbnail;

  /// 只有通过本地选择的资源才原始文件
  final File? originFile;

  /// 压缩后的路径
  /// 只有通过本地选择的资源 并添加了压缩方法
  final File? compressPath;

  /// 视频封面
  /// 只有通过本地选择的资源 并添加了获取封面的方法
  final File? videoCoverPath;

  /// 图片裁剪后的路径
  /// 只有通过本地选择的资源 并添加了裁剪的方法
  final File? imageCropPath;
}

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

typedef PickerEntryBuilder = Widget Function(AssetModel entry, int index);

enum FlAssetPickerFromType {
  /// 从图库中选择
  assets,

  /// 从相机拍摄
  camera,
}

class FlAssetPickerFromRequestTypes {
  const FlAssetPickerFromRequestTypes(
      {required this.fromType, required this.text, required this.requestTypes});

  final FlAssetPickerFromType fromType;
  final String text;
  final List<RequestType> requestTypes;
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
    this.maxSingleCount = 1,
    this.wrapConfig = const PickerWrapBuilderConfig(),
    this.wrapBuilder,
    this.fromRequestTypes = const [
      FlAssetPickerFromRequestTypes(
          fromType: FlAssetPickerFromType.assets,
          text: '图库选择',
          requestTypes: [RequestType.image, RequestType.video]),
      FlAssetPickerFromRequestTypes(
          fromType: FlAssetPickerFromType.camera,
          text: '相机拍摄',
          requestTypes: [RequestType.image, RequestType.video]),
    ],
    this.pageRouteBuilderForCameraPicker,
    this.pageRouteBuilderForAssetPicker,
    this.fromRequestTypesBuilder,
    this.entryConfig = const PickerAssetEntryBuilderConfig(),
    this.initList = const [],
    this.showDelete = true,
  }) : super(key: key);

  /// 是否显示删除按钮
  final bool showDelete;

  /// 默认初始资源
  final List<ExtendedAssetModel> initList;

  /// 请求类型
  final List<FlAssetPickerFromRequestTypes> fromRequestTypes;

  /// 资源选择变化
  final ValueChanged<List<AssetEntry>>? onChanged;

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

  /// 单次最多选择几个资源
  final int maxSingleCount;

  final PickerFromRequestTypesBuilder? fromRequestTypesBuilder;
  final bool useRootNavigator = true;
  final CameraPickerPageRouteBuilder<AssetEntity>?
      pageRouteBuilderForCameraPicker;
  final AssetPickerPageRouteBuilder<List<AssetEntity>>?
      pageRouteBuilderForAssetPicker;

  @override
  State<FlAssetPickerView> createState() => _FlAssetPickerViewState();
}

class _FlAssetPickerViewState extends State<FlAssetPickerView> {
  late FlAssetsPickerController controller;
  List<ExtendedAssetModel> allAsset = [];

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() {
    controller = widget.controller ?? FlAssetsPickerController();
    controller.addListener(listener);
  }

  void listener() {
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant FlAssetPickerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null &&
        controller.hashCode != widget.controller.hashCode) {
      controller.removeListener(listener);
      controller.dispose();
      controller = widget.controller!;
      setState(() {});
    }
  }

  List<ExtendedAssetModel> get currentAssetsEntryToAsset =>
      controller.currentAssetsEntry.map((entry) {
        AssetModel? thumbnail;
        if (entry.thumbnailDataAsync != null) {
          entry.title;
          thumbnail = AssetModel(
              assetType: AssetType.image,
              file: entry.videoCoverPath,
              bytes: entry.thumbnailDataAsync);
        }
        return ExtendedAssetModel(
            id: entry.id,
            originFile: entry.originFileAsync,
            assetType: entry.type,
            compressPath: entry.compressPath,
            videoCoverPath: entry.videoCoverPath,
            imageCropPath: entry.imageCropPath,
            file: entry.fileAsync,
            thumbnail: thumbnail);
      }).toList();

  @override
  Widget build(BuildContext context) {
    allAsset = currentAssetsEntryToAsset..insertAll(0, widget.initList);
    final children =
        allAsset.asMap().entries.map((entry) => entryBuilder(entry)).toList();
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

  Widget entryBuilder(MapEntry<int, ExtendedAssetModel> entry) {
    final assetEntry = entry.value;
    Widget builder = BuildAssetEntry(assetEntry);
    final config = widget.entryConfig;
    if (config.overlay != null ||
        assetEntry.assetType == AssetType.video ||
        assetEntry.assetType == AssetType.audio) {
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
    if (widget.showDelete) {
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

  void previewAssets(ExtendedAssetModel asset) async {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) => FlPreviewAssets(
              itemCount: allAsset.length,
              controller:
                  ExtendedPageController(initialPage: allAsset.indexOf(asset)),
              itemBuilder: (_, int index) => Center(
                  child: BuildAssetEntry(allAsset[index], isThumbnail: false)),
            ));
  }

  void pickerAsset() async {
    FocusScope.of(context).requestFocus(FocusNode());
    final assetsEntry = controller.currentAssetsEntry;
    if (assetsEntry.length >= widget.maxCount) {
      widget.errorCallback?.call('最多选择${widget.maxCount}个');
      return;
    }
    final requestType = controller.assetConfig.requestType;
    if (requestType.containsVideo()) {
      int hasVideo = 0;
      for (var element in assetsEntry) {
        if (element.type == AssetType.video) hasVideo += 1;
      }
      if (hasVideo >= widget.maxVideoCount) {
        widget.errorCallback?.call('最多添加${widget.maxVideoCount}个视频');
      }
    }
    controller.pickFromType(
        context,
        mounted: mounted,
        widget.fromRequestTypes,
        fromRequestTypesBuilder: widget.fromRequestTypesBuilder,
        useRootNavigator: widget.useRootNavigator,
        pageRouteBuilderForCameraPicker: widget.pageRouteBuilderForCameraPicker,
        pageRouteBuilderForAssetPicker: widget.pageRouteBuilderForAssetPicker);
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
    actions.add(CupertinoActionSheetAction(
        onPressed: Navigator.of(context).maybePop,
        isDefaultAction: true,
        child: const Text('取消',
            style:
                TextStyle(fontWeight: FontWeight.normal, color: Colors.red))));
    return CupertinoActionSheet(actions: actions);
  }
}
