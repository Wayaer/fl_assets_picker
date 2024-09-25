## fl_image_picker

- 简单封装 `image_picker`
- Web [image_picker](https://wayaer.github.io/fl_assets_picker/fl_image_picker/example/app/web/index.html#/)

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
                FlImagePicker.imageBuilder(allEntity[index], false)));
  };

  /// 设置错误回调的提示
  FlImagePicker.errorCallback = (ErrorDes des) {
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
    }
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
  /// 选择Actions
  FlImagePicker.showPickActions();

  /// 最原始的选择器
  FlImagePicker.showPick();

  /// 最原始的多选择器 只能图片多选
  FlImagePicker.showPickMultipleImage();

  /// 以上两个方法依次调用
  FlImagePicker.showPickWithOptionalActions();
}

```