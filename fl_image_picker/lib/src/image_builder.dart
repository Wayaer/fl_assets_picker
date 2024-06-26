import 'package:fl_image_picker/fl_image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PickerActions {
  const PickerActions({required this.action, required this.text});

  /// 来源
  final PickerOptionalActions action;

  /// 显示的文字
  final Widget text;
}

enum PickerOptionalActions {
  /// 仅图片
  image,

  /// 仅视频
  video,

  /// 拍照
  takePictures,

  /// 相机录像
  recording,

  /// 取消
  cancel,
}

const List<PickerActions> defaultPickerActions = [
  PickerActions(
      action: PickerOptionalActions.image, text: Text('选择图片')),
  PickerActions(
      action: PickerOptionalActions.video, text: Text('选择视频')),
  PickerActions(
      action: PickerOptionalActions.takePictures, text: Text('相机拍照')),
  PickerActions(
      action: PickerOptionalActions.recording, text: Text('相机录像')),
  PickerActions(
      action: PickerOptionalActions.cancel,
      text: Text('取消', style: TextStyle(color: Colors.red))),
];

typedef DeletionConfirmation = Future<bool> Function(ExtendedXFile entity);

class ImagePickerItemConfig {
  const ImagePickerItemConfig(
      {this.color,
      this.borderRadius = const BorderRadius.all(Radius.circular(8)),
      this.size = const Size(65, 65),
      this.pick = const DefaultPickIcon(),
      this.delete = const DefaultDeleteIcon(),
      this.deletionConfirmation,
      this.play = const Icon(Icons.play_circle_outline,
          size: 30, color: Color(0x804D4D4D))});

  final Color? color;
  final Size size;
  final BorderRadiusGeometry? borderRadius;

  /// 视频预览 播放 icon
  final Widget play;

  /// 添加 框的
  final Widget pick;

  /// 删除按钮
  final Widget delete;

  /// 删除确认
  final DeletionConfirmation? deletionConfirmation;
}

class DefaultPickIcon extends StatelessWidget {
  const DefaultPickIcon(
      {super.key,
      this.borderRadius = const BorderRadius.all(Radius.circular(8)),
      this.borderColor = const Color(0x804D4D4D),
      this.iconColor = const Color(0x804D4D4D),
      this.backgroundColor,
      this.icon,
      this.size = 30});

  final BorderRadiusGeometry? borderRadius;
  final Color? borderColor;
  final Color iconColor;
  final Color? backgroundColor;
  final double size;
  final Widget? icon;

  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          border: borderColor == null ? null : Border.all(color: borderColor!),
          borderRadius: borderRadius),
      child: icon ?? Icon(Icons.add, size: size, color: iconColor));
}

class DefaultDeleteIcon extends StatelessWidget {
  const DefaultDeleteIcon(
      {super.key,
      this.icon,
      this.iconColor = Colors.white,
      this.backgroundColor = Colors.redAccent,
      this.size = 12});

  final Widget? icon;
  final Color iconColor;
  final Color backgroundColor;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      padding: const EdgeInsets.all(2),
      child: icon ?? Icon(Icons.clear, size: size, color: iconColor));
}

class FlPickerOptionalActionsBuilder extends StatelessWidget {
  const FlPickerOptionalActionsBuilder(this.list, {super.key});

  final List<PickerActions> list;

  @override
  Widget build(BuildContext context) {
    List<Widget> actions = [];
    Widget? cancelButton;
    for (var element in list) {
      final entry = CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).maybePop(element),
          isDefaultAction: false,
          child: element.text);
      if (element.action != PickerOptionalActions.cancel) {
        actions.add(entry);
      } else {
        cancelButton = entry;
      }
    }
    return CupertinoActionSheet(cancelButton: cancelButton, actions: actions);
  }
}
