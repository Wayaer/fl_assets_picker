part of '../fl_image_picker.dart';

class PickerActionOptions {
  const PickerActionOptions({required this.action, required this.text});

  /// 来源
  final PickerAction action;

  /// 显示的文字
  final Widget text;
}

List<PickerActionOptions> get defaultImagePickerActionOptions => [
      PickerActionOptions(action: PickerAction.image, text: Text('单图片选择')),
      PickerActionOptions(action: PickerAction.multiImage, text: Text('多图片选择')),
      PickerActionOptions(action: PickerAction.video, text: Text('单视频选择')),
      PickerActionOptions(action: PickerAction.media, text: Text('单媒体选择')),
      PickerActionOptions(action: PickerAction.multiMedia, text: Text('多媒体选择')),
      PickerActionOptions(action: PickerAction.takePicture, text: Text('相机拍照')),
      PickerActionOptions(
          action: PickerAction.cameraRecording, text: Text('相机录像')),
      PickerActionOptions(
          action: PickerAction.cancel,
          text: Text('取消', style: TextStyle(color: Colors.red))),
    ];

/// 图片选择器 item 配置
class FlImagePickerItemConfig {
  const FlImagePickerItemConfig(
      {this.backgroundColor,
      this.borderRadius = const BorderRadius.all(Radius.circular(8)),
      this.pick = const FlImagePickerPickIcon(),
      this.delete = const FlImagePickerDeleteIcon(),
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
class FlImagePickerIcon extends StatelessWidget {
  const FlImagePickerIcon({
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
class FlImagePickerPickIcon extends FlImagePickerIcon {
  const FlImagePickerPickIcon(
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
class FlImagePickerDeleteIcon extends FlImagePickerIcon {
  const FlImagePickerDeleteIcon(
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
