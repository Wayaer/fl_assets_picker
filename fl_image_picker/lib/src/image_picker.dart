part of '../fl_image_picker.dart';

typedef FlImagePickerCheckPermission = Future<bool> Function(
    PickerAction action);

typedef PickerActionBuilder = Widget Function(
    BuildContext context, List<PickerActionOptions> actions);

typedef FlImageBuilder = Widget Function(
    ExtendedXFile entity, bool isThumbnail);

enum AssetType {
  /// The asset is an media
  media,

  /// The asset is an image file.
  image,

  /// The asset is an video file.
  video,
}

enum PickerAction {
  /// 仅图片
  image,

  /// 仅图片 多选
  multiImage,

  /// 仅视频
  video,

  /// 仅媒体
  media,

  /// 仅媒体 多选
  multiMedia,

  /// 拍照
  takePicture,

  /// 相机录像
  cameraRecording,

  /// 取消
  cancel,
  ;

  /// to [AssetType]
  AssetType toAssetType() {
    switch (this) {
      case PickerAction.image:
        return AssetType.image;
      case PickerAction.multiImage:
        return AssetType.image;
      case PickerAction.video:
        return AssetType.video;
      case PickerAction.takePicture:
        return AssetType.image;
      case PickerAction.cameraRecording:
        return AssetType.video;
      case PickerAction.cancel:
        return AssetType.media;
      case PickerAction.media:
        return AssetType.media;
      case PickerAction.multiMedia:
        return AssetType.media;
    }
  }

  /// pick image or video
  Future<List<XFile>> pick(
      {ImagePickerOptions options = const ImagePickerOptions()}) async {
    List<XFile> xFils = [];
    switch (this) {
      case PickerAction.image:
        final result = await FlImagePicker.imagePicker.pickImage(
            source: ImageSource.gallery,
            maxWidth: options.maxWidth,
            maxHeight: options.maxHeight,
            imageQuality: options.imageQuality,
            requestFullMetadata: options.requestFullMetadata,
            preferredCameraDevice: options.preferredCameraDevice);
        if (result != null) xFils.add(result);
        break;
      case PickerAction.multiImage:
        xFils = await FlImagePicker.imagePicker.pickMultiImage(
            limit: options.limit,
            maxWidth: options.maxWidth,
            maxHeight: options.maxHeight,
            imageQuality: options.imageQuality,
            requestFullMetadata: options.requestFullMetadata);
        break;
      case PickerAction.video:
        final result = await FlImagePicker.imagePicker.pickVideo(
            source: ImageSource.gallery, maxDuration: options.maxDuration);
        if (result != null) xFils.add(result);
        break;
      case PickerAction.takePicture:
        final result = await FlImagePicker.imagePicker.pickImage(
            source: ImageSource.camera,
            maxWidth: options.maxWidth,
            maxHeight: options.maxHeight,
            imageQuality: options.imageQuality,
            requestFullMetadata: options.requestFullMetadata,
            preferredCameraDevice: options.preferredCameraDevice);
        if (result != null) xFils.add(result);
        break;
      case PickerAction.cameraRecording:
        final result = await FlImagePicker.imagePicker.pickVideo(
            source: ImageSource.camera, maxDuration: options.maxDuration);
        if (result != null) xFils.add(result);
        break;
      case PickerAction.media:
        final result = await FlImagePicker.imagePicker.pickMedia(
            maxWidth: options.maxWidth,
            maxHeight: options.maxHeight,
            imageQuality: options.imageQuality,
            requestFullMetadata: options.requestFullMetadata);
        if (result != null) xFils.add(result);
        break;
      case PickerAction.multiMedia:
        xFils = await FlImagePicker.imagePicker.pickMultipleMedia(
            limit: options.limit,
            maxWidth: options.maxWidth,
            maxHeight: options.maxHeight,
            imageQuality: options.imageQuality,
            requestFullMetadata: options.requestFullMetadata);
        break;
      case PickerAction.cancel:
    }
    return xFils;
  }
}

/// [ImagePicker] pick options
class ImagePickerOptions {
  const ImagePickerOptions({
    this.limit,
    this.preferredCameraDevice = CameraDevice.rear,

    /// image
    this.maxWidth,
    this.maxHeight,
    this.imageQuality,

    /// video
    this.maxDuration,
  });

  /// multiple
  final int? limit;

  /// single
  final CameraDevice preferredCameraDevice;

  /// image
  final double? maxWidth;
  final double? maxHeight;
  final int? imageQuality;
  final bool requestFullMetadata = true;

  /// video
  final Duration? maxDuration;
}

