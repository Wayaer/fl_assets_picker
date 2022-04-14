import 'dart:io';
import 'dart:typed_data';

import 'package:assets_picker/src/controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

class AssetModel {
  AssetModel(
      {required this.assetType, this.path, this.file, this.url, this.bytes})
      : assert(path != null || file != null || url != null || bytes != null);

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

class AssetOriginModel extends AssetModel {
  AssetOriginModel({
    this.thumbnail,
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

  /// 缩略图
  AssetModel? thumbnail;
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
    BuildContext context, List<AssetPickerFromRequestTypes> fromTypes);

typedef PickerErrorCallback = void Function(String msg);

typedef PickerEntryBuilder = Widget Function(AssetModel entry, int index);

enum AssetPickerFromType {
  /// 从图库中选择
  assets,

  /// 从相机拍摄
  camera,
}

class AssetPickerFromRequestTypes {
  const AssetPickerFromRequestTypes(
      {required this.fromType, required this.text, required this.requestTypes});

  final AssetPickerFromType fromType;
  final String text;
  final List<RequestType> requestTypes;
}

class AssetPickerView extends StatefulWidget {
  const AssetPickerView({
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
      AssetPickerFromRequestTypes(
          fromType: AssetPickerFromType.assets,
          text: '图库选择',
          requestTypes: [RequestType.image, RequestType.video]),
      AssetPickerFromRequestTypes(
          fromType: AssetPickerFromType.camera,
          text: '相机拍摄',
          requestTypes: [RequestType.image, RequestType.video]),
    ],
    this.pageRouteBuilderForCameraPicker,
    this.pageRouteBuilderForAssetPicker,
    this.fromRequestTypesBuilder,
    this.entryConfig = const PickerAssetEntryBuilderConfig(),
    this.initList = const [],
  }) : super(key: key);

  /// 默认初始资源
  final List<AssetOriginModel> initList;

  /// 请求类型
  final List<AssetPickerFromRequestTypes> fromRequestTypes;

  /// 资源选择变化
  final ValueChanged<List<AssetEntry>>? onChanged;

  /// 资源控制器
  final AssetsPickerController? controller;

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
  _AssetPickerViewState createState() => _AssetPickerViewState();
}

class _AssetPickerViewState extends State<AssetPickerView> {
  late AssetsPickerController controller;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() {
    controller = widget.controller ?? AssetsPickerController();
    controller.addListener(listener);
  }

  void listener() {
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant AssetPickerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null &&
        controller.hashCode != widget.controller.hashCode) {
      controller.removeListener(listener);
      controller.dispose();
      controller = widget.controller!;
      setState(() {});
    }
  }

  List<AssetOriginModel> get currentAssetsEntryToAsset =>
      controller.currentAssetsEntry.map((entry) {
        AssetModel? thumbnail;
        if (entry.thumbnailDataAsync != null) {
          File? file;
          if (entry.type == AssetType.video && entry.videoCoverPath != null) {
            file = File(entry.videoCoverPath!);
          }
          thumbnail = AssetModel(
              assetType: AssetType.image,
              file: file,
              bytes: entry.thumbnailDataAsync);
        }
        return AssetOriginModel(
            assetType: entry.type, file: entry.fileAsync, thumbnail: thumbnail);
      }).toList();

  @override
  Widget build(BuildContext context) {
    final assets = currentAssetsEntryToAsset..insertAll(0, widget.initList);
    final children =
        assets.asMap().entries.map((entry) => entryBuilder(entry)).toList();
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

  Widget entryBuilder(MapEntry<int, AssetOriginModel> entry) {
    final assetEntry = entry.value;
    Widget builder = _BuildAssetEntry(assetEntry);
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
          child: builder, borderRadius: BorderRadius.circular(config.radius!));
    }
    return widget.entryBuilder?.call(entry.value, entry.key) ?? builder;
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
    showSelectType();
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
          child: icon, borderRadius: BorderRadius.circular(config.radius!));
    }
    return GestureDetector(
        onTap: pickerAsset, child: widget.pickerIconBuilder?.call() ?? icon);
  }

  void showSelectType() async {
    final fromRequestTypes = widget.fromRequestTypes;
    AssetPickerFromRequestTypes? type;
    if (fromRequestTypes.length == 1) {
      type = fromRequestTypes.first;
    } else {
      type = await showModalBottomSheet<AssetPickerFromRequestTypes?>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) =>
              widget.fromRequestTypesBuilder?.call(context, fromRequestTypes) ??
              _AlertSelectTypeChoice(fromRequestTypes));
    }

    if (type == null) return;
    switch (type.fromType) {
      case AssetPickerFromType.assets:
        controller.pickAssets(context,
            useRootNavigator: widget.useRootNavigator,
            pageRouteBuilder: widget.pageRouteBuilderForAssetPicker);
        break;
      case AssetPickerFromType.camera:
        controller.pickFromCamera(context,
            useRootNavigator: widget.useRootNavigator,
            pageRouteBuilder: widget.pageRouteBuilderForCameraPicker);
        break;
    }
  }

  @override
  void dispose() {
    super.dispose();
    controller.removeListener(listener);
    controller.dispose();
  }
}

class _BuildAssetEntry extends StatelessWidget {
  const _BuildAssetEntry(this.entry, {Key? key, this.isThumbnail = true})
      : super(key: key);
  final AssetOriginModel entry;
  final bool isThumbnail;

  @override
  Widget build(BuildContext context) {
    Widget current = const SizedBox();
    ImageProvider? thumbnailProvider;
    if (entry.thumbnail != null) {
      thumbnailProvider = getImageProvider(entry.thumbnail!);
    }
    switch (entry.assetType) {
      case AssetType.other:
        if (isThumbnail && thumbnailProvider != null) {
          current = Image(fit: BoxFit.cover, image: thumbnailProvider);
        }
        break;
      case AssetType.image:
        current = Image(
            fit: BoxFit.cover,
            image: isThumbnail && thumbnailProvider != null
                ? thumbnailProvider
                : getImageProvider(entry));
        break;
      case AssetType.video:
        print(entry.file?.path);
        if (isThumbnail && thumbnailProvider != null) {
          current = Image(fit: BoxFit.cover, image: thumbnailProvider);
        }
        break;
      case AssetType.audio:
        if (isThumbnail && thumbnailProvider != null) {
          current = Image(fit: BoxFit.cover, image: thumbnailProvider);
        }
        break;
    }
    return current;
  }

  ImageProvider getImageProvider(AssetModel asset) {
    ImageProvider? provider;
    if (asset.path != null) {
      provider = AssetImage(asset.path!);
    } else if (asset.file != null) {
      provider = FileImage(asset.file!);
    } else if (asset.bytes != null) {
      provider = MemoryImage(asset.bytes!);
    } else if (asset.url != null) {
      provider = NetworkImage(asset.url!);
    }
    return provider!;
  }
}

class _AlertSelectTypeChoice extends StatelessWidget {
  const _AlertSelectTypeChoice(this.list, {Key? key}) : super(key: key);

  final List<AssetPickerFromRequestTypes> list;

  @override
  Widget build(BuildContext context) {
    final actions = list
        .map((entry) => CupertinoActionSheetAction(
            child: Text(entry.text),
            onPressed: () => Navigator.of(context).maybePop(entry),
            isDefaultAction: true))
        .toList();
    actions.add(CupertinoActionSheetAction(
        child: const Text('取消'),
        onPressed: Navigator.of(context).maybePop,
        isDefaultAction: true));
    return CupertinoActionSheet(actions: actions);
  }
}
