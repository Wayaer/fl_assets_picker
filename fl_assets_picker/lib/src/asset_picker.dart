part of '../fl_assets_picker.dart';

bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

bool get _isMacOS => defaultTargetPlatform == TargetPlatform.macOS;

/// 图库选择：Android、iOS、macOS
bool get _supportableGallery => _isAndroid || _isIOS || _isMacOS;

/// 相机拍摄：Android、iOS
bool get _supportableCamera => _isAndroid || _isIOS;

typedef FlAssetsPickerPermissionRequest = Future<bool> Function(PickerAction action);

@Deprecated('Use FlAssetsPickerPermissionRequest instead')
typedef FlAssetsPickerCheckPermission = FlAssetsPickerPermissionRequest;

typedef FlAssetsPickerActionSheetBuilder = Widget Function(BuildContext context, List<PickerActionOptions> actions);

@Deprecated('Use FlAssetsPickerActionSheetBuilder instead')
typedef PickerActionBuilder = FlAssetsPickerActionSheetBuilder;

typedef FlAssetsPickerErrorHandler = void Function(Object error, StackTrace stackTrace);

typedef FlAssetPreviewBuilder = Widget Function(FlAssetEntity asset, bool isThumbnail);

@Deprecated('Use FlAssetPreviewBuilder instead')
typedef FlAssetBuilder = FlAssetPreviewBuilder;

Widget _defaultAssetPreviewBuilder(FlAssetEntity asset, bool isThumbnail) {
  Widget unsupported() => const Center(child: Text('No preview'));
  if (asset.type == AssetType.image) {
    final imageProvider = asset.toImageProvider();
    if (imageProvider != null) {
      return Image(image: imageProvider, fit: isThumbnail ? BoxFit.cover : BoxFit.contain);
    }
  }
  return unsupported();
}

Widget _defaultActionSheetBuilder(BuildContext context, List<PickerActionOptions> actions) =>
    FlPickerActionBuilder(actions);

void _reportPickerError(FlAssetsPickerErrorHandler? onError, Object error, StackTrace stackTrace) {
  if (onError != null) {
    onError(error, stackTrace);
    return;
  }
  FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stackTrace, library: 'fl_assets_picker'));
}

enum PickerAction {
  /// 从图库中选择
  gallery,

  /// 从相机拍摄
  camera,

  /// 取消
  cancel;

  Future<List<AssetEntity>> pick(
    BuildContext context, {
    FlAssetPickerOptions options = const FlAssetPickerOptions(),
    FlAssetsPickerPermissionRequest? requestPermission,
    FlAssetsPickerErrorHandler? onError,
  }) async {
    List<AssetEntity> assets = [];
    switch (this) {
      case PickerAction.gallery:
        if (!_supportableGallery) return [];
        assets = await FlAssetsPicker.showPickAssets(
          context,
          pageRouteBuilder: options.pageRouteBuilderForAssetPicker,
          pickerConfig: options.assetConfig,
          useRootNavigator: options.useRootNavigator,
          requestPermission: requestPermission,
          onError: onError,
        );
        break;
      case PickerAction.camera:
        if (!_supportableCamera) return [];
        final asset = await FlAssetsPicker.showPickFromCamera(
          context,
          pageRouteBuilder: options.pageRouteBuilderForCameraPicker,
          pickerConfig: options.cameraConfig,
          useRootNavigator: options.useRootNavigator,
          requestPermission: requestPermission,
          onError: onError,
        );
        if (asset != null) assets.add(asset);
        break;
      default:
        return [];
    }
    return assets;
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
  final AssetPickerPageRouteBuilder<List<AssetEntity>>? pageRouteBuilderForAssetPicker;

  /// 相机配置信息
  final CameraPickerConfig cameraConfig;
  final CameraPickerPageRoute<AssetEntity> Function(Widget picker)? pageRouteBuilderForCameraPicker;

  /// 是否使用根导航器
  final bool useRootNavigator;
}

abstract class FlAssetsPicker extends StatefulWidget {
  /// value 转换为 [ImageProvider]
  ///
  /// 支持 [ImageProvider]、网络地址、本地文件路径、asset 路径、[Uint8List]、[File]、[XFile]
  static ImageProvider? buildImageProvider(dynamic value) {
    if (value is ImageProvider) return value;
    if (value is String) {
      if (value.startsWith('http') || value.startsWith('blob:')) {
        return NetworkImage(value);
      }
      final file = File(value);
      if (file.existsSync()) return FileImage(file);
      return AssetImage(value);
    }
    if (value is Uint8List) return MemoryImage(value);
    if (value is File) return FileImage(value);
    if (value is XFile) return FileImage(File(value.path));
    return null;
  }

  /// show pick actions
  /// show pick
  static Future<List<AssetEntity>> showPickWithActions(
    BuildContext context,
    List<PickerActionOptions> actions, {
    FlAssetPickerOptions options = const FlAssetPickerOptions(),
    FlAssetsPickerPermissionRequest? requestPermission,
    FlAssetsPickerActionSheetBuilder actionSheetBuilder = _defaultActionSheetBuilder,
    FlAssetsPickerErrorHandler? onError,
  }) async {
    if (!_supportableGallery && !_supportableCamera) return [];
    final actionOption = await showPickActions(context, actions, actionSheetBuilder: actionSheetBuilder);
    if (actionOption == null) return [];
    if (context.mounted) {
      return await actionOption.action.pick(
        context,
        options: options,
        requestPermission: requestPermission,
        onError: onError,
      );
    }
    return [];
  }

