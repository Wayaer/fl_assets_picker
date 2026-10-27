part of '../fl_image_picker.dart';

typedef FlImagePreviewBuilder = Widget Function(FlXFile file, bool isThumbnail);

@Deprecated('Use FlImagePreviewBuilder instead')
typedef FlImageBuilder = FlImagePreviewBuilder;

typedef FlImagePickerPermissionRequest = Future<bool> Function(PickerAction action);

@Deprecated('Use FlImagePickerPermissionRequest instead')
typedef FlImagePickerCheckPermission = FlImagePickerPermissionRequest;

typedef FlImagePickerActionSheetBuilder = Widget Function(BuildContext context, List<PickerActionOptions> actions);

@Deprecated('Use FlImagePickerActionSheetBuilder instead')
typedef PickerActionBuilder = FlImagePickerActionSheetBuilder;

typedef FlImagePickerErrorHandler = void Function(Object error, StackTrace stackTrace);

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
  image(AssetType.image),

  /// 仅图片 多选
  multiImage(AssetType.image),

  /// 仅视频
  video(AssetType.video),

  /// 仅媒体
  media(AssetType.media),

  /// 仅媒体 多选
  multiMedia(AssetType.media),

  /// 拍照
  takePicture(AssetType.image),

  /// 相机录像
  cameraRecording(AssetType.video),

  /// 取消
  cancel(AssetType.media);

  const PickerAction(this.assetType);

  /// 对应的 [AssetType]
  final AssetType assetType;

  /// pick image or video
  Future<List<XFile>> pick({FlImagePickerOptions options = const FlImagePickerOptions()}) async {
    List<XFile> xFils = [];
    switch (this) {
      case PickerAction.image:
        final result = await FlImagePicker.imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: options.maxWidth,
          maxHeight: options.maxHeight,
          imageQuality: options.imageQuality,
          requestFullMetadata: options.requestFullMetadata,
          preferredCameraDevice: options.preferredCameraDevice,
        );
        if (result != null) xFils.add(result);
        break;
      case PickerAction.multiImage:
        xFils = await FlImagePicker.imagePicker.pickMultiImage(
          limit: options.limit,
          maxWidth: options.maxWidth,
          maxHeight: options.maxHeight,
          imageQuality: options.imageQuality,
          requestFullMetadata: options.requestFullMetadata,
        );
        break;
      case PickerAction.video:
        final result = await FlImagePicker.imagePicker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: options.maxDuration,
        );
        if (result != null) xFils.add(result);
        break;
      case PickerAction.takePicture:
        final result = await FlImagePicker.imagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: options.maxWidth,
          maxHeight: options.maxHeight,
          imageQuality: options.imageQuality,
          requestFullMetadata: options.requestFullMetadata,
          preferredCameraDevice: options.preferredCameraDevice,
        );
        if (result != null) xFils.add(result);
        break;
      case PickerAction.cameraRecording:
        final result = await FlImagePicker.imagePicker.pickVideo(
          source: ImageSource.camera,
          maxDuration: options.maxDuration,
          preferredCameraDevice: options.preferredCameraDevice,
        );
        if (result != null) xFils.add(result);
        break;
      case PickerAction.media:
        final result = await FlImagePicker.imagePicker.pickMedia(
          maxWidth: options.maxWidth,
          maxHeight: options.maxHeight,
          imageQuality: options.imageQuality,
          requestFullMetadata: options.requestFullMetadata,
        );
        if (result != null) xFils.add(result);
        break;
      case PickerAction.multiMedia:
        xFils = await FlImagePicker.imagePicker.pickMultipleMedia(
          limit: options.limit,
          maxWidth: options.maxWidth,
          maxHeight: options.maxHeight,
          imageQuality: options.imageQuality,
          requestFullMetadata: options.requestFullMetadata,
        );
        break;
      case PickerAction.cancel:
    }
    return xFils;
  }
}

/// [ImagePicker] pick options
class FlImagePickerOptions {
  const FlImagePickerOptions({
    this.limit,
    this.preferredCameraDevice = CameraDevice.rear,

    /// image
    this.maxWidth,
    this.maxHeight,
    this.imageQuality,
    this.requestFullMetadata = true,

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

  /// 是否请求完整的元数据（例如地理位置）
  final bool requestFullMetadata;

  /// video
  final Duration? maxDuration;
}

/// 默认资源预览渲染，子类可通过 [ImagePickerController.buildPreview] 重写
Widget _defaultImagePreviewBuilder(FlXFile file, bool isThumbnail) {
  Widget unsupported() => const Center(child: Text('No preview'));
  if (file.type == AssetType.image) {
    final imageProvider = file.toImageProvider();
    if (imageProvider != null) {
      return Image(image: imageProvider, fit: isThumbnail ? BoxFit.cover : BoxFit.contain);
    }
  }
  return unsupported();
}

/// 默认来源选择弹层，子类可通过 [ImagePickerController.buildActionSheet] 重写
Widget _defaultActionSheetBuilder(BuildContext context, List<PickerActionOptions> actions) =>
    FlPickerActionBuilder(actions);

void _reportPickerError(FlImagePickerErrorHandler? onError, Object error, StackTrace stackTrace) {
  if (onError != null) {
    onError(error, stackTrace);
    return;
  }
  FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stackTrace, library: 'fl_image_picker'));
}

abstract class FlImagePicker extends StatefulWidget {
  /// image picker，可通过替换该实例注入自定义实现
  static ImagePicker imagePicker = ImagePicker();

  const FlImagePicker({
    super.key,
    this.itemConfig = const FlImagePickerItemConfig(),
    required this.controller,
    this.disposeController = false,
    this.allowDelete = true,
  });

