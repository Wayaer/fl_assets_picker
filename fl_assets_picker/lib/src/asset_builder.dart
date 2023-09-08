import 'package:fl_assets_picker/fl_assets_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PickerFromTypeItem {
  const PickerFromTypeItem(
      {required this.fromType,
      required this.text,
      this.requestType = RequestType.common});

  /// 选择来源
  final PickerFromType fromType;

  /// 显示的文字
  final Widget text;

  /// [PickerFromType.values];
  final RequestType requestType;
}

enum PickerFromType {
  /// 从图库中选择
  gallery,

  /// 从相机拍摄
  camera,

  /// 取消
  cancel,
}

const List<PickerFromTypeItem> defaultPickerFromTypeItem = [
  PickerFromTypeItem(
      fromType: PickerFromType.gallery,
      text: Text('图库选择'),
      requestType: RequestType.image),
  PickerFromTypeItem(
      fromType: PickerFromType.camera,
      text: Text('相机拍摄'),
      requestType: RequestType.image),
  PickerFromTypeItem(
      fromType: PickerFromType.cancel,
      text: Text('取消', style: TextStyle(color: Colors.red))),
];

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

class FlPickFromTypeBuilder extends StatelessWidget {
  const FlPickFromTypeBuilder(this.list, {super.key});

  final List<PickerFromTypeItem> list;

  @override
  Widget build(BuildContext context) {
    List<Widget> actions = [];
    Widget? cancelButton;
    for (var element in list) {
      final entry = CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).maybePop(element),
          isDefaultAction: false,
          child: element.text);
      if (element.fromType != PickerFromType.cancel) {
        actions.add(entry);
      } else {
        cancelButton = entry;
      }
    }
    return CupertinoActionSheet(cancelButton: cancelButton, actions: actions);
  }
}

enum ImageCroppingQuality {
  /// 最高画质
  high,

  /// 中等
  medium,

  ///最低
  low,
}
