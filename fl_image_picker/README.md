[Web example](https://wayaer.github.io/fl_assets_picker/fl_image_picker/example/app/web/index.html#/)

# fl_image_picker

基于 `image_picker` 的简单封装，提供图片/视频选择、拍照、录像和全屏预览能力。

- 支持 Android、iOS、macOS、Windows、Linux、Web
- 完整示例：[example](https://github.com/Wayaer/fl_assets_picker/tree/main/fl_image_picker/example)

## 初始化

无需全局初始化，资源渲染、权限请求和来源弹层都通过重写控制器定制。

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}
```

## 控制器

```dart
class CustomImagePickerController extends ImagePickerController {
  CustomImagePickerController({
    super.entities,
    super.actions,
    super.allowPick,
    super.options = const FlImagePickerOptions(
      limit: 9,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
      maxDuration: Duration(minutes: 2),
      requestFullMetadata: true,
    ),
    super.onRenovate = compressImage,
  });

  /// 资源渲染（缩略图 / 全屏预览）
  @override
  Widget buildPreview(FlXFile file, bool isThumbnail) =>
      ImageBuilder(file, isThumbnail: isThumbnail);

  /// 权限申请
  @override
  Future<bool> requestPermission(PickerAction action) async {
    if (action == PickerAction.takePicture ||
        action == PickerAction.cameraRecording) {
      return (await Permission.camera.request()).isGranted;
    }
    if (action == PickerAction.image || action == PickerAction.video) {
      if (isIOS) return (await Permission.photos.request()).isGranted;
      if (isAndroid) return (await Permission.storage.request()).isGranted;
    }
    return true;
  }

  /// 来源选择弹层
  @override
  Widget buildActionSheet(BuildContext context, List<PickerActionOptions> actions) =>
      MyActionSheet(actions: actions);

  @override
  Future<void> delete(FlXFile file) async {
    // 自定义删除确认
    if (await confirmDelete()) return super.delete(file);
  }

  @override
  Future<T?> preview<T>(BuildContext context, {int initialIndex = 0}) {
    return super.preview(context, initialIndex: initialIndex);
  }
}
```

## 组件

```dart
/// 单选
SingleImagePicker(
  controller: controller,
  width: 80,
  height: 80,
  itemConfig: const FlImagePickerItemConfig(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  ),
  onChanged: (FlXFile? file) {},
);

/// 多选
MultipleImagePicker(
  controller: controller,
  allowDelete: true,
  builderConfig: const MultipleImagePickerListBuilderConfig(crossAxisCount: 4),
  itemConfig: const FlImagePickerItemConfig(),
  itemBuilder: (FlXFile file, int index) => MyItem(file, index),
  onChanged: (List<FlXFile> files) {},
);
```

## 静态方法

```dart
/// 选择来源
FlImagePicker.showPickActions(
  context,
  defaultImagePickerActionOptions,
  actionSheetBuilder: controller.buildActionSheet,
);

/// 直接选择
FlImagePicker.showPick(
  PickerAction.image,
  options: const FlImagePickerOptions(),
  requestPermission: controller.requestPermission,
);
FlImagePicker.showPick(
  PickerAction.multiMedia,
  options: const FlImagePickerOptions(limit: 9),
  requestPermission: controller.requestPermission,
);

/// 先选来源再选择
FlImagePicker.showPickWithActions(
  context,
  defaultImagePickerActionOptions,
  options: const FlImagePickerOptions(),
  requestPermission: controller.requestPermission,
  actionSheetBuilder: controller.buildActionSheet,
);

/// 全屏预览
FlImagePicker.preview(
  context,
  entities,
  initialIndex: 0,
  previewBuilder: controller.buildPreview,
);
```

## PickerAction

| 值 | 说明 |
| --- | --- |
| `image` | 单图片 |
| `multiImage` | 多图片 |
| `video` | 单视频 |
| `media` | 单媒体（图片或视频） |
| `multiMedia` | 多媒体 |
| `takePicture` | 相机拍照 |
| `cameraRecording` | 相机录像 |
| `cancel` | 取消 |

## 扩展能力

- `XFile.toExtended(AssetType)`：转换为 `FlXFile`。
- `FlXFile.toRenovated()`：对文件重新编辑（压缩、裁剪、上传等）。
- `FlXFile.toImageProvider()`：按 `previewed > renovated > path` 生成 `ImageProvider`。
- `FlImagePicker.buildImageProvider()`：支持 `ImageProvider`、网络地址、asset 路径、`Uint8List`、`File`、`XFile`。
- `MultipleImagePicker.convertPaths/convertUrls/toStringList/toDynamicList`。
