import 'dart:math';

import 'package:fl_assets_picker/fl_assets_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

bool get _isMobile => _isAndroid || _isIOS;

typedef FlAssetsPickerCheckPermission = Future<bool> Function(
    PickerFromType fromType);

typedef FlAssetsPickerErrorCallback = void Function(String erroe);

typedef PickerFromTypeBuilder = Widget Function(
    BuildContext context, List<PickerFromTypeItem> fromTypes);

typedef FlAssetFileRenovate<T> = Future<T> Function(AssetEntity entity);

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
  gallery,

  /// 从相机拍摄
  camera,

  /// 取消
  cancel,
}

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

typedef DeletionConfirmation = Future<bool> Function(
    ExtendedAssetEntity entity);

class AssetsPickerEntryConfig {
  const AssetsPickerEntryConfig(
      {this.color,
      this.fit = BoxFit.cover,
      this.previewFit = BoxFit.contain,
      this.borderRadius = const BorderRadius.all(Radius.circular(8)),
      this.size = const Size(65, 65),
      this.pick = const AssetPickIcon(),
      this.delete = const AssetDeleteIcon(),
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

  /// 缩略图fit
  final BoxFit fit;

  /// 预览画面fit
  final BoxFit previewFit;
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
      this.pageRouteBuilderForAssetPicker,
      this.checkPermission});

  /// 最大选择视频数量
  final int maxVideoCount;

  /// 最多选择几个资源
  final int maxCount;

  /// 请求类型
  final List<PickerFromTypeItem> fromRequestTypes;

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

  /// 获取权限
  final FlAssetsPickerCheckPermission? checkPermission;

  /// 选择图片或者视频
  static Future<ExtendedAssetEntity?> showPickerWithFormType(
    BuildContext context, {
    /// 选择框提示item
    List<PickerFromTypeItem> fromTypes = defaultPickerFromTypeItem,
    PickerFromTypeBuilder? fromTypesBuilder,

    /// 获取权限
    FlAssetsPickerCheckPermission? checkPermission,

    /// 资源选择器配置信息
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
    final pickerFromTypeConfig = await showPickerFromType(context, fromTypes,
        fromTypesBuilder: fromTypesBuilder);
    if (pickerFromTypeConfig == null) return null;
    AssetEntity? entity;
    switch (pickerFromTypeConfig.fromType) {
      case PickerFromType.gallery:
        if (context.mounted) {
          final assetsEntity = await showPickerAssets(context,
              pageRouteBuilder: pageRouteBuilderForAssetPicker,
              checkPermission: checkPermission,
              pickerConfig: AssetPickerConfig(
                  maxAssets: 1,
                  requestType: pickerFromTypeConfig.requestType,
                  selectedAssets: []).merge(assetPickerConfig));
          if (assetsEntity == null || assetsEntity.isEmpty) return null;
          entity = assetsEntity.first;
        } else {
          return null;
        }
        break;
      case PickerFromType.camera:
        if (context.mounted) {
          entity = await showPickerFromCamera(context,
              checkPermission: checkPermission,
              pageRouteBuilder: pageRouteBuilderForCameraPicker,
              pickerConfig: const CameraPickerConfig(
                      resolutionPreset: ResolutionPreset.high)
                  .merge(cameraPickerConfig)
                  .copyWith(
                      enableRecording:
                          pickerFromTypeConfig.requestType.containsVideo(),
                      onlyEnableRecording:
                          pickerFromTypeConfig.requestType == RequestType.video,
                      enableAudio: pickerFromTypeConfig.requestType
                              .containsVideo() ||
                          pickerFromTypeConfig.requestType.containsAudio()));
        } else {
          return null;
        }
        break;
      default:
        return null;
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
    return entity.toExtended(renovate: renovate);
  }

  /// show 选择弹窗
  static Future<PickerFromTypeItem?> showPickerFromType(
    BuildContext context,
    List<PickerFromTypeItem> fromTypes, {
    PickerFromTypeBuilder? fromTypesBuilder,
  }) async {
    PickerFromTypeItem? type;
    if (fromTypes.length == 1 &&
        fromTypes.first.fromType != PickerFromType.cancel) {
      type = fromTypes.first;
    } else {
      type = await showCupertinoModalPopup<PickerFromTypeItem?>(
          context: context,
          builder: (BuildContext context) =>
              fromTypesBuilder?.call(context, fromTypes) ??
              _PickFromTypeBuilderWidget(fromTypes));
    }
    return type;
  }

  /// 选择图片
  static Future<List<AssetEntity>?> showPickerAssets(
    BuildContext context, {
    bool useRootNavigator = true,
    FlAssetsPickerCheckPermission? checkPermission,
    Key? key,
    AssetPickerConfig pickerConfig = const AssetPickerConfig(),
    AssetPickerPageRouteBuilder<List<AssetEntity>>? pageRouteBuilder,
  }) async {
    final permissionState =
        await checkPermission?.call(PickerFromType.gallery) ?? true;
    if (permissionState && context.mounted) {
      return await AssetPicker.pickAssets(context,
          key: key,
          pickerConfig: pickerConfig,
          useRootNavigator: useRootNavigator,
          pageRouteBuilder: pageRouteBuilder);
    }
    return null;
  }

  /// 选择图片
  static Future<List<Asset>?> showPickerAssetsWithDelegate<Asset, Path,
      PickerProvider extends AssetPickerProvider<Asset, Path>>(
    BuildContext context, {
    Key? key,
    FlAssetsPickerCheckPermission? checkPermission,
    required AssetPickerBuilderDelegate<Asset, Path> delegate,
    bool useRootNavigator = true,
    AssetPickerPageRouteBuilder<List<Asset>>? pageRouteBuilder,
  }) async {
    final permissionState =
        await checkPermission?.call(PickerFromType.gallery) ?? true;
    if (context.mounted && permissionState) {
      return await AssetPicker.pickAssetsWithDelegate<Asset, Path,
              PickerProvider>(context,
          key: key,
          delegate: delegate,
          useRootNavigator: useRootNavigator,
          pageRouteBuilder: pageRouteBuilder);
    }
    return null;
  }

  /// 通过相机拍照
  static Future<AssetEntity?> showPickerFromCamera(
    BuildContext context, {
    bool useRootNavigator = true,
    FlAssetsPickerCheckPermission? checkPermission,
    CameraPickerConfig pickerConfig = const CameraPickerConfig(),
    CameraPickerPageRoute<AssetEntity> Function(Widget picker)?
        pageRouteBuilder,
  }) async {
    final permissionState =
        await checkPermission?.call(PickerFromType.camera) ?? true;
    if (context.mounted && permissionState) {
      return await CameraPicker.pickFromCamera(context,
          pickerConfig: pickerConfig,
          useRootNavigator: useRootNavigator,
          pageRouteBuilder: pageRouteBuilder);
    }
    return null;
  }

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