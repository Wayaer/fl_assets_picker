part of '../fl_assets_picker.dart';

class PickerActionOptions {
  const PickerActionOptions({required this.action, required this.text});

  /// 选择来源
  final PickerAction action;

  /// 显示的文字
  final Widget text;
}

List<PickerActionOptions> get defaultPickerActionOptions => [
      PickerActionOptions(action: PickerAction.gallery, text: Text('图库选择')),
      PickerActionOptions(action: PickerAction.camera, text: Text('相机拍摄')),
      PickerActionOptions(
          action: PickerAction.cancel,
          text: Text('取消', style: TextStyle(color: Colors.red))),
    ];

/// 图片选择器 item 配置
class FlAssetsPickerItemConfig {
  const FlAssetsPickerItemConfig(
      {this.backgroundColor,
      this.borderRadius = const BorderRadius.all(Radius.circular(8)),
      this.pick = const FlAssetsPickerPickIcon(),
      this.delete = const FlAssetsPickerDeleteIcon(),
      this.play = const Icon(Icons.play_circle_outline,
          size: 30, color: Color(0x804D4D4D))});

  /// 颜色
  final Color? backgroundColor;

  /// 圆角
  final BorderRadiusGeometry? borderRadius;

  /// 视频预览 播放 icon
  final Widget play;

  /// 添加选择 item
  final Widget pick;

  /// 删除按钮
  final Widget delete;
}

/// Image picker icon
class FlAssetsPickerIcon extends StatelessWidget {
  const FlAssetsPickerIcon({
    super.key,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
    this.borderColor,
    this.borderWidth = 1,
    required this.iconColor,
    this.backgroundColor,
    required this.size,
    this.icon,
    this.iconData,
    this.padding,
    this.alignment,
  });

  /// 圆角
  final BorderRadiusGeometry? borderRadius;

  /// 边框
  final Color? borderColor;

  /// 边框
  final double borderWidth;

  /// 图标
  final Color iconColor;

  /// 图标
  final IconData? iconData;

  /// 图标
  final Widget? icon;

  /// 背景
  final Color? backgroundColor;

  /// size
  final double size;

  /// padding
  final EdgeInsetsGeometry? padding;

  /// 形状
  final BoxShape shape;

  /// 对齐方式
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: alignment,
        decoration: BoxDecoration(
            color: backgroundColor,
            shape: shape,
            border: borderColor == null
                ? null
                : Border.all(color: borderColor!, width: borderWidth),
            borderRadius: borderRadius),
        padding: padding,
        child: icon ?? Icon(iconData, size: size, color: iconColor));
  }
}

/// Pick icon
class FlAssetsPickerPickIcon extends FlAssetsPickerIcon {
  const FlAssetsPickerPickIcon(
      {super.key,
      super.icon,
      super.borderRadius = const BorderRadius.all(Radius.circular(8)),
      super.borderColor = const Color(0x804D4D4D),
      super.iconColor = const Color(0x804D4D4D),
      super.backgroundColor,
      super.shape,
      super.iconData = Icons.add,
      super.size = 30})
      : super(alignment: Alignment.center);
}

/// Delete icon
class FlAssetsPickerDeleteIcon extends FlAssetsPickerIcon {
  const FlAssetsPickerDeleteIcon(
      {super.key,
      super.icon,
      super.iconColor = Colors.white,
      super.backgroundColor = Colors.redAccent,
      super.size = 12,
      super.shape = BoxShape.circle,
      super.iconData = Icons.close,
      super.padding = const EdgeInsets.all(2)});
}

/// [PickerActionOptions] Action builder
class FlPickerActionBuilder extends StatelessWidget {
  const FlPickerActionBuilder(this.actions, {super.key});

  final List<PickerActionOptions> actions;

  @override
  Widget build(BuildContext context) {
    List<Widget> list = [];
    Widget? cancel;
    for (var element in actions) {
      final entry = CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).maybePop(element),
          isDefaultAction: false,
          child: element.text);
      if (element.action != PickerAction.cancel) {
        list.add(entry);
      } else {
        cancel = entry;
      }
    }
    return CupertinoActionSheet(cancelButton: cancel, actions: list);
  }
}

/// 图片预览器
class FlAssetsPickerPreviewModal extends StatelessWidget {
  const FlAssetsPickerPreviewModal({
    super.key,
    required this.child,
    this.close,
    this.overlay,
    this.backgroundColor = Colors.black87,
  });

  final Widget child;

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
          SizedBox.expand(child: child),
          if (overlay != null) SizedBox.expand(child: overlay!),
          Positioned(
              right: 6,
              top: MediaQuery.of(context).viewPadding.top,
              child: close ?? const CloseButton(color: Colors.white)),
        ]));
  }
}

/// 图片预览器
class FlAssetsPickerPreviewPageView extends StatelessWidget {
  const FlAssetsPickerPreviewPageView(
      {super.key, required this.entities, this.initialIndex = 0});

  /// 资源列表
  final List<FlAssetEntity> entities;

  /// 初始索引
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    final length = entities.length;
    final initialPage = min(length, initialIndex);
    return FlAssetsPickerPreviewModal(
        child: PageView.builder(
            controller: PageController(initialPage: initialPage),
            itemCount: length,
            itemBuilder: (_, int index) {
              return Center(
                  child: FlAssetsPicker.assetBuilder(entities[index], false));
            }));
  }
}
