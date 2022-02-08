import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_curiosity/flutter_curiosity.dart';
import 'package:image/image.dart';
import 'package:universally/universally.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

typedef ImageOSSPathCallback = void Function(String imageOSSPath, BoxFit fit);
typedef VideoOperationCallback = Future<AssetsModel?> Function(
    AssetsModel assets);

VideoOperationCallback? compressVideoFun;
VideoOperationCallback? getVideoFirstFrameFun;



class AssetsModel {
  AssetsModel({
    required this.path,
    this.assetsType,
    this.size,
    this.firstFramePath,
  });

  String path;
  String? firstFramePath;
  AssetsType? assetsType;
  Size? size;
}

const List<String> imageSelectType = ['图库选择', '相机拍摄'];

class AssetsUtils {
  // static const int _maxSize = 33554432;

  static const int _maxSize = 20971520;

  // static const int _maxSize = 10485760;

  ///选择图片或者视频
  static Future<AssetsModel?> selectAssets(
    BuildContext context, {

    ///图片剪切宽高比
    double? cropAspectRatio,

    ///选择的类型
    AssetsType? assetsType,

    ///一次最多选择几个资源
    int? maxAssets,

    ///图片剪切压缩比
    ImageCompressionRatio? compressionRatio,
  }) async {
    if (!isMobile) {
      if (isDebug) showToast('仅支持手机端');
      return null;
    }
    final index = await pickerSingleChoice(imageSelectType);
    if (index == null) return null;
    final text = imageSelectType[index];
    AssetEntity? entity;
    RequestType requestType = RequestType.common;
    switch (assetsType) {
      case AssetsType.image:
        requestType = RequestType.image;
        break;
      case AssetsType.video:
        requestType = RequestType.video;
        break;
      case AssetsType.all:
        requestType = RequestType.common;
        break;
      default:
        requestType = RequestType.image;
    }
    if (text == imageSelectType[0]) {
      final List<AssetEntity>? assets = await AssetPicker.pickAssets(context,
          maxAssets: 1, requestType: requestType, selectedAssets: []
          // specialPickerType: SpecialPickerType.wechatMoment,
          );
      if (assets == null || assets.isEmpty) return null;
      entity = assets[0];
    } else if (text == imageSelectType[1]) {
      final state = await getAllPermissions(
          [Permission.camera, Permission.storage], '拍照使用');
      if (!state) return null;
      entity = await CameraPicker.pickFromCamera(context,
          resolutionPreset: ResolutionPreset.high);
    }
    // setStatusBarLight(false);
    if (entity == null) return null;
    final Uint8List? originBytes = await entity.originBytes;
    if (originBytes == null) {
      showToast('无法获取该资源');
      return null;
    }

    if (entity.type == AssetType.image) {
      if (originBytes.length > _maxSize / 2) {
        showToast('最大选择10M图片');
        return null;
      }

      ///剪切图片
      final cropPath = await cropImage(originBytes,
          cropAspectRatio: cropAspectRatio, compressionRatio: compressionRatio);
      if (cropPath != null) {
        return AssetsModel(
            path: cropPath, assetsType: AssetsType.image, size: entity.size);
      }
    } else if (entity.type == AssetType.video) {
      if (originBytes.length > _maxSize) {
        showToast('最大选择20M视频');
        return null;
      }

      final File? file = await entity.file;
      if (file == null) {
        showToast('无法获取该视频');
        return null;
      }

      ///视频选择
      final size = entity.size;
      AssetsModel? asset = AssetsModel(
          path: file.path, assetsType: AssetsType.video, size: size);
      if (originBytes.length > _maxSize / 3 && compressVideoFun != null) {
        /// 压缩 10M 以上的视频
        asset = await compressVideoFun!(asset);
      } else if (getVideoFirstFrameFun != null) {
        ///获取视频第一帧图片
        asset = await getVideoFirstFrameFun!(asset);
      }
      return asset;
    }
    return null;
  }

  /// 上传图片或视频
  static Future<FileModel?> uploadFile(AssetsModel asset) async {
    final formData = getFileFormData(path: asset.path);
    final data =
        await BaseDio().upload(GlobalConfig().currentUploadUrl, formData);
    if (resultSuccessFail(data)) {
      if (data.data is List) return getFileModelList(data.data as List)[0];
      if (data.data is Map) {
        return FileModel.fromJson(data.data as Map<String, dynamic>);
      }
      if (data.data is String) return FileModel(imageUrl: data.data as String);
    }
    return null;
  }

  ///选择并上传图片或视频
  static Future<FileModel?> selectAndUpload(
    BuildContext context, {

    /// 图片选择宽高比 默认为1
    double cropAspectRatio = 1,
    int maxAssets = 1,
    bool isDelete = true,
    AssetsType assetsType = AssetsType.image,

    ///图片剪切压缩比 默认为 [ImageCompressionRatio.medium]
    ImageCompressionRatio? compressionRatio,
  }) async {
    final asset = await selectAssets(context,
        cropAspectRatio: cropAspectRatio,
        maxAssets: maxAssets,
        assetsType: assetsType,
        compressionRatio: compressionRatio);
    if (asset == null) return null;
    final fileModel = await uploadFile(asset);
    return fileModel;
  }
}

