part of '../fl_image_picker.dart';

class ImagePickerController with ChangeNotifier {
  ImagePickerController({
    List<ExtendedXFile>? entities,
    List<PickerActionOptions>? actions,
    this.allowPick = true,
    this.options = const ImagePickerOptions(),
  })  : entities = entities ?? [],
        actions = actions ?? defaultImagePickerActionOptions;

  /// 资源选择参数
  final ImagePickerOptions options;

  /// 选择的资源
  final List<ExtendedXFile> entities;

  set entities(List<ExtendedXFile> entities) {
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

  /// 选择图片
  Future<void> pick(PickerAction action, {bool reset = false}) async {
    if (!allowPick) return;
    final files = await FlImagePicker.showPick(action, options: options);
    if (reset && files.isNotEmpty) entities.clear();
    for (final file in files) {
      entities.add(await file.toRenovated(onRenovate));
    }
    notifyListeners();
  }

  /// 对选中的资源文件重新编辑，例如 压缩 裁剪 上传
  ExtendedXFileRenovate? get onRenovate => null;

  /// 弹窗选择类型
  Future<void> pickActions(BuildContext context,
      {bool requestFocus = true, bool reset = false}) async {
    if (requestFocus) FocusScope.of(context).requestFocus(FocusNode());
    final action = await FlImagePicker.showPickActions(context, actions);
    if (action == null) return;
    await pick(action.action, reset: reset);
  }

  /// 删除图片
  Future<void> delete(ExtendedXFile entity) async {
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
