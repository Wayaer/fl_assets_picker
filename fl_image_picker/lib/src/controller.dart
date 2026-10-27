part of '../fl_image_picker.dart';

class ImagePickerController with ChangeNotifier {
  ImagePickerController({
    List<FlXFile>? entities,
    List<PickerActionOptions>? actions,
    this.allowPick = true,
    this.options = const FlImagePickerOptions(),
    this.onRenovate,
    this.onError,
  }) : entities = entities ?? [],
       actions = actions ?? defaultImagePickerActionOptions;

  /// 资源选择参数
  final FlImagePickerOptions options;

  /// 选择的资源
  final List<FlXFile> entities;

  set entities(List<FlXFile> entities) {
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
  final FlXFileRenovate? onRenovate;

  /// 选择过程中的异常回调
  final FlImagePickerErrorHandler? onError;

  bool _disposed = false;
  bool _picking = false;

  /// 资源预览渲染，子类可重写
  Widget buildPreview(FlXFile file, bool isThumbnail) => _defaultImagePreviewBuilder(file, isThumbnail);

  /// 权限请求，子类可重写
  Future<bool> requestPermission(PickerAction action) async => true;

  /// 来源选择弹层，子类可重写
  Widget buildActionSheet(BuildContext context, List<PickerActionOptions> actions) =>
      _defaultActionSheetBuilder(context, actions);

  /// 选择图片
  Future<void> pick(PickerAction action, {bool reset = false}) {
    return _guard(() => _pickFiles(action, reset: reset));
  }

  /// 弹窗选择类型
  Future<void> pickActions(BuildContext context, {bool unfocus = true, bool reset = false}) {
    return _guard(() async {
      if (unfocus) FocusManager.instance.primaryFocus?.unfocus();
      final action = await FlImagePicker.showPickActions(context, actions, actionSheetBuilder: buildActionSheet);
      if (action == null || _disposed) return;
      await _pickFiles(action.action, reset: reset);
    });
  }

  Future<void> _pickFiles(PickerAction action, {required bool reset}) async {
    final files = await FlImagePicker.showPick(
      action,
      options: options,
      requestPermission: requestPermission,
      onError: onError,
    );
    if (_disposed || files.isEmpty) return;
    final extended = <FlXFile>[];
    for (final file in files) {
      if (_disposed) return;
      extended.add(await file.toRenovated(onRenovate));
    }
    if (reset) entities.clear();
    entities.addAll(extended);
    _notify();
  }

  /// 删除图片
  Future<void> delete(FlXFile file) async {
    if (_disposed) return;
    entities.remove(file);
    _notify();
  }

  /// 全屏预览
  Future<T?> preview<T>(BuildContext context, {int initialIndex = 0}) {
    if (_disposed) return Future<T?>.value();
    return FlImagePicker.preview<T>(context, entities, initialIndex: initialIndex, previewBuilder: buildPreview);
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
