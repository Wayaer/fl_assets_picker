# fl_assets_picker

基于 `wechat_assets_picker`、`wechat_camera_picker` 的简单封装，提供图库单选/多选、相机拍摄和全屏预览能力。

- 图库选择：Android、iOS、macOS
- 相机拍摄：Android、iOS
- 完整示例：[example](https://github.com/Wayaer/fl_assets_picker/tree/main/fl_assets_picker/example)

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
class CustomAssetsPickerController extends AssetsPickerController {
  CustomAssetsPickerController({
    super.entities,
    super.actions,
    super.allowPick,
    super.assetConfig = const AssetPickerConfig(maxAssets: 9),
    super.cameraConfig = const CameraPickerConfig(enableRecording: true),
    super.useRootNavigator,
    super.pageRouteBuilderForAssetPicker,
    super.pageRouteBuilderForCameraPicker,
    super.getFileAsync = true,
    super.getThumbnailDataAsync = true,
    super.onRenovate = compressImage,
  });

  /// 资源渲染（缩略图 / 全屏预览）
  @override
  Widget buildPreview(FlAssetEntity asset, bool isThumbnail) =>
      AssetBuilder(asset, isThumbnail: isThumbnail);

  /// 权限申请
  @override
  Future<bool> requestPermission(PickerAction action) async {
    if (action == PickerAction.camera) {
      return (await Permission.camera.request()).isGranted;
    }
    if (action == PickerAction.gallery) {
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
  Future<void> delete(FlAssetEntity asset) async {
    // 自定义删除确认
    if (await confirmDelete()) return super.delete(asset);
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
SingleAssetsPicker(
  controller: controller,
  width: 80,
  height: 80,
  itemConfig: const FlAssetsPickerItemConfig(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  ),
  onChanged: (FlAssetEntity? asset) {},
);

/// 多选
MultipleAssetsPicker(
  controller: controller,
  allowDelete: true,
  builderConfig: const MultipleAssetsPickerListBuilderConfig(crossAxisCount: 4),
  itemConfig: const FlAssetsPickerItemConfig(),
  itemBuilder: (FlAssetEntity asset, int index) => MyItem(asset, index),
  onChanged: (List<FlAssetEntity> assets) {},
);
```

## 静态方法

```dart
/// 选择来源
FlAssetsPicker.showPickActions(
  context,
  defaultPickerActionOptions,
  actionSheetBuilder: controller.buildActionSheet,
);

/// 图库 / 相机
FlAssetsPicker.showPickAssets(
  context,
  pickerConfig: const AssetPickerConfig(),
  requestPermission: controller.requestPermission,
);
FlAssetsPicker.showPickFromCamera(
  context,
  pickerConfig: const CameraPickerConfig(),
  requestPermission: controller.requestPermission,
);

/// 先选来源再选择资源
FlAssetsPicker.showPickWithActions(
  context,
  defaultPickerActionOptions,
  options: const FlAssetPickerOptions(),
  requestPermission: controller.requestPermission,
  actionSheetBuilder: controller.buildActionSheet,
);

/// 全屏预览
FlAssetsPicker.preview(
  context,
  entities,
  initialIndex: 0,
  previewBuilder: controller.buildPreview,
);
```

## 扩展能力

- `AssetEntity.toExtended()`：转换为 `FlAssetEntity`，可同时获取文件、缩略图和 `renovated` 数据。
- `FlAssetEntity.toAssetEntity()`：还原为 `AssetEntity`。
- `FlAssetEntity.toImageProvider()`：按 `previewed > renovated > fileAsync` 生成 `ImageProvider`。
- `FlAssetsPicker.buildImageProvider()`：支持 `ImageProvider`、网络地址、asset 路径、`Uint8List`、`File`、`XFile`。
- `AssetPickerConfig.copyWith/merge`、`CameraPickerConfig.copyWith/merge`：与上游最新字段保持同步。
- `MultipleAssetsPicker.convertPaths/convertUrls/toStringList/toDynamicList`。
