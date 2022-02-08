 

import 'package:assets_picker/src/assets.dart';
import 'package:assets_picker/src/controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_waya/extension/src/object_extension.dart';
import 'package:universally/universally.dart';

/// 图片和视频
class AssetSelect extends StatefulWidget {
  const AssetSelect({
    Key? key,
    this.onSelectChange,
    this.imagesUrl,
    this.imagesList,
    this.isShow = false,
    this.showLocalFile = false,
    this.canDelete = false,
    double? cropAspectRatio,
    int? maxAssets,
    int? maxSelectAssets,
    int? maxVideoCount,
    AssetsType? selectType,
    ImageCompressionRatio? compressionRatio,
    this.initialImages,
  })  : cropAspectRatio = cropAspectRatio ?? 1,
        selectType = selectType ?? AssetsType.image,
        compressionRatio = compressionRatio ?? ImageCompressionRatio.medium,
        maxVideoCount = maxVideoCount ?? 1,
        maxAssets = maxAssets ?? 9,
        maxSelectAssets = maxSelectAssets ?? 3,
        super(key: key);

  final ValueChanged<List<String>>? onSelectChange;

  ///图片剪切宽高比
  final double cropAspectRatio;

  ///选择的类型
  final AssetsType selectType;

  /// [isShow] = true 只显示图片 通过 [imagesUrl]、[imagesList]
  /// [isShow] = false 选择图片，默认为false
  final bool isShow;

  /// [isShow] == true 时有效，默认为 [false]
  /// [showLocalFile] == true [imagesUrl]和[imagesList] 为本地文件path ，使用本地图片组件显示
  final bool showLocalFile;

  /// [isShow] == true 时有效，默认为 [false]
  /// 仅显示的时候 是否可以删除 删除后无法恢复
  final bool canDelete;

  /// 图片url 不可添加 视频url
  final String? imagesUrl;

  /// 图片路径 不可添加视频
  final List<String>? imagesList;

  /// 初始本地图片路径
  final List<String>? initialImages;

  ///最大选择视频数量
  final int maxVideoCount;

  ///最多选择几个资源
  final int maxAssets;

  ///单次最多选择几个资源
  final int maxSelectAssets;

  ///图片剪切压缩比
  final ImageCompressionRatio compressionRatio;

  @override
  _AssetSelectState createState() => _AssetSelectState();
}

class _AssetSelectState extends State<AssetSelect> {
  List<AssetsModel> assets = [];
  final String _addAsset = 'add';
  bool isContainVideo = false;

  @override
  void initState() {
    super.initState();
    final imagesUrl = widget.imagesUrl;
    final imagesList = widget.imagesList;
    if (widget.isShow && imagesUrl != null) {
      if (imagesUrl.contains(',')) {
        assets = imagesUrl.split(',').builder(
            (item) => AssetsModel(path: item, assetsType: AssetsType.image));
      } else {
        if (imagesUrl.isNotEmpty) {
          assets
              .add(AssetsModel(path: imagesUrl, assetsType: AssetsType.image));
        }
      }
    } else if (widget.isShow && imagesList != null && imagesList.isNotEmpty) {
      assets = imagesList.builder(
          (item) => AssetsModel(path: item, assetsType: AssetsType.image));
    } else {
      if (widget.initialImages != null && widget.initialImages!.isNotEmpty) {
        assets = widget.initialImages!.builder(
            (item) => AssetsModel(path: item, assetsType: AssetsType.image));
      }
      assets.add(AssetsModel(path: _addAsset, assetsType: AssetsType.all));
    }
  }

  @override
  Widget build(BuildContext context) => Universal(
      isWrap: true,
      direction: Axis.horizontal,
      margin: const EdgeInsets.all(10),
      width: double.infinity,
      wrapAlignment: WrapAlignment.start,
      wrapCrossAlignment: WrapCrossAlignment.start,
      runSpacing: 15,
      // wrapSpacing: 15,
      children: assets.builder((path) => item(path)));

  Widget item(AssetsModel asset) {
    Widget current = assetWidget(asset);
    if (widget.isShow) {
      if (widget.canDelete) {
        current = addBadge(
            child: current,
            onTap: () {
              showAlertSureCancel(
                  text: '确定要删除这张图片或视频么？删除后无法恢复',
                  sureTap: () {
                    assets.remove(asset);
                    refreshImage;
                  });
            });
      }
      return asset.path != _addAsset ? current : const SizedBox();
    } else {
      return asset.path == _addAsset
          ? addAsset
          : addBadge(
              onTap: () {
                assets.remove(asset);
                refreshImage;
              },
              child: current);
    }
  }