  /// show pick actions
  static Future<PickerActionOptions?> showPickActions(
    BuildContext context,
    List<PickerActionOptions> actions, {
    FlAssetsPickerActionSheetBuilder actionSheetBuilder = _defaultActionSheetBuilder,
  }) async {
    if (actions.isEmpty) return null;
    PickerActionOptions? action;
    final effectiveActions = actions.where((e) => e.action != PickerAction.cancel);
    if (effectiveActions.isEmpty) return null;
    if (effectiveActions.length == 1) {
      action = effectiveActions.first;
    } else {
      action = await showCupertinoModalPopup<PickerActionOptions?>(
        context: context,
        builder: (BuildContext context) => actionSheetBuilder(context, actions),
      );
    }
    return action;
  }

  /// 选择图片
  static Future<List<AssetEntity>> showPickAssets(
    BuildContext context, {
    bool useRootNavigator = true,
    AssetPickerConfig pickerConfig = const AssetPickerConfig(),
    AssetPickerPageRouteBuilder<List<AssetEntity>>? pageRouteBuilder,
    FlAssetsPickerPermissionRequest? requestPermission,
    FlAssetsPickerErrorHandler? onError,
  }) async {
    if (!_supportableGallery) return [];
    try {
      final permissionState = await requestPermission?.call(PickerAction.gallery) ?? true;
      if (permissionState && context.mounted) {
        return await AssetPicker.pickAssets(
              context,
              pickerConfig: pickerConfig,
              useRootNavigator: useRootNavigator,
              pageRouteBuilder: pageRouteBuilder,
            ) ??
            [];
      }
    } catch (error, stackTrace) {
      _reportPickerError(onError, error, stackTrace);
    }
    return [];
  }

  /// 选择图片
  static Future<List<Asset>?> showPickAssetsWithDelegate<
    Asset,
    PathEntity,
    PickerProvider extends AssetPickerProvider<Asset, PathEntity>,
    Delegate extends AssetPickerBuilderDelegate<Asset, PathEntity>
  >(
    BuildContext context, {
    required Delegate delegate,
    bool useRootNavigator = true,
    AssetPickerPageRouteBuilder<List<Asset>>? pageRouteBuilder,
    FlAssetsPickerPermissionRequest? requestPermission,
    FlAssetsPickerErrorHandler? onError,
  }) async {
    if (!_supportableGallery) return null;
    try {
      final permissionState = await requestPermission?.call(PickerAction.gallery) ?? true;
      if (context.mounted && permissionState) {
        return await AssetPicker.pickAssetsWithDelegate<Asset, PathEntity, PickerProvider, Delegate>(
          context,
          delegate: delegate,
          useRootNavigator: useRootNavigator,
          pageRouteBuilder: pageRouteBuilder,
        );
      }
    } catch (error, stackTrace) {
      _reportPickerError(onError, error, stackTrace);
    }
    return null;
  }

  /// 通过相机拍照
  static Future<AssetEntity?> showPickFromCamera(
    BuildContext context, {
    bool useRootNavigator = true,
    CameraPickerConfig pickerConfig = const CameraPickerConfig(),
    CameraPickerPageRoute<AssetEntity> Function(Widget picker)? pageRouteBuilder,
    FlAssetsPickerPermissionRequest? requestPermission,
    FlAssetsPickerErrorHandler? onError,
  }) async {
    if (!_supportableCamera) return null;
    try {
      final permissionState = await requestPermission?.call(PickerAction.camera) ?? true;
      if (context.mounted && permissionState) {
        return await CameraPicker.pickFromCamera(
          context,
          pickerConfig: pickerConfig,
          useRootNavigator: useRootNavigator,
          pageRouteBuilder: pageRouteBuilder,
        );
      }
    } catch (error, stackTrace) {
      _reportPickerError(onError, error, stackTrace);
    }
    return null;
  }

  /// 全屏预览
  static Future<T?> preview<T>(
    BuildContext context,
    List<FlAssetEntity> entities, {
    int initialIndex = 0,
    FlAssetPreviewBuilder previewBuilder = _defaultAssetPreviewBuilder,
  }) async {
    if (entities.isEmpty) return null;
    final builder = FlAssetsPickerPreviewPageView(
      entities: entities,
      initialIndex: initialIndex,
      previewBuilder: previewBuilder,
    );
    if (context.mounted) {
      return await showCupertinoModalPopup<T>(context: context, builder: (_) => builder);
    }
    return null;
  }

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
}

abstract class FlAssetsPickerState<T extends FlAssetsPicker> extends State<T> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(listener);
  }

  void listener() {
    if (mounted) setState(() {});
  }

  Widget buildVideo(FlAssetEntity asset, Widget current) {
    final config = widget.itemConfig;
    if (asset.type == AssetType.video) {
      current = Stack(
        children: [
          SizedBox.expand(child: current),
          Align(alignment: Alignment.center, child: config.play),
        ],
      );
    }
    return current;
  }

  Widget buildBackgroundColor(Widget current) {
    final config = widget.itemConfig;
    if (config.backgroundColor != null) {
      current = ColoredBox(color: config.backgroundColor!, child: current);
    }
    return current;
  }

  Widget buildBorderRadius(Widget current) {
    final config = widget.itemConfig;
    if (config.borderRadius != null) {
      current = ClipRRect(borderRadius: config.borderRadius!, child: current);
    }
    return current;
  }

  Widget buildPickActions(Widget current, {bool reset = false}) {
    if (widget.controller.allowPick) {
      current = GestureDetector(
        onTap: () {
          widget.controller.pickActions(context, reset: reset);
        },
        child: current,
      );
    }
    return current;
  }

  @override
  void dispose() {
    widget.controller.removeListener(listener);
    if (widget.disposeController) widget.controller.dispose();
    super.dispose();
  }
}
