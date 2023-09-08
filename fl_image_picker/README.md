## fl_image_picker

- 简单封装 `image_picker`

```dart

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  /// 先设置 资源渲染组件（默认仅支持图片预览）
  FlImagePicker.assetBuilder = (entity, bool isThumbnail) =>
      AssetBuilder(entity, isThumbnail: isThumbnail);

  /// 设置权限申请回调
  FlImagePicker.checkPermission = (PickerFromType fromType) async {
    if (!isMobile) return true;
    if (fromType == PickerFromType.image || fromType == PickerFromType.video) {
      if (isIOS) {
        return (await Permission.photos.request()).isGranted;
      } else if (isAndroid) {
        bool resultStorage = (await Permission.storage.request()).isGranted;
        return resultStorage;
      }
      return false;
    } else if (fromType == PickerFromType.takePictures ||
        fromType == PickerFromType.recording) {
      final permissionState = await Permission.camera.request();
      return permissionState.isGranted;
    }
    return false;
  };

  /// 设置多选框 点击方法预览的弹出方式
  FlImagePicker.previewModalPopup = (_, Widget widget) => widget.popupDialog();

  /// 设置多选框 点击预览的UI组件
  FlImagePicker.previewBuilder = (context, entity, allEntity) {
    return FlPreviewGesturePageView(
        pageView: ExtendedImageGesturePageView.builder(
            itemCount: allEntity.length,
            controller:
            ExtendedPageController(initialPage: allEntity.indexOf(entity)),
            itemBuilder: (_, int index) =>
                FlImagePicker.assetBuilder(allEntity[index], false)));
  };

  /// 设置错误回调的提示
  FlImagePicker.errorCallback = (String value) {
    showToast(value);
  };
  runApp();
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
  /// 不同picker类型选择
  FlImagePicker.showPickerFromType();

  /// 最原始的选择器
  FlImagePicker.showPicker();

  /// 以上两个方法调用
  FlImagePicker.showPickerWithFormType();

  /// 最原始的多选择器 只能图片多选
  FlImagePicker.showImagePickerMultiple();
}

```