import 'package:assets_picker/src/controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

class PickerIconConfig {
  const PickerIconConfig(
      {this.color = const Color(0x204D4D4D),
      this.icon = const Icon(Icons.add, size: 30, color: Color(0x804D4D4D)),
      this.radius = 6,
      this.decoration,
      this.size = const Size(65, 65)});

  final Color color;
  final double radius;
  final Icon icon;
  final Size size;
  final Decoration? decoration;
}

class PickerAssetEntryBuilderConfig {
  const PickerAssetEntryBuilderConfig(
      {this.decoration,
      this.size = const Size(65, 65),
      this.color,
      this.overlay,
      this.playIcon = const Icon(Icons.play_circle_outline,
          size: 30, color: Color(0x804D4D4D)),
      this.radius});

  final Decoration? decoration;
  final Size size;
  final Color? color;
  final double? radius;
  final Icon playIcon;
  final Widget? overlay;
}

typedef PickerIconBuilder = Widget Function();
typedef PickerFromRequestTypesBuilder = Widget Function(
    BuildContext context, List<AssetPickerFromRequestTypes> fromTypes);
typedef PickerErrorCallback = void Function(String msg);
typedef PickerEntryBuilder = Widget Function(AssetEntry entry, int index);

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
  const AssetPickerView(
      {Key? key,
      this.onChanged,
      this.controller,
      this.enablePicker = true,
      this.pickerIconConfig = const PickerIconConfig(),
      this.pickerIconBuilder,
      this.entryBuilder,
      this.errorCallback,
      this.maxVideoCount = 1,
      this.maxCount = 9,
      this.maxSingleCount = 1,
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
      this.entryConfig = const PickerAssetEntryBuilderConfig()})
      : super(key: key);

  /// 请求类型
  final List<AssetPickerFromRequestTypes> fromRequestTypes;

  /// 资源选择变化
  final ValueChanged<List<AssetEntry>>? onChanged;

  /// 资源控制器
  final AssetsPickerController? controller;

  /// 是否开始 资源选择
  final bool enablePicker;

  ///  资源选择 icon 配置
  final PickerIconConfig pickerIconConfig;

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

  @override
  Widget build(BuildContext context) {
    final children = controller.currentAssetsEntry
        .asMap()
        .entries
        .map((entry) => entryBuilder(entry))
        .toList();
    if (widget.enablePicker) children.add(pickerBuilder);
    return Container(
        margin: const EdgeInsets.all(10),
        width: double.infinity,
        child: Wrap(
            direction: Axis.horizontal,
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.start,
            runSpacing: 16,
            spacing: 16,
            children: children));
  }

  Widget entryBuilder(MapEntry<int, AssetEntry> entry) {
    final assetEntry = entry.value;
    Widget builder = buildAssetEntry(assetEntry);
    final config = widget.entryConfig;
    if (config.overlay != null ||
        assetEntry.type == AssetType.video ||
        assetEntry.type == AssetType.audio) {
      builder = Stack(children: [
        builder,
        if (config.overlay != null) config.overlay!,
        config.playIcon,
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

  Widget buildAssetEntry(AssetEntry entry, {bool isThumbnail = true}) {
    Widget current = const SizedBox();
    switch (entry.type) {
      case AssetType.other:
        break;
      case AssetType.image:
        current = Image(
            fit: BoxFit.cover,
            image: AssetEntityImageProvider(entry, isOriginal: isThumbnail));
        break;
      case AssetType.video:
        final thumbnailData = entry.thumbnailDataAsync;
        if (thumbnailData != null) {
          current = Image(image: MemoryImage(thumbnailData));
        }
        break;
      case AssetType.audio:
        final thumbnailData = entry.thumbnailDataAsync;
        if (thumbnailData != null) {
          current = Image(image: MemoryImage(thumbnailData));
        }
        break;
    }
    return current;
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
    final config = widget.pickerIconConfig;
    final icon = widget.pickerIconBuilder?.call() ??
        Container(
            width: config.size.width,
            height: config.size.height,
            decoration: config.decoration ??
                BoxDecoration(
                    border: Border.all(color: config.color),
                    borderRadius: BorderRadius.circular(config.radius)),
            child: config.icon);
    return GestureDetector(onTap: pickerAsset, child: icon);
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
