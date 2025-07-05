part of '../fl_assets_picker.dart';

bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

bool get _supportable => _isAndroid || _isIOS;

typedef FlAssetsPickerCheckPermission = Future<bool> Function(
    PickerAction action);

typedef PickerActionBuilder = Widget Function(
    BuildContext context, List<PickerActionOptions> actions);

typedef FlAssetBuilder = Widget Function(
    ExtendedAssetEntity entity, bool isThumbnail);

FlAssetBuilder _defaultAssetBuilder =
    (ExtendedAssetEntity entity, bool isThumbnail) {
  Widget unsupported() => const Center(child: Text('No preview'));
  if (entity.type == AssetType.image) {
    final imageProvider = entity.toImageProvider();
    if (imageProvider != null) {
      return Image(
          image: imageProvider,
          fit: isThumbnail ? BoxFit.cover : BoxFit.contain);
    }
  }
  return unsupported();
};

PickerActionBuilder _defaultActionsBuilder =
    (_, List<PickerActionOptions> actions) => FlPickerActionBuilder(actions);

enum PickerAction {
  /// 从图库中选择
  gallery,

  /// 从相机拍摄
  camera,

  /// 取消
  cancel,
  ;

  Future<List<AssetEntity>> pick(BuildContext context,
      {FlAssetPickerOptions options = const FlAssetPickerOptions()}) async {
    List<AssetEntity> entities = [];
    switch (this) {
      case PickerAction.gallery:
        entities = await FlAssetsPicker.showPickAssets(
          context,
          pageRouteBuilder: options.pageRouteBuilderForAssetPicker,
          pickerConfig: options.assetConfig,
          useRootNavigator: options.useRootNavigator,
        );
        break;
      case PickerAction.camera:
        final result = await FlAssetsPicker.showPickFromCamera(
          context,
          pageRouteBuilder: options.pageRouteBuilderForCameraPicker,
          pickerConfig: options.cameraConfig,
          useRootNavigator: options.useRootNavigator,
        );
        if (result != null) entities.add(result);
        break;
      default:
        return [];
    }
    return entities;
  }
}

class FlAssetPickerOptions {
  const FlAssetPickerOptions({
    this.pageRouteBuilderForAssetPicker,
    this.pageRouteBuilderForCameraPicker,
    this.assetConfig = const AssetPickerConfig(),
    this.cameraConfig = const CameraPickerConfig(),
    this.useRootNavigator = true,
  });

  /// 资源选择器配置信息
  final AssetPickerConfig assetConfig;
  final AssetPickerPageRouteBuilder<List<AssetEntity>>?
      pageRouteBuilderForAssetPicker;

  /// 相机配置信息
  final CameraPickerConfig cameraConfig;
  final CameraPickerPageRoute<AssetEntity> Function(Widget picker)?
      pageRouteBuilderForCameraPicker;

  /// 是否使用根导航器
  final bool useRootNavigator;
}

abstract class FlAssetsPicker extends StatefulWidget {
  /// assetBuilder
  static FlAssetBuilder assetBuilder = _defaultAssetBuilder;

  /// 权限申请
  static FlAssetsPickerCheckPermission? checkPermission;

  /// 类型来源选择器
  static PickerActionBuilder actionsBuilder = _defaultActionsBuilder;

  const FlAssetsPicker({
    super.key,
    this.itemConfig = const FlAssetsPickerItemConfig(),
    required this.controller,
    this.disposeController = false,
  });

  /// 资源控制器
  final AssetsPickerController controller;

  /// dispose controller.dispose();
  final bool disposeController;

  /// item UI 样式配置
  final FlAssetsPickerItemConfig itemConfig;

  /// value 转换为 [ImageProvider]
  static ImageProvider? buildImageProvider(dynamic value) {
    if (value is String) {
      if (value.startsWith('http') || value.startsWith('blob:http')) {
        return NetworkImage(value);
      } else {
        return AssetImage(value);
      }
    } else if (value is Uint8List) {
      return MemoryImage(value);
    } else if (value is File || value is XFile) {
      return FileImage(value);
    } else if (value is XFile) {
      return FileImage(File(value.path));
    }
    return null;
  }