  /// 资源控制器
  final ImagePickerController controller;

  /// dispose controller.dispose();
  final bool disposeController;

  /// item 样式配置
  final FlImagePickerItemConfig itemConfig;

  /// 是否显示删除按钮
  final bool allowDelete;

  /// value 转换为 [ImageProvider]
  ///
  /// 支持 [ImageProvider]、网络地址、本地文件路径、asset 路径、[Uint8List]、[File]、[XFile]
  static ImageProvider? buildImageProvider(dynamic value) {
    if (value is ImageProvider) return value;
    if (value is String) {
      if (value.startsWith('http') || value.startsWith('blob:')) {
        return NetworkImage(value);
      }
      if (!kIsWeb && File(value).existsSync()) {
        return FileImage(File(value));
      }
      return AssetImage(value);
    }
    if (value is Uint8List) return MemoryImage(value);
    if (value is File) {
      if (kIsWeb) return NetworkImage(value.path);
      return FileImage(value);
    }
    if (value is XFile) {
      if (kIsWeb) return NetworkImage(value.path);
      return FileImage(File(value.path));
    }
    return null;
  }

  /// show pick actions
  /// show pick
  static Future<List<FlXFile>> showPickWithActions(
    BuildContext context,
    List<PickerActionOptions> actions, {
    FlImagePickerOptions options = const FlImagePickerOptions(),
    FlImagePickerPermissionRequest? requestPermission,
    FlImagePickerActionSheetBuilder actionSheetBuilder = _defaultActionSheetBuilder,
    FlImagePickerErrorHandler? onError,
  }) async {
    final actionOption = await showPickActions(context, actions, actionSheetBuilder: actionSheetBuilder);
    if (actionOption == null) return [];
    return showPick(actionOption.action, options: options, requestPermission: requestPermission, onError: onError);
  }

  /// show pick actions
  static Future<PickerActionOptions?> showPickActions(
    BuildContext context,
    List<PickerActionOptions> actions, {
    FlImagePickerActionSheetBuilder actionSheetBuilder = _defaultActionSheetBuilder,
  }) async {
    if (actions.isEmpty) return null;
    PickerActionOptions? action;
    final effectiveActions = actions.where((e) => e.action != PickerAction.cancel);
    if (effectiveActions.isEmpty) return null;
    if (effectiveActions.length == 1) {
      action = effectiveActions.first;
    } else {
      action = await showCupertinoModalPopup<PickerActionOptions?>(
        context: context,
        builder: (BuildContext context) => actionSheetBuilder(context, actions),
      );
    }
    return action;
  }

  /// show pick
  static Future<List<FlXFile>> showPick(
    PickerAction action, {
    FlImagePickerOptions options = const FlImagePickerOptions(),
    FlImagePickerPermissionRequest? requestPermission,
    FlImagePickerErrorHandler? onError,
  }) async {
    if (action == PickerAction.cancel) return [];
    try {
      final permissionState = await requestPermission?.call(action) ?? true;
      if (!permissionState) return [];
      final files = await action.pick(options: options);
      return files.map((file) {
        AssetType assetType = AssetType.media;
        final mimeType = file.mimeType ?? lookupMimeType(file.name) ?? lookupMimeType(file.path);
        if (mimeType?.startsWith('video') ?? false) {
          assetType = AssetType.video;
        } else if (mimeType?.startsWith('image') ?? false) {
          assetType = AssetType.image;
        }
        return file.toExtended(assetType);
      }).toList();
    } catch (error, stackTrace) {
      _reportPickerError(onError, error, stackTrace);
      return [];
    }
  }

  /// 全屏预览
  static Future<T?> preview<T>(
    BuildContext context,
    List<FlXFile> entities, {
    int initialIndex = 0,
    FlImagePreviewBuilder previewBuilder = _defaultImagePreviewBuilder,
  }) async {
    if (entities.isEmpty) return null;
    final builder = FlImagePickerPreviewPageView(
      entities: entities,
      initialIndex: initialIndex,
      previewBuilder: previewBuilder,
    );
    if (context.mounted) {
      return await showCupertinoModalPopup<T>(context: context, builder: (_) => builder);
    }
    return null;
  }
}

abstract class FlImagePickerState<T extends FlImagePicker> extends State<T> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(listener);
  }

  void listener() {
    if (mounted) setState(() {});
  }

  Widget buildVideo(FlXFile file, Widget current) {
    final config = widget.itemConfig;
    if (file.type == AssetType.video) {
      current = Stack(
        children: [
          SizedBox.expand(child: current),
          Align(alignment: Alignment.center, child: config.play),
        ],
      );
    }
    return current;
  }

  Widget buildBackgroundColor(Widget current) {
    final config = widget.itemConfig;
    if (config.backgroundColor != null) {
      current = ColoredBox(color: config.backgroundColor!, child: current);
    }
    return current;
  }

  Widget buildBorderRadius(Widget current) {
    final config = widget.itemConfig;
    if (config.borderRadius != null) {
      current = ClipRRect(borderRadius: config.borderRadius!, child: current);
    }
    return current;
  }

  Widget buildPickActions(Widget current, {bool reset = false}) {
    if (widget.controller.allowPick) {
      current = GestureDetector(
        onTap: () {
          widget.controller.pickActions(context, reset: reset);
        },
        child: current,
      );
    }
    return current;
  }

  @override
  void dispose() {
    widget.controller.removeListener(listener);
    if (widget.disposeController) widget.controller.dispose();
    super.dispose();
  }
}
