import 'package:fl_assets_picker/fl_assets_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum ImageCroppingQuality {
  /// 最高画质
  high,

  /// 中等
  medium,

  ///最低
  low,
}

enum PickerFromType {
  /// 从图库中选择
  assets,

  /// 从相机拍摄
  camera,

  /// 取消
  cancel,
}

class PickerFromTypeConfig {
  const PickerFromTypeConfig(
      {required this.fromType, required this.text, this.requestType});

  /// 来源
  final PickerFromType fromType;

  /// 显示的文字
  final Widget text;

  /// [PickerFromType.values];
  final RequestType? requestType;
}

typedef PickerFromTypeBuilder = Widget Function(
    BuildContext context, List<PickerFromTypeConfig> fromTypes);

/// show 选择弹窗
Future<PickerFromTypeConfig?> showPickerFromType(
  BuildContext context,
  List<PickerFromTypeConfig> fromTypes, {
  PickerFromTypeBuilder? fromRequestTypesBuilder,
}) async {
  PickerFromTypeConfig? type;
  if (fromTypes.length == 1 &&
      fromTypes.first.fromType != PickerFromType.cancel) {
    type = fromTypes.first;
  } else {
    type = await showModalBottomSheet<PickerFromTypeConfig?>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) =>
            fromRequestTypesBuilder?.call(context, fromTypes) ??
            _PickFromTypeBuilderWidget(fromTypes));
  }
  return type;
}

class _PickFromTypeBuilderWidget extends StatelessWidget {
  const _PickFromTypeBuilderWidget(this.list, {Key? key}) : super(key: key);

  final List<PickerFromTypeConfig> list;

  @override
  Widget build(BuildContext context) {
    List<Widget> actions = [];
    Widget? cancelButton;
    for (var element in list) {
      final entry = CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).maybePop(element),
          isDefaultAction: true,
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