/// 全部默认 [ImageBuilder]
FlImageBuilder get _defaultImageBuilder =>
    (ExtendedXFile entity, bool isThumbnail) {
      Widget unsupported() => const Center(child: Text('No preview'));
      if (entity.type == AssetType.image) {
        final imageProvider = entity.toImageProvider();
        if (imageProvider != null) {
          return Image(
              image: imageProvider,
              fit: isThumbnail ? BoxFit.cover : BoxFit.contain);
        }
      }
      return unsupported();
    };

/// 默认 [PickerActionBuilder]
PickerActionBuilder get _defaultActionsBuilder =>
    (_, List<PickerActionOptions> actions) => FlPickerActionBuilder(actions);

abstract class FlImagePicker extends StatefulWidget {
  /// image picker
  static ImagePicker imagePicker = ImagePicker();

  /// imageBuilder
  static FlImageBuilder imageBuilder = _defaultImageBuilder;

  /// 权限申请
  static FlImagePickerCheckPermission? checkPermission;

  /// 类型来源选择器
  static PickerActionBuilder actionsBuilder = _defaultActionsBuilder;

  const FlImagePicker({
    super.key,
    this.itemConfig = const FlImagePickerItemConfig(),
    required this.controller,
    this.disposeController = false,
  });

  /// 资源控制器
  final ImagePickerController controller;

  /// dispose controller.dispose();
  final bool disposeController;

  /// item 样式配置
  final FlImagePickerItemConfig itemConfig;

  /// value 转换为 [ImageProvider]
  static ImageProvider? buildImageProvider(dynamic value) {
    if (value is String) {
      if (value.startsWith('http') || value.startsWith('blob:http')) {
        return NetworkImage(value);
      } else {
        return AssetImage(value);
      }
    } else if (value is Uint8List) {
      return MemoryImage(value);
    } else if (value is File || value is XFile) {
      return FileImage(value);
    } else if (value is XFile) {
      return FileImage(File(value.path));
    }
    return null;
  }

  /// show pick actions
  /// show pick
  static Future<List<ExtendedXFile>> showPickWithActions(
    BuildContext context,
    List<PickerActionOptions> actions, {
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    final actionOption = await showPickActions(context, actions);
    if (actionOption == null) return [];
    return await showPick(actionOption.action, options: options);
  }

  /// show pick actions
  static Future<PickerActionOptions?> showPickActions(
      BuildContext context, List<PickerActionOptions> actions) async {
    if (actions.isEmpty) return null;
    PickerActionOptions? action;
    final effectiveActions =
        actions.where((e) => e.action != PickerAction.cancel);
    if (effectiveActions.length == 1) {
      action = effectiveActions.first;
    } else {
      action = await showCupertinoModalPopup<PickerActionOptions?>(
          context: context,
          builder: (BuildContext context) => actionsBuilder(context, actions));
    }
    return action;
  }

  /// show pick
  static Future<List<ExtendedXFile>> showPick(PickerAction action,
      {ImagePickerOptions options = const ImagePickerOptions()}) async {
    if (action == PickerAction.cancel) return [];
    final permissionState = await checkPermission?.call(action) ?? true;
    if (permissionState) {
      final files = await action.pick(options: options);
      return files.map((file) {
        AssetType assetType = AssetType.media;
        final mimeType = file.mimeType ?? lookupMimeType(file.path);
        if (mimeType?.startsWith('video') ?? false) {
          assetType = AssetType.video;
        } else if (mimeType?.startsWith('image') ?? false) {
          assetType = AssetType.image;
        }
        return file.toExtended(assetType);
      }).toList();
    }
    return [];
  }
}

/// 图片预览器
class FlImagePickerPreviewModal extends StatelessWidget {
  const FlImagePickerPreviewModal({
    super.key,
    required this.child,
    this.close,
    this.overlay,
    this.backgroundColor = Colors.black87,
  });

  final Widget child;

  /// 关闭按钮
  final Widget? close;

  /// 在图片的上层
  final Widget? overlay;

  /// 背景色
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
        color: backgroundColor,
        child: Stack(children: [
          SizedBox.expand(child: child),
          if (overlay != null) SizedBox.expand(child: overlay!),
          Positioned(
              right: 6,
              top: MediaQuery.of(context).viewPadding.top,
              child: close ?? const CloseButton(color: Colors.white)),
        ]));
  }
}

/// 图片预览器
class FlImagePickerPreviewPageView extends StatelessWidget {
  const FlImagePickerPreviewPageView(
      {super.key, required this.controller, this.initialIndex = 0});

  final ImagePickerController controller;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    final length = controller.entities.length;
    final initialPage = min(length, initialIndex);
    return FlImagePickerPreviewModal(
        child: PageView.builder(
            controller: PageController(initialPage: initialPage),
            itemCount: length,
            itemBuilder: (_, int index) => Center(
                child: FlImagePicker.imageBuilder(
                    controller.entities[index], false))));
  }
}
