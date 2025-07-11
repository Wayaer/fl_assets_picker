part of '../fl_image_picker.dart';

class ImagePickerController with ChangeNotifier {
  ImagePickerController({
    List<FlXFile>? entities,
    List<PickerActionOptions>? actions,
    this.allowPick = true,
    this.options = const ImagePickerOptions(),
  })  : entities = entities ?? [],
        actions = actions ?? defaultImagePickerActionOptions;

  /// 资源选择参数
  final ImagePickerOptions options;

  /// 选择的资源
  final List<FlXFile> entities;

  set entities(List<FlXFile> entities) {
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
  FlXFileRenovate? get onRenovate => null;

  /// 弹窗选择类型
  Future<void> pickActions(BuildContext context,
      {bool unfocus = true, bool reset = false}) async {
    if (unfocus) FocusManager.instance.primaryFocus?.unfocus();
    final action = await FlImagePicker.showPickActions(context, actions);
    if (action == null) return;
    await pick(action.action, reset: reset);
  }

  /// 删除图片
  Future<void> delete(FlXFile file) async {
    entities.remove(file);
    notifyListeners();
  }

  /// 全屏预览
  Future<T?> preview<T>(BuildContext context, {int initialIndex = 0}) {
    return FlImagePicker.preview<T>(context, entities,
        initialIndex: initialIndex);
  }
}