  Widget assetWidget(AssetsModel asset) {
    if (asset.assetsType == AssetsType.image) {
      return image(asset, onTap: () {
        if (asset.path.isNotEmpty && asset.path != 'null') {
          showBottomPopup<dynamic>(
              options:
                  const BottomSheetOptions(backgroundColor: CCS.transparent),
              widget: fullImage(asset));
        } else {
          showToast('无法查看');
        }
      });
    } else if (asset.assetsType == AssetsType.video) {
      return video(asset);
    }
    return const SizedBox();
  }

  Widget addBadge({required Widget child, GestureTapCallback? onTap}) => Badge(
      right: 2,
      top: 2,
      onTap: onTap,
      pointColor: GlobalConfig().currentColor,
      pointChild: const Icon(CIS.clear, size: 14, color: CCS.white),
      child: child);

  /// 小视频预览图片
  Widget video(AssetsModel asset) => IconBox(
      icon: CIS.playCircleFill,
      width: 65,
      height: 65,
      size: 30,
      color: CCS.white,
      margin: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
          image: asset.firstFramePath == null
              ? null
              : DecorationImage(
                  fit: BoxFit.cover,
                  image: FileImage(File(asset.firstFramePath!))),
          color: CCS.background,
          borderRadius: BorderRadius.circular(4)),
      onTap: !(asset.path.isNotEmpty && asset.path != 'null')
          ? null
          : () => showBottomPopup<dynamic>(
              options:
                  const BottomSheetOptions(backgroundColor: CCS.transparent),
              widget: fullVideo(asset)));

  /// 全屏显示视频
  Widget fullVideo(AssetsModel asset) {
    final child = SizedBox.fromSize(
        size: asset.size,
        child: BaseVideo.file(asset.path,
            coverFile: asset.firstFramePath == null
                ? null
                : File(asset.firstFramePath!),
            autoPlay: true));
    return PopupModalWindows(
        options: const ModalWindowsOptions(onTap: pop, color: CCS.black),
        child: Badge(
            right: 20,
            top: getStatusBarHeight + 20,
            pointColor: CCS.mainGray,
            pointChild: const IconBox(
                icon: CIS.clear, color: CCS.white, size: 20, onTap: pop),
            child: Center(child: child)));
  }

  /// 显示图片组件
  Widget image(AssetsModel asset,
      {bool isFull = false, GestureTapCallback? onTap}) {
    double? width = 65;
    double? height = 65;
    BoxFit fit = BoxFit.cover;
    if (isFull) {
      width = double.infinity;
      height = null;
      fit = BoxFit.contain;
    }
    ImageProvider? image;
    if (!widget.isShow || widget.showLocalFile) {
      image = FileImage(File(asset.path));
    } else {
      if (asset.path.isNotEmpty && asset.path != 'null') {
        image =
            ExtendedNetworkImageProvider(asset.path, cache: true, retries: 1);
      }
    }
    if (image == null) return const SizedBox();
    return Universal(
        heroTag: asset.path,
        onTap: onTap,
        margin: const EdgeInsets.symmetric(horizontal: 7),
        child: BaseImage(image,
            hasGesture: isFull,
            fit: fit,
            width: width,
            height: height,
            radius: isFull ? null : 4));
  }

  /// 全屏显示图片
  Widget fullImage(AssetsModel asset) {
    int i = 0;
    assets.builderEntry((entry) {
      if (entry.value.path == asset.path) {
        i = entry.key;
      }
    });
    final List<AssetsModel> images = [];
    assets.builder((item) {
      if (item.assetsType == AssetsType.image && item.path != _addAsset) {
        images.add(item);
      }
    });
    return PreviewImage(
        initialPage: i,
        itemCount: images.length,
        itemBuilder: (_, int index) => image(images[index], isFull: true));
  }

  void get refreshImage {
    setState(() {});
    if (widget.onSelectChange != null) {
      widget.onSelectChange!(assets
          .sublist(
              0,
              widget.isShow && widget.canDelete
                  ? assets.length
                  : assets.length - 1)
          .builder((item) => item.path));
    }
  }

  /// 添加资源按钮
  Widget get addAsset => IconBox(
        onTap: () async {
          context.focusNode();
          if (assets.length >= widget.maxAssets + 1) {
            showToast('最多选择${widget.maxAssets}个');
            return;
          }
          if (assets.length == widget.maxAssets + 1) {
            showToast(
                '最多添加${widget.maxAssets - widget.maxVideoCount}张图片或${widget.maxVideoCount}个视频');
            return;
          }
          var selectType = widget.selectType;
          if (selectType != AssetsType.image) {
            int hasVideo = 0;
            assets.builder((item) {
              if (item.assetsType == AssetsType.video) hasVideo += 1;
            });
            if (hasVideo >= widget.maxVideoCount) {
              showToast('最多添加${widget.maxVideoCount}个视频');
              selectType = AssetsType.image;
            }
          }

          final assetsModel = await AssetsUtils.selectAssets(context,
              cropAspectRatio: widget.cropAspectRatio,
              assetsType: selectType,
              maxAssets: widget.maxSelectAssets,
              compressionRatio: widget.compressionRatio);
          if (assetsModel == null) return;
          assets.insert(assets.length - 1, assetsModel);
          refreshImage;
        },
        width: 65,
        height: 65,
        decoration: BoxDecoration(
            border: Border.all(color: CCS.smallTextColor),
            color: CCS.white,
            borderRadius: BorderRadius.circular(4)),
        size: 30,
        icon: CIS.add,
        color: CCS.smallTextColor,
      );
}

