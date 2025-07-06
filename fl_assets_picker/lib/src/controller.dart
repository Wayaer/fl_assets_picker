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
  })  : entities = entities ?? [],
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
    notifyListeners();
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
  FlAssetEntityRenovate? get onRenovate => null;

  /// 选择图片
  Future<void> pickAssets(BuildContext context, {bool reset = false}) async {
    if (!allowPick) return;
    final assets = await FlAssetsPicker.showPickAssets(context,
        pickerConfig: assetConfig,
        useRootNavigator: useRootNavigator,
        pageRouteBuilder: pageRouteBuilderForAssetPicker);
    if (assets.isEmpty) return;
    if (reset) entities.clear();
    for (final asset in assets) {
      entities.add(await toExtended(asset));
    }
    notifyListeners();
  }

  /// 通过相机拍照
  Future<void> pickFromCamera(BuildContext context,
      {bool reset = false}) async {
    if (!allowPick) return;
    final asset = await FlAssetsPicker.showPickFromCamera(context,
        pickerConfig: cameraConfig,
        useRootNavigator: useRootNavigator,
        pageRouteBuilder: pageRouteBuilderForCameraPicker);
    if (asset == null) return;
    if (reset) entities.clear();
    entities.add(await toExtended(asset));
    notifyListeners();
  }

  /// 弹窗选择类型
  Future<void> pickActions(BuildContext context,
      {bool requestFocus = true, bool reset = false}) async {
    if (!allowPick) return;
    if (requestFocus) FocusScope.of(context).requestFocus(FocusNode());
    final actionOptions =
        await FlAssetsPicker.showPickActions(context, actions);
    if (actionOptions == null) return;
    if (context.mounted) {
      final assets = await actionOptions.action.pick(context, options: this);
      if (assets.isEmpty) return;
      if (reset) entities.clear();
      for (final asset in assets) {
        entities.add(await toExtended(asset));
      }
      notifyListeners();
    }
  }

  /// 对图片进行扩展，例如 压缩 裁剪 上传
  Future<FlAssetEntity> toExtended(AssetEntity asset) => asset.toExtended(
      onRenovate: onRenovate,
      getFileAsync: getFileAsync,
      getThumbnailDataAsync: getThumbnailDataAsync);

  /// 删除图片
  Future<void> delete(FlAssetEntity asset) async {
    entities.remove(asset);
    notifyListeners();
  }

  /// 全屏预览
  Future<T?> preview<T>(BuildContext context, {int initialIndex = 0}) async {
    final builder = buildPreviewModal(initialIndex: initialIndex);
    if (context.mounted) {
      return await showCupertinoModalPopup<T>(
          context: context, builder: (_) => builder);
    }
    return null;
  }

  /// 构建预览 Widget
  Widget buildPreviewModal({int initialIndex = 0}) =>
      FlAssetsPickerPreviewPageView(
          controller: this, initialIndex: initialIndex);
}
