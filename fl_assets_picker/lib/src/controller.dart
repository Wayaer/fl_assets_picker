part of '../fl_assets_picker.dart';

class AssetsPickerController extends FlAssetPickerOptions with ChangeNotifier {
  AssetsPickerController({
    List<ExtendedAssetEntity>? entities,
    List<PickerActionOptions>? actions,
    this.allowPick = true,
    super.assetConfig = const AssetPickerConfig(),
    super.cameraConfig = const CameraPickerConfig(),
    super.useRootNavigator = true,
    super.pageRouteBuilderForAssetPicker,
    super.pageRouteBuilderForCameraPicker,
  })  : entities = entities ?? [],
        actions = actions ?? defaultPickerActionOptions;

  /// 选择的资源
  final List<ExtendedAssetEntity> entities;

  set entities(List<ExtendedAssetEntity> entities) {
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
  ExtendedAssetEntityRenovate? get onRenovate => null;

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
      entities.add(await asset.toExtended(renovate: onRenovate));
    }
    notifyListeners();
  }

  /// 通过相机拍照
  Future<void> pickFromCamera(BuildContext context,
      {bool reset = false}) async {
    if (!allowPick) return;
    final entity = await FlAssetsPicker.showPickFromCamera(context,
        pickerConfig: cameraConfig,
        useRootNavigator: useRootNavigator,
        pageRouteBuilder: pageRouteBuilderForCameraPicker);
    if (entity == null) return;
    if (reset) entities.clear();
    entities.add(await entity.toExtended(renovate: onRenovate));
    notifyListeners();
  }

  /// 弹窗选择类型
  Future<void> pickActions(BuildContext context,
      {bool requestFocus = true, bool reset = false}) async {
    if (requestFocus) FocusScope.of(context).requestFocus(FocusNode());
    final actionOptions =
        await FlAssetsPicker.showPickActions(context, actions);
    if (actionOptions == null) return;
    switch (actionOptions.action) {
      case PickerAction.gallery:
        if (context.mounted) await pickAssets(context, reset: reset);
      case PickerAction.camera:
        if (context.mounted) await pickFromCamera(context, reset: reset);
      case PickerAction.cancel:
        break;
    }
  }

  /// 删除图片
  Future<void> delete(ExtendedAssetEntity entity) async {
    entities.remove(entity);
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
      FlImagePickerPreviewPageView(
          controller: this, initialIndex: initialIndex);
}
