## fl_assets_picker

- 封装 `wechat_assets_picker`,`wechat_camera_picker`

- 初始化

```dart

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  /// 先设置 资源渲染组件（默认仅支持图片预览）
  FlAssetsPicker.assetBuilder = (entity, bool isThumbnail) =>
      AssetBuilder(entity, isThumbnail: isThumbnail);

  /// 设置权限申请回调
  FlAssetsPicker.checkPermission = (PickerAction action) async {
    if (!isMobile) return true;
    if (action == PickerAction.gallery) {
      if (isIOS) {
        return (await Permission.photos.request()).isGranted;
      } else if (isAndroid) {
        bool resultStorage = (await Permission.storage.request()).isGranted;
        return resultStorage;
      }
      return false;
    } else if (action == PickerAction.camera) {
      final permissionState = await Permission.camera.request();
      return permissionState.isGranted;
    }
    return false;
  };
}

```

- 自定义 AssetsPickerController

```dart

/// 自定义 AssetsPickerController
class CustomAssetsPickerController extends AssetsPickerController {
  CustomAssetsPickerController({
    super.actions,
    super.allowPick = true,
    super.entities,
    super.assetConfig = const AssetPickerConfig(),
    super.cameraConfig = const CameraPickerConfig(),
    super.useRootNavigator = true,
    super.pageRouteBuilderForAssetPicker,
    super.pageRouteBuilderForCameraPicker,
    super.getFileAsync = true,
    super.getThumbnailDataAsync = true,
  });

  @override
  Future<void> pickAssets(BuildContext context, {bool reset = false}) {
    log('Start Pick Assets');
    return super.pickAssets(context, reset: reset);
  }

  @override
  Future<void> pickFromCamera(BuildContext context, {bool reset = false}) {
    log('Start Pick From Camera');
    return super.pickFromCamera(context, reset: reset);
  }

  @override
  Future<void> pickActions(BuildContext context,
      {bool unfocus = true, bool reset = false}) async {
    log('Start Pick Actions');
    super.pickActions(context, reset: reset, unfocus: unfocus);
  }

  @override
  FlAssetEntityRenovate? get onRenovate =>
          (AssetEntity asset) async {
        if (asset.type == AssetType.image) {
          final file = await asset.file;
          if (file != null) return await compressImage(file);
        }
        return null;
      };

  @override
  Future<void> delete(FlAssetEntity asset) async {
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
    if (value == true) return super.delete(asset);
  }

  @override
  Future<T?> preview<T>(BuildContext context, {int initialIndex = 0}) async {
    final builder = FlAssetsPickerPreviewPageView(
        entities: entities, initialIndex: initialIndex);
    if (context.mounted) return await builder.popupDialog<T>();
    return null;
  }
}
```

```dart
/// 单选
SingleAssetsPicker();

/// 多选
MultipleAssetPicker();
```

直接调用方法选择

```dart

void fun() {
  /// 选择Actions
  FlAssetsPicker.showPickActions();

  /// 最原始的资源选择器
  FlAssetsPicker.showPickAssets();
  FlAssetsPicker.showPickAssetsWithDelegate();

  /// 从相机拍摄
  FlAssetsPicker.showPickFromCamera();

  /// 依次选择Actions和资源选择器
  FlAssetsPicker.showPickWithActions();
}

```