/// 全局文件长传添加 map数据
Map<String, dynamic>? fileFormDataMap;

FormData getFileFormData(
    {String? path, Map<String, dynamic>? fromMap, List<String>? paths}) {
  fromMap ??= <String, dynamic>{};
  if (path != null) {
    final MultipartFile file = MultipartFile.fromFileSync(path);
    if (GlobalConfig().currentStyle == AppStyle.serverTools ||
        GlobalConfig().currentStyle == AppStyle.fireControl) {
      fromMap.addAll({'files': file});
    } else {
      fromMap.addAll({'file': file});
    }
  }
  if (paths != null) {
    fromMap.addAll(
        {'files': paths.builder((p0) => MultipartFile.fromFileSync(p0))});
  }
  if (fileFormDataMap != null) fromMap.addAll(fileFormDataMap!);
  return FormData.fromMap(fromMap);
}

//保存图片到相册并发送通知
Future<void> saveImageToGalleryAndToast(GlobalKey imageKey,
    {String? imageName}) async {
  if (!await getAllPermissions(
      [Permission.photos, Permission.storage], '访问相册和手机存储')) {
    showToast('无法访问相册和手机存储 不能保存');
    return;
  }

  final byteData = await imageKey.screenshots(format: ImageByteFormat.png);
  if (byteData == null) {
    showToast('图片截取失败');
    return;
  }
  final assetEntity = await PhotoManager.editor.saveImage(
      byteData.buffer.asUint8List(),
      title: imageName,
      desc: imageName);
  showToast(assetEntity == null ? '保存失败' : '保存成功');
}

Future<String?> saveFileToPath(
    String path, String name, List<int> bytes) async {
  Directory dir = Directory(path);
  if (!dir.existsSync()) {
    dir = await dir.create(recursive: true);
    if (!dir.existsSync()) {
      log('路径创建失败');
      return null;
    }
  }
  path += name;
  final File file = File(path);
  await file.writeAsBytes(bytes);
  await file.create();
  if (File(path).existsSync()) {
    log('文件保存成功 => $path');
    return path;
  }
  return null;
}

//保存图片到相册
Future<String?> saveImageGallery(Uint8List fileData) async {
  final AssetEntity? imageEntity =
      await PhotoManager.editor.saveImage(fileData);
  if (imageEntity != null) {
    final File? file = await imageEntity.file;
    if (file != null) file.path;
  }
  return null;
}

/// 裁剪图片
Future<String?> cropImage(Uint8List image,
        {ImageCompressionRatio? compressionRatio, double? cropAspectRatio}) =>
    showCupertinoBottomPopup<String?>(
        widget: _CropImage(
            image: image,
            cropAspectRatio: cropAspectRatio,
            compressionRatio: compressionRatio));

class _CropImage extends StatefulWidget {
  const _CropImage(
      {Key? key,
      required this.image,
      double? cropAspectRatio,
      ImageCompressionRatio? compressionRatio})
      : compressionRatio = compressionRatio ?? ImageCompressionRatio.medium,
        cropAspectRatio = cropAspectRatio ?? CropAspectRatios.ratio1_1,
        super(key: key);

  final Uint8List image;
  final double cropAspectRatio;
  final ImageCompressionRatio compressionRatio;

  @override
  _CropImageState createState() => _CropImageState();
}


enum _CropState {
  /// 首次加载
  loading,

  /// 可编辑 裁剪
  editor,

  /// 裁剪中
  cutting,

  /// 裁剪后的预览
  preview,

  /// 保存中
  saving,
}

class _CropImageState extends State<_CropImage> {
  GlobalKey editorKey = GlobalKey();
  GlobalKey repaintBoundaryKey = GlobalKey();

  late Uint8List image;
  late StateSetter buttonState;
  late double pixelRatio;
  bool isEdit = true;

  ValueNotifier<bool> hasLoading = ValueNotifier<bool>(true);
  _CropState editState = _CropState.loading;

