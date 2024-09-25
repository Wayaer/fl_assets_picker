## fl_assets_picker

- 简单封装 `wechat_assets_picker`,`wechat_camera_picker`

```dart

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  /// 先设置 资源渲染组件（默认仅支持图片预览）
  FlAssetsPicker.assetBuilder = (entity, bool isThumbnail) =>
      AssetBuilder(entity, isThumbnail: isThumbnail);

  /// 设置权限申请回调
  FlAssetsPicker.checkPermission = (PickerOptionalActions action) async {
    if (!isMobile) return true;
    if (action == PickerOptionalActions.gallery) {
      if (isIOS) {
        return (await Permission.photos.request()).isGranted;
      } else if (isAndroid) {
        bool resultStorage = (await Permission.storage.request()).isGranted;
        return resultStorage;
      }
      return false;
    } else if (action == PickerOptionalActions.camera) {
      final permissionState = await Permission.camera.request();
      return permissionState.isGranted;
    }
    return false;
  };

  /// 设置多选框 点击方法预览的弹出方式
  FlAssetsPicker.previewModalPopup = (_, Widget widget) => widget.popupDialog();

  /// 设置多选框 点击预览的UI组件
  FlAssetsPicker.previewBuilder = (context, entity, allEntity) {
    return FlPreviewGesturePageView(
        pageView: ExtendedImageGesturePageView.builder(
            itemCount: allEntity.length,
            controller:
            ExtendedPageController(initialPage: allEntity.indexOf(entity)),
            itemBuilder: (_, int index) =>
                FlAssetsPicker.assetBuilder(allEntity[index], false)));
  };

  /// 设置错误回调的提示
  FlAssetsPicker.errorCallback = (ErrorDes des) {
    switch (des) {
      case ErrorDes.maxBytes:
        showToast('资源过大');
        break;
      case ErrorDes.maxCount:
        showToast('超过最大数量');
        break;
      case ErrorDes.maxVideoCount:
        showToast('超过最大视频数量');
        break;
      case ErrorDes.none:
        showToast('未获取都资源');
        break;
    }
  };
  runApp();
}

```

```dart
/// 单选
SingleAssetPicker();

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
  FlAssetsPicker.showPickWithOptionalActions();
}

```