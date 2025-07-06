## fl_image_picker

- 简单封装 `image_picker`
- Web [Example](https://wayaer.github.io/fl_assets_picker/fl_image_picker/example/app/web/index.html#/)

- 初始化

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  /// 先设置 资源渲染组件（默认仅支持图片预览）
  FlImagePicker.imageBuilder = (entity, bool isThumbnail) =>
      ImageBuilder(entity, isThumbnail: isThumbnail);

  /// 设置权限申请回调
  FlImagePicker.checkPermission = (PickerOptionalActions action) async {
    if (!isMobile) return true;
    if (action == PickerOptionalActions.image || action == PickerOptionalActions.video) {
      if (isIOS) {
        return (await Permission.photos.request()).isGranted;
      } else if (isAndroid) {
        bool resultStorage = (await Permission.storage.request()).isGranted;
        return resultStorage;
      }
      return false;
    } else if (action == PickerOptionalActions.takePictures ||
        action == PickerOptionalActions.recording) {
      final permissionState = await Permission.camera.request();
      return permissionState.isGranted;
    }
    return false;
  };
  runApp();
}

```

- 自定义 ImagePickerController

```dart
/// 自定义 ImagePickerController
class CustomImagePickerController extends ImagePickerController {
  CustomImagePickerController({super.actions,
    super.allowPick = true,
    super.entities,
    super.options = const ImagePickerOptions()});

  @override
  Future<void> pick(PickerAction action, {bool reset = false}) async {
    log('Start Pick');
    super.pick(action, reset: reset);
  }

  @override
  Future<void> pickActions(BuildContext context,
      {bool requestFocus = true, bool reset = false}) async {
    log('Start Pick Actions');
    super.pickActions(context, reset: reset, requestFocus: requestFocus);
  }

  @override
  FlXFileRenovate? get onRenovate =>
          (AssetType type, XFile file) async {
        if (type == AssetType.image) {
          return await compressImage(file);
        }
        return null;
      };

  @override
  Future<void> delete(FlXFile file) async {
    final value = await CupertinoAlertDialog(
        content: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            constraints: const BoxConstraints(maxHeight: 100),
            child: const Text('确定要删除么')),
        actions: [
          Universal(
              height: 45,
              alignment: Alignment.center,
              onTap: () {
                pop(false);
              },
              child: const BText('取消', fontSize: 14, color: Colors.grey)),
          Universal(
              height: 45,
              alignment: Alignment.center,
              onTap: () {
                pop(true);
              },
              child: const BText('确定', fontSize: 14, color: Colors.grey)),
        ]).popupCupertinoModal<bool?>();
    if (value == true) return super.delete(file);
  }

  @override
  Future<T?> preview<T>(BuildContext context, {int initialIndex = 0}) async {
    final builder = FlImagePickerPreviewPageView(
        entities: entities, initialIndex: initialIndex);
    if (context.mounted) return await builder.popupDialog<T>();
    return null;
  }
}
```

```dart
/// 单选
SingleImagePicker();

/// 多选
MultipleImagePicker();
```

直接调用方法选择

```dart

void fun() {

  /// 选择 action
  FlImagePicker.showPickActions();

  /// 调用 ImagePicker
  FlImagePicker.showPick();

  /// 以上两个方法依次调用
  FlImagePicker.showPickWithActions();
}

```