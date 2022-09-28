import 'package:fl_assets_picker/fl_assets_picker.dart';
import 'package:flutter/material.dart';

typedef PickerFromTypeBuilder = Widget Function(
    BuildContext context, List<PickerFromTypeConfig> fromTypes);

class PickerAssetEntryBuilderConfig {
  const PickerAssetEntryBuilderConfig(
      {this.color,
      this.borderRadius,
      this.size = const Size(65, 65),
      this.pickerIcon =
          const Icon(Icons.add, size: 30, color: Color(0x804D4D4D)),
      this.pickerBorderColor = const Color(0x804D4D4D),
      this.deleteColor = Colors.redAccent,
      this.overlay,
      this.playIcon = const Icon(Icons.play_circle_outline,
          size: 30, color: Color(0x804D4D4D))});

  final Color? color;
  final Size size;
  final BorderRadiusGeometry? borderRadius;
  final Widget playIcon;
  final Widget? overlay;
  final Widget pickerIcon;

  /// 添加框 borderColor
  final Color pickerBorderColor;
  final Color deleteColor;
}

abstract class FlAssetsPicker extends StatefulWidget {
  const FlAssetsPicker(
      {super.key,
      required this.maxVideoCount,
      required this.maxCount,
      required this.fromRequestTypes,
      this.enablePicker = true,
      this.errorCallback,
      this.fromRequestTypesBuilder,
      this.pageRouteBuilderForCameraPicker,
      this.pageRouteBuilderForAssetPicker});

  /// 最大选择视频数量
  final int maxVideoCount;

  /// 最多选择几个资源
  final int maxCount;

  /// 请求类型
  final List<PickerFromTypeConfig> fromRequestTypes;

  /// 是否开启 资源选择
  final bool enablePicker;

  /// 错误消息回调
  final PickerErrorCallback? errorCallback;

  /// 选择框 自定义
  final PickerFromTypeBuilder? fromRequestTypesBuilder;

  final bool useRootNavigator = true;
  final CameraPickerPageRoute<AssetEntity> Function(Widget picker)?
      pageRouteBuilderForCameraPicker;
  final AssetPickerPageRouteBuilder<List<AssetEntity>>?
      pageRouteBuilderForAssetPicker;
}
