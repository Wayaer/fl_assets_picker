import 'package:fl_image_picker/fl_image_picker.dart';
import 'package:flutter/material.dart';

const List<PickerFromTypeItem> defaultPickerFromTypeItem = [
  PickerFromTypeItem(fromType: PickerFromType.image, text: Text('选择图片')),
  PickerFromTypeItem(fromType: PickerFromType.video, text: Text('选择视频')),
  PickerFromTypeItem(fromType: PickerFromType.takePictures, text: Text('相机拍照')),
  PickerFromTypeItem(fromType: PickerFromType.recording, text: Text('相机录像')),
  PickerFromTypeItem(
      fromType: PickerFromType.cancel,
      text: Text('取消', style: TextStyle(color: Colors.red))),
];

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
