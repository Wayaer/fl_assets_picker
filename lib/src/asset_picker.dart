import 'dart:math';

import 'package:fl_assets_picker/fl_assets_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

bool get _isMobile => _isAndroid || _isIOS;

typedef FlAssetsPickerGetPermission = Future<bool> Function(
    PickerFromType fromType);

typedef FlAssetsPickerErrorCallback = void Function(String erroe);

typedef PickerFromTypeBuilder = Widget Function(
    BuildContext context, List<PickerFromTypeConfig> fromTypes);

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

class PickerAssetEntryBuilderConfig {
  const PickerAssetEntryBuilderConfig(
      {this.color,
      this.fit = BoxFit.cover,
      this.previewFit = BoxFit.contain,
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

  /// 视频预览 播放 icon
  final Widget playIcon;

  /// pick 框的 icon
  final Widget pickerIcon;
  final Widget? overlay;

  final BoxFit fit;
  final BoxFit previewFit;

  /// 添加框 borderColor
  final Color pickerBorderColor;
  final Color deleteColor;
}

abstract class FlAssetsPicker extends StatefulWidget {
  const FlAssetsPicker(
      {super.key,
      this.renovate,
      required this.maxVideoCount,
      required this.maxCount,
      required this.fromRequestTypes,
      this.enablePicker = true,
      this.errorCallback,
      this.fromTypesBuilder,
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
  final PickerFromTypeBuilder? fromTypesBuilder;

  final bool useRootNavigator = true;

  final CameraPickerPageRoute<AssetEntity> Function(Widget picker)?
      pageRouteBuilderForCameraPicker;

  final AssetPickerPageRouteBuilder<List<AssetEntity>>?
      pageRouteBuilderForAssetPicker;

  /// 资源重新编辑
  final FlAssetFileRenovate? renovate;

  /// 选择图片或者视频
  static Future<ExtendedAssetEntity?> showPickerWithFormType(
    BuildContext context, {
    bool mounted = true,

    /// 选择框提示item
    List<PickerFromTypeConfig> fromTypes = const [
      PickerFromTypeConfig(
          fromType: PickerFromType.assets,
          text: Text('图库选择'),
          requestType: RequestType.image),
      PickerFromTypeConfig(
          fromType: PickerFromType.camera,
          text: Text('相机拍摄'),
          requestType: RequestType.image),
      PickerFromTypeConfig(
          fromType: PickerFromType.cancel,
          text: Text('取消', style: TextStyle(color: Colors.red))),
    ],
    PickerFromTypeBuilder? fromTypesBuilder,

    /// 默认选择的类型 [fromTypes] 不会弹出选择框
    RequestType requestType = RequestType.image,

    /// 指定类型时
    PickerFromType? pickerFromType,

    /// 获取权限
    FlAssetsPickerGetPermission? getPermission,

    /// 选择器配置信息
    AssetPickerConfig? assetPickerConfig,
    AssetPickerPageRouteBuilder<List<AssetEntity>>?
        pageRouteBuilderForAssetPicker,

    /// 相机配置信息
    CameraPickerConfig? cameraPickerConfig,
    CameraPickerPageRoute<AssetEntity> Function(Widget picker)?
        pageRouteBuilderForCameraPicker,

    /// 错误提示
    FlAssetsPickerErrorCallback? errorCallback,

    /// 资源重编辑
    FlAssetFileRenovate? renovate,

    /// 资源最大占用字节
    int maxBytes = 167772160,
  }) async {
    if (!_isMobile) return null;
    pickerFromType ??= (await showPickerFromType(context, fromTypes,
            fromTypesBuilder: fromTypesBuilder))
        ?.fromType;
    AssetEntity? entity;
    switch (pickerFromType) {
      case PickerFromType.assets:
        final permission = await getPermission?.call(pickerFromType!) ?? true;
        if (!permission || !mounted) return null;
        final assetsEntity = await showPickerAssets(context,
            pageRouteBuilder: pageRouteBuilderForAssetPicker,
            pickerConfig: AssetPickerConfig(
                maxAssets: 1,
                requestType: requestType,
                selectedAssets: []).merge(assetPickerConfig));
        if (assetsEntity == null || assetsEntity.isEmpty) return null;
        entity = assetsEntity.first;
        break;
      case PickerFromType.camera:
        final permission = await getPermission?.call(pickerFromType!) ?? true;
        if (!permission || !mounted) return null;
        entity = await showPickerFromCamera(context,
            pageRouteBuilder: pageRouteBuilderForCameraPicker,
            pickerConfig: const CameraPickerConfig(
                    resolutionPreset: ResolutionPreset.high)
                .merge(cameraPickerConfig));
        break;
      default:
    }
    if (entity == null) return null;
    final file = await entity.file;
    if (file == null) {
      errorCallback?.call('无法获取该资源');
      return null;
    }
    final fileBytes = file.readAsBytesSync();
    if (fileBytes.length > maxBytes) {
      errorCallback?.call('最大选择${_toSize(maxBytes)}');
      return null;
    }
    return entity.toExtensionAssetEntity(renovate: renovate);
  }

  /// show 选择弹窗
  static Future<PickerFromTypeConfig?> showPickerFromType(
    BuildContext context,
    List<PickerFromTypeConfig> fromTypes, {
    PickerFromTypeBuilder? fromTypesBuilder,
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
              fromTypesBuilder?.call(context, fromTypes) ??
              _PickFromTypeBuilderWidget(fromTypes));
    }
    return type;
  }

  /// 选择图片
  static Future<List<AssetEntity>?> showPickerAssets(BuildContext context,
          {bool useRootNavigator = true,
          Key? key,
          AssetPickerConfig pickerConfig = const AssetPickerConfig(),
          AssetPickerPageRouteBuilder<List<AssetEntity>>? pageRouteBuilder}) =>
      AssetPicker.pickAssets(context,
          key: key,
          pickerConfig: pickerConfig,
          useRootNavigator: useRootNavigator,
          pageRouteBuilder: pageRouteBuilder);

  /// 选择图片
  static Future<List<Asset>?> showPickerAssetsWithDelegate<Asset, Path,
              PickerProvider extends AssetPickerProvider<Asset, Path>>(
          BuildContext context,
          {Key? key,
          required AssetPickerBuilderDelegate<Asset, Path> delegate,
          bool useRootNavigator = true,
          AssetPickerPageRouteBuilder<List<Asset>>? pageRouteBuilder}) =>
      AssetPicker.pickAssetsWithDelegate<Asset, Path, PickerProvider>(context,
          key: key,
          delegate: delegate,
          useRootNavigator: useRootNavigator,
          pageRouteBuilder: pageRouteBuilder);

  /// 通过相机拍照
  static Future<AssetEntity?> showPickerFromCamera(
    BuildContext context, {
    bool useRootNavigator = true,
    CameraPickerConfig pickerConfig = const CameraPickerConfig(),
    CameraPickerPageRoute<AssetEntity> Function(Widget picker)?
        pageRouteBuilder,
  }) =>
      CameraPicker.pickFromCamera(context,
          pickerConfig: pickerConfig,
          useRootNavigator: useRootNavigator,
          pageRouteBuilder: pageRouteBuilder);

  /// int 字节转 k MB GB
  static String _toSize(int size) {
    if (size < 1024) {
      return '${size}B';
    } else if (size >= 1024 && size < pow(1024, 2)) {
      size = (size / 10.24).round();
      return '${size / 100}KB';
    } else if (size >= pow(1024, 2) && size < pow(1024, 3)) {
      size = (size / (pow(1024, 2) * 0.01)).round();
      return '${size / 100}MB';
    } else if (size >= pow(1024, 3) && size < pow(1024, 4)) {
      size = (size / (pow(1024, 3) * 0.01)).round();
      return '${size / 100}GB';
    }
    return size.toString();
  }
}

class _PickFromTypeBuilderWidget extends StatelessWidget {
  const _PickFromTypeBuilderWidget(this.list);

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
