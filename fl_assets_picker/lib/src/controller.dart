part of '../fl_assets_picker.dart';

class AssetsPickerController extends FlAssetPickerOptions with ChangeNotifier {
  AssetsPickerController({
    List<FlAssetEntity>? entities,
    List<PickerActionOptions>? actions,
    this.allowPick = true,
    super.assetConfig = const AssetPickerConfig(),
    super.cameraConfig = const CameraPickerConfig(),
    super.useRootNavigator = true,
    super.pageRouteBuilderForAssetPicker,
    super.pageRouteBuilderForCameraPicker,
    this.getFileAsync = false,
    this.getThumbnailDataAsync = false,
    this.onRenovate,
    this.onError,
  }) : entities = entities ?? [],
       actions = actions ?? defaultPickerActionOptions;

  /// 是否异步获取文件
  final bool getFileAsync;

  /// 是否异步获取缩略图
  final bool getThumbnailDataAsync;

  /// 选择的资源
  final List<FlAssetEntity> entities;

  set entities(List<FlAssetEntity> entities) {
    this.entities.clear();
    this.entities.addAll(entities);
    _notify();
  }

  /// 选择的动作
  final List<PickerActionOptions> actions;

  set actions(List<PickerActionOptions> actions) {
    this.actions.clear();
    this.actions.addAll(actions);
  }

  /// 是否允许 资源选择
  final bool allowPick;

  /// 对选中的资源文件重新编辑，例如 压缩 裁剪 上传
  final FlAssetEntityRenovate? onRenovate;

  /// 选择过程中的异常回调
  final FlAssetsPickerErrorHandler? onError;

  bool _disposed = false;
  bool _picking = false;

  /// 资源预览渲染，子类可重写
  Widget buildPreview(FlAssetEntity asset, bool isThumbnail) => _defaultAssetPreviewBuilder(asset, isThumbnail);

  /// 权限请求，子类可重写
  Future<bool> requestPermission(PickerAction action) async => true;

  /// 来源选择弹层，子类可重写
  Widget buildActionSheet(BuildContext context, List<PickerActionOptions> actions) =>
      _defaultActionSheetBuilder(context, actions);

  /// 选择图片
  Future<void> pickAssets(BuildContext context, {bool reset = false}) {
    return _guard(() async {
      final assets = await FlAssetsPicker.showPickAssets(
        context,
        pickerConfig: assetConfig,
        useRootNavigator: useRootNavigator,
        pageRouteBuilder: pageRouteBuilderForAssetPicker,
        requestPermission: requestPermission,
        onError: onError,
      );
      await _addAssets(assets, reset: reset);
    });
  }

  /// 通过相机拍照
  Future<void> pickFromCamera(BuildContext context, {bool reset = false}) {
    return _guard(() async {
      final asset = await FlAssetsPicker.showPickFromCamera(
        context,
        pickerConfig: cameraConfig,
        useRootNavigator: useRootNavigator,
        pageRouteBuilder: pageRouteBuilderForCameraPicker,
        requestPermission: requestPermission,
        onError: onError,
      );
      if (asset == null) return;
      await _addAssets(<AssetEntity>[asset], reset: reset);
    });
  }

  /// 弹窗选择类型
  Future<void> pickActions(BuildContext context, {bool unfocus = true, bool reset = false}) {
    return _guard(() async {
      if (unfocus) FocusManager.instance.primaryFocus?.unfocus();
      final actionOptions = await FlAssetsPicker.showPickActions(
        context,
        actions,
        actionSheetBuilder: buildActionSheet,
      );
      if (actionOptions == null || _disposed || !context.mounted) return;
      final assets = await actionOptions.action.pick(
        context,
        options: this,
        requestPermission: requestPermission,
        onError: onError,
      );
      await _addAssets(assets, reset: reset);
    });
  }

  Future<void> _addAssets(List<AssetEntity> assets, {required bool reset}) async {
    if (_disposed || assets.isEmpty) return;
    final extended = <FlAssetEntity>[];
    for (final asset in assets) {
      if (_disposed) return;
      extended.add(await toExtended(asset));
    }
    if (reset) entities.clear();
    entities.addAll(extended);
    _notify();
  }

  /// 对图片进行扩展，例如 压缩 裁剪 上传
  Future<FlAssetEntity> toExtended(AssetEntity asset) => asset.toExtended(
    onRenovate: onRenovate,
    getFileAsync: getFileAsync,
    getThumbnailDataAsync: getThumbnailDataAsync,
  );

  /// 删除图片
  Future<void> delete(FlAssetEntity asset) async {
    if (_disposed) return;
    entities.remove(asset);
    _notify();
  }

  /// 全屏预览
  Future<T?> preview<T>(BuildContext context, {int initialIndex = 0}) {
    if (_disposed) return Future<T?>.value();
    return FlAssetsPicker.preview<T>(context, entities, initialIndex: initialIndex, previewBuilder: buildPreview);
  }

  Future<void> _guard(Future<void> Function() action) async {
    if (!allowPick || _picking) return;
    _picking = true;
    try {
      await action();
    } catch (error, stackTrace) {
      _reportPickerError(onError, error, stackTrace);
    } finally {
      _picking = false;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