/// 资源文件上传
Future<List<FileModel?>?> assetUpload(List<String> paths,
        {bool compress = true}) =>
    showBottomPopup(
        options: const BottomSheetOptions(backgroundColor: CCS.transparent),
        widget: _AssetUpload(paths: paths, compress: compress));

/// 资源文件上传 UI
class _AssetUpload extends StatefulWidget {
  const _AssetUpload({Key? key, required this.paths, this.compress = true})
      : super(key: key);

  final List<String> paths;

  /// 上传文件是否压缩
  final bool compress;

  @override
  _AssetUploadState createState() => _AssetUploadState();
}

class _FileUploadModel {
  _FileUploadModel({this.path, this.percent, this.fileModel, this.setState});

  String? path;
  double? percent;
  FileModel? fileModel;
  StateSetter? setState;
}

class _AssetUploadState extends State<_AssetUpload> {
  List<_FileUploadModel> list = <_FileUploadModel>[];
  CancelToken cancelToken = CancelToken();
  int downloadNum = 0;

  @override
  void initState() {
    super.initState();
    if (widget.paths.isNotEmpty) {
      for (int i = 0; i < widget.paths.length; i++) {
        final _FileUploadModel file = _FileUploadModel();
        file.path = widget.paths[i];
        list.add(file);
        initUpload(i);
      }
    } else {
      addPostFrameCallback((_) {
        pop(<FileModel?>[]);
      });
    }
  }

  Future<void> initUpload(int i) async {
    final _FileUploadModel file = list[i];
    final BaseModel data =
        await upload(file.path!, onSendProgress: (int count, int total) {
      list[i].percent = count / total;
      if (list[i].setState != null && list[i].percent! <= 1) {
        list[i].setState!(() {});
      }
    });
    if (resultSuccessFail(data)) {
      downloadNum += 1;
      list[i].fileModel = getFileModelList(data.data as List<dynamic>)[0];
      if (downloadNum == list.length) {
        pop(list.builder((_FileUploadModel item) => item.fileModel));
      }
    } else {
      pop(<FileModel?>[]);
    }
  }

  Future<BaseModel> upload(String path,
      {required ProgressCallback onSendProgress}) async {
    final formData = getFileFormData(
        path: path, fromMap: <String, dynamic>{'compress': widget.compress});
    return await BaseDio().upload(GlobalConfig().currentUploadUrl, formData,
        loading: false,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken);
  }

  @override
  Widget build(BuildContext context) => PopupModalWindows(
      options: ModalWindowsOptions(
          left: 40, right: 40, onTap: () {}, gaussian: true),
      child: Universal(
          mainAxisSize: MainAxisSize.min,
          decoration: BoxDecoration(
              color: CCS.white, borderRadius: BorderRadius.circular(10)),
          children: <Widget>[
            SimpleButton(
                text: '资源上传中...',
                textStyle: TStyle(),
                alignment: Alignment.center,
                height: 45,
                decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: CCS.lineColor, width: 0.5)))),
            Universal(
                width: 300,
                mainAxisSize: MainAxisSize.min,
                children: list.map((_FileUploadModel e) => item(e)).toList()),
            SimpleButton(
                margin: const EdgeInsets.only(top: 6),
                text: '取消',
                textStyle: TStyle(),
                height: 45,
                alignment: Alignment.center,
                onTap: () {
                  pop();
                  cancelToken.cancel();
                },
                decoration: const BoxDecoration(
                    border: Border(
                        top: BorderSide(color: CCS.lineColor, width: 0.5)))),
          ]));

  Widget item(_FileUploadModel file) {
    final int index = list.indexOf(file);
    return Universal(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
              margin: const EdgeInsets.only(left: 10, bottom: 4, top: 4),
              child: Text('资源 ' + (index + 1).toString())),
          StatefulBuilder(builder: (_, StateSetter setState) {
            list[index].setState = setState;
            return Progress.linear(
                width: 280,
                lineHeight: 4,
                percent: file.percent ?? 0,
                backgroundColor: CCS.lineColor,
                progressColor: CCS.mainRed);
          })
        ]);
  }
}