  /// show pick actions
  /// show pick
  static Future<List<AssetEntity>> showPickWithActions(
      BuildContext context, List<PickerActionOptions> actions,
      {FlAssetPickerOptions options = const FlAssetPickerOptions()}) async {
    if (!_supportable) return [];
    final actionOption = await showPickActions(context, actions);
    if (actionOption == null) return [];
    if (context.mounted) {
      return await actionOption.action.pick(context, options: options);
    }
    return [];
  }

  /// show pick actions
  static Future<PickerActionOptions?> showPickActions(
      BuildContext context, List<PickerActionOptions> actions) async {
    if (actions.isEmpty) return null;
    PickerActionOptions? action;
    final effectiveActions =
        actions.where((e) => e.action != PickerAction.cancel);
    if (effectiveActions.length == 1) {
      action = effectiveActions.first;
    } else {
      action = await showCupertinoModalPopup<PickerActionOptions?>(
          context: context,
          builder: (BuildContext context) => actionsBuilder(context, actions));
    }
    return action;
  }

  /// 选择图片
  static Future<List<AssetEntity>> showPickAssets(
    BuildContext context, {
    bool useRootNavigator = true,
    AssetPickerConfig pickerConfig = const AssetPickerConfig(),
    AssetPickerPageRouteBuilder<List<AssetEntity>>? pageRouteBuilder,
  }) async {
    final permissionState =
        await checkPermission?.call(PickerAction.gallery) ?? true;
    if (permissionState && context.mounted) {
      return await AssetPicker.pickAssets(context,
              pickerConfig: pickerConfig,
              useRootNavigator: useRootNavigator,
              pageRouteBuilder: pageRouteBuilder) ??
          [];
    }
    return [];
  }

  /// 选择图片
  static Future<List<Asset>?> showPickAssetsWithDelegate<Asset, Path,
      PickerProvider extends AssetPickerProvider<Asset, Path>>(
    BuildContext context, {
    required AssetPickerBuilderDelegate<Asset, Path> delegate,
    bool useRootNavigator = true,
    AssetPickerPageRouteBuilder<List<Asset>>? pageRouteBuilder,
  }) async {
    final permissionState =
        await checkPermission?.call(PickerAction.gallery) ?? true;
    if (context.mounted && permissionState) {
      return await AssetPicker.pickAssetsWithDelegate<Asset, Path,
              PickerProvider>(context,
          delegate: delegate,
          useRootNavigator: useRootNavigator,
          pageRouteBuilder: pageRouteBuilder);
    }
    return null;
  }

  /// 通过相机拍照
  static Future<AssetEntity?> showPickFromCamera(
    BuildContext context, {
    bool useRootNavigator = true,
    CameraPickerConfig pickerConfig = const CameraPickerConfig(),
    CameraPickerPageRoute<AssetEntity> Function(Widget picker)?
        pageRouteBuilder,
  }) async {
    final permissionState =
        await checkPermission?.call(PickerAction.camera) ?? true;
    if (context.mounted && permissionState) {
      return await CameraPicker.pickFromCamera(context,
          pickerConfig: pickerConfig,
          useRootNavigator: useRootNavigator,
          pageRouteBuilder: pageRouteBuilder);
    }
    return null;
  }
}

/// 图片预览器
class FlImagePickerPreviewModal extends StatelessWidget {
  const FlImagePickerPreviewModal({
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
class FlImagePickerPreviewPageView extends StatelessWidget {
  const FlImagePickerPreviewPageView(
      {super.key, required this.controller, this.initialIndex = 0});

  final AssetsPickerController controller;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    final length = controller.entities.length;
    final initialPage = min(length, initialIndex);
    return FlImagePickerPreviewModal(
        child: PageView.builder(
            controller: PageController(initialPage: initialPage),
            itemCount: length,
            itemBuilder: (_, int index) => Center(
                child: FlAssetsPicker.assetBuilder(
                    controller.entities[index], false))));
  }
}