  @override
  void initState() {
    super.initState();
    image = widget.image;
    pixelRatio = window.devicePixelRatio;
    switch (widget.compressionRatio) {
      case ImageCompressionRatio.high:
        break;
      case ImageCompressionRatio.medium:
        pixelRatio = pixelRatio / 2;
        break;
      case ImageCompressionRatio.low:
        pixelRatio = 1;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
        appBarTitle: '图片裁剪',
        isStack: true,
        appBarRightWidget: button(),
        children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              child: RepaintBoundary(
                  key: repaintBoundaryKey,
                  child: ExtendedImage.memory(image,
                      fit: BoxFit.contain,
                      enableLoadState: true,
                      loadStateChanged: (ExtendedImageState state) {
                        switch (state.extendedImageLoadState) {
                          case LoadState.loading:
                            return const Align(
                                child: BaseLoading(),
                                alignment: Alignment.center);
                          case LoadState.completed:
                            if (editState == _CropState.loading) {
                              editState = _CropState.editor;
                              // log('首次加载完成刷新按钮');
                              200.milliseconds.delayed(() {
                                refreshLoadingAndButton(_CropState.editor);
                              });
                            } else if (editState == _CropState.editor) {
                            } else if (editState == _CropState.cutting) {
                              /// 剪切完成
                              200.milliseconds.delayed(() {
                                // log('裁剪后加载完成并刷新loading和按钮');
                                refreshLoadingAndButton(_CropState.preview);
                              });
                            }
                            return null;
                          case LoadState.failed:
                            return Align(
                                child: TextDefault('加载失败'),
                                alignment: Alignment.center);
                        }
                      },
                      mode: isEdit
                          ? ExtendedImageMode.editor
                          : ExtendedImageMode.none,
                      extendedImageEditorKey: editorKey,
                      clearMemoryCacheWhenDispose: true,
                      initEditorConfigHandler: (state) => EditorConfig(
                          maxScale: 8.0,
                          cornerSize: const Size(20, 3),
                          cornerColor: GlobalConfig().currentColor,
                          cropRectPadding: const EdgeInsets.all(20.0),
                          cropAspectRatio: widget.cropAspectRatio,
                          hitTestSize: 20.0)))),
          ValueListenableBuilder<bool>(
              valueListenable: hasLoading,
              builder: (_, bool value, __) {
                return value
                    ? Universal(
                        onTap: () {},
                        alignment: Alignment.center,
                        color: CCS.background.withOpacity(0.2),
                        child: const BaseLoading())
                    : const SizedBox();
              })
        ]);
  }

  Widget button() {
    return StatefulBuilder(builder: (_, state) {
      buttonState = state;
      return SimpleButton(
          text: buttonText,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(left: 12, right: 6),
          textStyle: TStyle(height: 1),
          onTap: () {
            switch (editState) {
              case _CropState.loading:
                break;
              case _CropState.editor:
                cropImage();
                break;
              case _CropState.cutting:
                break;
              case _CropState.preview:
                saveImage();
                break;
              case _CropState.saving:
                break;
            }
          });
    });
  }

  String get buttonText {
    switch (editState) {
      case _CropState.loading:
        return '加载中';
      case _CropState.editor:
        return '裁剪';
      case _CropState.cutting:
        return '裁剪中';
      case _CropState.preview:
        return '保存';
      case _CropState.saving:
        return '保存中';
    }
  }

  /// 剪切后保存
  Future<void> saveImage() async {
    refreshLoadingAndButton(_CropState.saving);
    final ByteData? byteData = await repaintBoundaryKey.screenshots(
        format: ImageByteFormat.png, pixelRatio: pixelRatio);
    if (GlobalConfig().currentCacheDir == null ||
        byteData == null ||
        GlobalConfig().currentCacheDir!.length < 2) {
      showToast('图片保存失败');
      refreshLoadingAndButton(_CropState.preview);
      return;
    }
    final String path = '${GlobalConfig().currentCacheDir}image/';
    final String name =
        DateTime.now().millisecondsSinceEpoch.toString() + '.png';
    final savePath =
        await saveFileToPath(path, name, byteData.buffer.asUint8List());
    if (savePath == null) {
      showToast('图片保存失败');
      refreshLoadingAndButton(_CropState.preview);
      return;
    }
    300.milliseconds.delayed(() => pop(savePath));
  }

  ///剪切图片
  Future<void> cropImage() async {
    // log('开始剪切加载loading');
    refreshLoadingAndButton(_CropState.cutting);

    final ExtendedImageEditorState? state =
        editorKey.currentState as ExtendedImageEditorState?;

    final cropRect = state?.getCropRect();
    final img = state?.rawImageData;
    if (state == null || img == null || cropRect == null) {
      showToast('图片获取失败');
      refreshLoadingAndButton(_CropState.editor);
      return;
    }
    final decodeImg = await compute(decodeImage, img);
    if (decodeImg == null) {
      showToast('图片转换失败');
      refreshLoadingAndButton(_CropState.editor);
      return;
    }
    final needEncodeImg = copyCrop(decodeImg, cropRect.left.toInt(),
        cropRect.top.toInt(), cropRect.width.toInt(), cropRect.height.toInt());
    final data = await compute(encodeJpg, needEncodeImg);
    image = Uint8List.fromList(data);
    isEdit = false;
    setState(() {});
  }

  void refreshLoadingAndButton(_CropState state) {
    final bool loading = state == _CropState.loading ||
        state == _CropState.cutting ||
        state == _CropState.saving;
    hasLoading.value = loading;
    editState = state;
    buttonState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    hasLoading.dispose();
  }
}
