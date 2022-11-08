import 'package:fl_assets_picker/fl_assets_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

extension ExtensionExtendedAssetEntity on ExtendedAssetEntity {
  AssetEntity toAssetEntity() => AssetEntity(
      id: id,
      typeInt: typeInt,
      width: width,
      height: height,
      duration: duration,
      orientation: orientation,
      isFavorite: isFavorite,
      title: title,
      createDateSecond: createDateSecond,
      modifiedDateSecond: modifiedDateSecond,
      relativePath: relativePath,
      latitude: latitude,
      longitude: longitude,
      mimeType: mimeType,
      subtype: subtype);
}

extension ExtensionAssetEntity on AssetEntity {
  ///  to [ExtendedAssetEntity] and renovate [AssetEntity];
  Future<ExtendedAssetEntity> toExtensionAssetEntity<T>(
      {FlAssetFileRenovate<T>? renovate}) async {
    T? renovated;
    if (renovate != null) renovated = await renovate.call(this);
    final fileAsync = await file;
    final thumbnailData = await this.thumbnailData;
    return ExtendedAssetEntity<T>(
        thumbnailDataAsync: thumbnailData,
        fileAsync: fileAsync,
        renovated: renovated,
        id: id,
        typeInt: typeInt,
        width: width,
        height: height,
        duration: duration,
        orientation: orientation,
        isFavorite: isFavorite,
        title: title,
        createDateSecond: createDateSecond,
        modifiedDateSecond: modifiedDateSecond,
        relativePath: relativePath,
        latitude: latitude,
        longitude: longitude,
        mimeType: mimeType,
        subtype: subtype);
  }
}

extension ExtensionAssetPickerConfig on AssetPickerConfig {
  AssetPickerConfig copyWith({
    /// Selected assets.
    /// 已选中的资源
    List<AssetEntity>? selectedAssets,

    /// Maximum count for asset selection.
    /// 资源选择的最大数量
    int? maxAssets,

    /// Assets should be loaded per page.
    /// 资源选择的最大数量
    ///
    /// Use `null` to display all assets into a single grid.
    int? pageSize,

    /// Thumbnail size in the grid.
    /// 预览时网络的缩略图大小
    ///
    /// This only works on images and videos since other types does not have to
    /// request for the thumbnail data. The preview can speed up by reducing it.
    /// 该参数仅生效于图片和视频类型的资源，因为其他资源不需要请求缩略图数据。
    /// 预览图片的速度可以通过适当降低它的数值来提升。
    ///
    /// This cannot be `null` or a large value since you shouldn't use the
    /// original data for the grid.
    /// 该值不能为空或者非常大，因为在网格中使用原数据不是一个好的决定。
    ThumbnailSize? gridThumbnailSize,

    /// Thumbnail size for path selector.
    /// 路径选择器中缩略图的大小
    ThumbnailSize? pathThumbnailSize,

    /// Preview thumbnail size in the viewer.
    /// 预览时图片的缩略图大小
    ///
    /// This only works on images and videos since other types does not have to
    /// request for the thumbnail data. The preview can speed up by reducing it.
    /// 该参数仅生效于图片和视频类型的资源，因为其他资源不需要请求缩略图数据。
    /// 预览图片的速度可以通过适当降低它的数值来提升。
    ///
    /// Default is `null`, which will request the origin data.
    /// 默认为空，即读取原图。
    ThumbnailSize? previewThumbnailSize,

    /// Request assets type.
    /// 请求的资源类型
    RequestType? requestType,

    /// The current special picker type for the picker.
    /// 当前特殊选择类型
    ///
    /// Several types which are special:
    /// * [SpecialPickerType.wechatMoment] When user selected video,
    ///   no more images can be selected.
    /// * [SpecialPickerType.noPreview] Disable preview of asset,
    ///   Clicking on an asset selects it.
    ///
    /// 这里包含一些特殊选择类型：
    /// * [SpecialPickerType.wechatMoment] 微信朋友圈模式。
    ///   当用户选择了视频，将不能选择图片。
    /// * [SpecialPickerType.noPreview] 禁用资源预览。
    ///   多选时单击资产将直接选中，单选时选中并返回。
    SpecialPickerType? specialPickerType,

    /// Whether the picker should save the scroll offset between pushes and pops.
    /// 选择器是否可以从同样的位置开始选择
    bool? keepScrollOffset,

    /// @{macro wechat_assets_picker.delegates.SortPathDelegate}
    SortPathDelegate<AssetPathEntity>? sortPathDelegate,

    /// {@template wechat_assets_picker.constants.AssetPickerConfig.sortPathsByModifiedDate}
    /// Whether to allow sort delegates to sort paths with
    /// [FilterOptionGroup.containsPathModified].
    /// 是否结合 [FilterOptionGroup.containsPathModified] 进行路径排序
    /// {@endtemplate}
    bool? sortPathsByModifiedDate,

    /// Filter options for the picker.
    /// 选择器的筛选条件
    ///
    /// Will be merged into the base selectedAssets??thisuration.
    /// 将会与基础条件进行合并。
    FilterOptionGroup? filterOptions,

    /// Assets count for the picker.
    /// 资源网格数
    int? gridCount,

    /// Main color for the picker.
    /// 选择器的主题色
    Color? themeColor,

    /// Theme for the picker.
    /// 选择器的主题
    ///
    /// Usually the WeChat uses the dark version (dark background color)
    /// for the picker. However, some others want a light or a custom version.
    /// 通常情况下微信选择器使用的是暗色（暗色背景）的主题，
    /// 但某些情况下开发者需要亮色或自定义主题。
    ThemeData? pickerTheme,
    AssetPickerTextDelegate? textDelegate,

    /// Allow users set a special item in the picker with several positions.
    /// 允许用户在选择器中添加一个自定义item，并指定位置
    SpecialItemPosition? specialItemPosition,

    /// The widget builder for the the special item.
    /// 自定义item的构造方法
    SpecialItemBuilder<AssetPathEntity>? specialItemBuilder,

    /// Indicates the loading status for the builder.
    /// 指示目前加载的状态
    LoadingIndicatorBuilder? loadingIndicatorBuilder,

    /// {@macro wechat_assets_picker.AssetSelectPredicate}
    AssetSelectPredicate<AssetEntity>? selectPredicate,

    /// Whether the assets grid should revert.
    /// 判断资源网格是否需要倒序排列
    ///
    /// [Null] means judging by Apple OS.
    /// 使用 [Null] 即使用是否为 Apple 系统进行判断。
    bool? shouldRevertGrid,

    /// {@macro wechat_assets_picker.LimitedPermissionOverlayPredicate}
    LimitedPermissionOverlayPredicate? limitedPermissionOverlayPredicate,

    /// {@macro wechat_assets_picker.PathNameBuilder}
    PathNameBuilder<AssetPathEntity>? pathNameBuilder,
  }) =>
      AssetPickerConfig(
          selectedAssets: selectedAssets ?? this.selectedAssets,
          maxAssets: maxAssets ?? this.maxAssets,
          pageSize: pageSize ?? this.pageSize,
          gridThumbnailSize: gridThumbnailSize ?? this.gridThumbnailSize,
          pathThumbnailSize: pathThumbnailSize ?? this.pathThumbnailSize,
          previewThumbnailSize:
              previewThumbnailSize ?? this.previewThumbnailSize,
          requestType: requestType ?? this.requestType,
          specialPickerType: specialPickerType ?? this.specialPickerType,
          keepScrollOffset: keepScrollOffset ?? this.keepScrollOffset,
          sortPathDelegate: sortPathDelegate ?? this.sortPathDelegate,
          sortPathsByModifiedDate:
              sortPathsByModifiedDate ?? this.sortPathsByModifiedDate,
          filterOptions: filterOptions ?? this.filterOptions,
          gridCount: gridCount ?? this.gridCount,
          themeColor: themeColor ?? this.themeColor,
          pickerTheme: pickerTheme ?? this.pickerTheme,
          textDelegate: textDelegate ?? this.textDelegate,
          specialItemPosition: specialItemPosition ?? this.specialItemPosition,
          specialItemBuilder: specialItemBuilder ?? this.specialItemBuilder,
          loadingIndicatorBuilder:
              loadingIndicatorBuilder ?? this.loadingIndicatorBuilder,
          selectPredicate: selectPredicate ?? this.selectPredicate,
          shouldRevertGrid: shouldRevertGrid ?? this.shouldRevertGrid,
          limitedPermissionOverlayPredicate:
              limitedPermissionOverlayPredicate ??
                  this.limitedPermissionOverlayPredicate,
          pathNameBuilder: pathNameBuilder ?? this.pathNameBuilder);

  AssetPickerConfig merge([AssetPickerConfig? config]) => AssetPickerConfig(
      selectedAssets: config?.selectedAssets ?? selectedAssets,
      maxAssets: config?.maxAssets ?? maxAssets,
      pageSize: config?.pageSize ?? pageSize,
      gridThumbnailSize: config?.gridThumbnailSize ?? gridThumbnailSize,
      pathThumbnailSize: config?.pathThumbnailSize ?? pathThumbnailSize,
      previewThumbnailSize:
          config?.previewThumbnailSize ?? previewThumbnailSize,
      requestType: config?.requestType ?? requestType,
      specialPickerType: config?.specialPickerType ?? specialPickerType,
      keepScrollOffset: config?.keepScrollOffset ?? keepScrollOffset,
      sortPathDelegate: config?.sortPathDelegate ?? sortPathDelegate,
      sortPathsByModifiedDate:
          config?.sortPathsByModifiedDate ?? sortPathsByModifiedDate,
      filterOptions: config?.filterOptions ?? filterOptions,
      gridCount: config?.gridCount ?? gridCount,
      themeColor: config?.themeColor ?? themeColor,
      pickerTheme: config?.pickerTheme ?? pickerTheme,
      textDelegate: config?.textDelegate ?? textDelegate,
      specialItemPosition: config?.specialItemPosition ?? specialItemPosition,
      specialItemBuilder: config?.specialItemBuilder ?? specialItemBuilder,
      loadingIndicatorBuilder:
          loadingIndicatorBuilder ?? loadingIndicatorBuilder,
      selectPredicate: config?.selectPredicate ?? selectPredicate,
      shouldRevertGrid: config?.shouldRevertGrid ?? shouldRevertGrid,
      limitedPermissionOverlayPredicate:
          config?.limitedPermissionOverlayPredicate ??
              limitedPermissionOverlayPredicate,
      pathNameBuilder: config?.pathNameBuilder ?? pathNameBuilder);
}

extension ExtensionCameraPickerConfig on CameraPickerConfig {
  CameraPickerConfig copyWith({
    /// Whether the picker can record video.
    /// 选择器是否可以录像
    bool? enableRecording,

    /// Whether the picker can record video.
    /// 选择器是否可以录像
    bool? onlyEnableRecording,

    /// Whether allow the record can start with single tap.
    /// 选择器是否可以单击录像
    ///
    /// It only works when [onlyEnableRecording] is true.
    /// 仅在 [onlyEnableRecording] 为 true 时生效。
    bool? enableTapRecording,

    /// Whether the picker should record audio.
    /// 选择器录像时是否需要录制声音
    bool? enableAudio,

    /// Whether users can set the exposure point by tapping.
    /// 用户是否可以在界面上通过点击设定曝光点
    bool? enableSetExposure,

    /// Whether users can adjust exposure according to the set point.
    /// 用户是否可以根据已经设置的曝光点调节曝光度
    bool? enableExposureControlOnPoint,

    /// Whether users can zoom the camera by pinch.
    /// 用户是否可以在界面上双指缩放相机对焦
    bool? enablePinchToZoom,

    /// Whether users can zoom by pulling up when recording video.
    /// 用户是否可以在录制视频时上拉缩放
    bool? enablePullToZoomInRecord,

    /// Whether the camera preview should be scaled during captures.
    /// 拍摄过程中相机预览是否需要缩放
    bool? enableScaledPreview,

    /// {@template wechat_camera_picker.shouldDeletePreviewFile}
    /// Whether the preview file will be delete when pop.
    /// 返回页面时是否删除预览文件
    /// {@endtemplate}
    bool? shouldDeletePreviewFile,

    /// {@template wechat_camera_picker.shouldAutoPreviewVideo}
    /// Whether the video should be played instantly in the preview.
    /// 在预览时是否直接播放视频
    /// {@endtemplate}
    bool? shouldAutoPreviewVideo,

    /// The maximum duration of the video recording process.
    /// 录制视频最长时长
    ///
    /// Defaults to 15 seconds, allow `null` for unrestricted video recording.
    /// 默认为 15 秒，可以使用 `null` 来设置无限制的视频录制
    Duration? maximumRecordingDuration,

    /// Theme data for the picker.
    /// 选择器的主题
    ThemeData? theme,

    /// The number of clockwise quarter turns the camera view should be rotated.
    /// 摄像机视图顺时针旋转次数，每次90度
    int? cameraQuarterTurns,

    /// Text delegate that controls text in widgets.
    /// 控制部件中的文字实现
    CameraPickerTextDelegate? textDelegate,

    /// Present resolution for the camera.
    /// 相机的分辨率预设
    ResolutionPreset? resolutionPreset,

    /// The [ImageFormatGroup] describes the output of the raw image format.
    /// 输出图像的格式描述
    ImageFormatGroup? imageFormatGroup,

    /// Which lens direction is preferred when first using the camera,
    /// typically with the front or the back direction.
    /// 首次使用相机时首选的镜头方向，通常是前置或后置。
    CameraLensDirection? preferredLensDirection,

    /// {@macro wechat_camera_picker.ForegroundBuilder}
    ForegroundBuilder? foregroundBuilder,

    /// {@macro wechat_camera_picker.PreviewTransformBuilder}
    PreviewTransformBuilder? previewTransformBuilder,

    /// Whether the camera should be locked to the specific orientation
    /// during captures.
    /// 摄像机在拍摄时锁定的旋转角度
    DeviceOrientation? lockCaptureOrientation,

    /// {@macro wechat_camera_picker.EntitySaveCallback}
    EntitySaveCallback? onEntitySaving,

    /// {@macro wechat_camera_picker.CameraErrorHandler}
    CameraErrorHandler? onError,

    /// {@macro wechat_camera_picker.XFileCapturedCallback}
    XFileCapturedCallback? onXFileCaptured,
  }) =>
      CameraPickerConfig(
          enableRecording: enableRecording ?? this.enableRecording,
          onlyEnableRecording: onlyEnableRecording ?? this.onlyEnableRecording,
          enableTapRecording: enableTapRecording ?? this.enableTapRecording,
          enableAudio: enableAudio ?? this.enableAudio,
          enableSetExposure: enableSetExposure ?? this.enableSetExposure,
          enableExposureControlOnPoint:
              enableExposureControlOnPoint ?? this.enableExposureControlOnPoint,
          enablePinchToZoom: enablePinchToZoom ?? this.enablePinchToZoom,
          enablePullToZoomInRecord:
              enablePullToZoomInRecord ?? this.enablePullToZoomInRecord,
          enableScaledPreview: enableScaledPreview ?? this.enableScaledPreview,
          shouldDeletePreviewFile:
              shouldDeletePreviewFile ?? this.shouldDeletePreviewFile,
          shouldAutoPreviewVideo:
              shouldAutoPreviewVideo ?? this.shouldAutoPreviewVideo,
          maximumRecordingDuration:
              maximumRecordingDuration ?? this.maximumRecordingDuration,
          theme: theme ?? this.theme,
          textDelegate: textDelegate ?? this.textDelegate,
          cameraQuarterTurns: cameraQuarterTurns ?? this.cameraQuarterTurns,
          resolutionPreset: resolutionPreset ?? this.resolutionPreset,
          imageFormatGroup: imageFormatGroup ?? this.imageFormatGroup,
          preferredLensDirection:
              preferredLensDirection ?? this.preferredLensDirection,
          lockCaptureOrientation:
              lockCaptureOrientation ?? this.lockCaptureOrientation,
          foregroundBuilder: foregroundBuilder ?? this.foregroundBuilder,
          previewTransformBuilder:
              previewTransformBuilder ?? this.previewTransformBuilder,
          onEntitySaving: onEntitySaving ?? this.onEntitySaving,
          onError: onError ?? this.onError,
          onXFileCaptured: onXFileCaptured ?? this.onXFileCaptured);

  CameraPickerConfig merge([CameraPickerConfig? config]) => CameraPickerConfig(
      enableRecording: config?.enableRecording ?? enableRecording,
      onlyEnableRecording: config?.onlyEnableRecording ?? onlyEnableRecording,
      enableTapRecording: config?.enableTapRecording ?? enableTapRecording,
      enableAudio: config?.enableAudio ?? enableAudio,
      enableSetExposure: config?.enableSetExposure ?? enableSetExposure,
      enableExposureControlOnPoint:
          config?.enableExposureControlOnPoint ?? enableExposureControlOnPoint,
      enablePinchToZoom: config?.enablePinchToZoom ?? enablePinchToZoom,
      enablePullToZoomInRecord:
          config?.enablePullToZoomInRecord ?? enablePullToZoomInRecord,
      enableScaledPreview: config?.enableScaledPreview ?? enableScaledPreview,
      shouldDeletePreviewFile:
          config?.shouldDeletePreviewFile ?? shouldDeletePreviewFile,
      shouldAutoPreviewVideo:
          config?.shouldAutoPreviewVideo ?? shouldAutoPreviewVideo,
      maximumRecordingDuration:
          config?.maximumRecordingDuration ?? maximumRecordingDuration,
      theme: config?.theme ?? theme,
      textDelegate: config?.textDelegate ?? textDelegate,
      cameraQuarterTurns: config?.cameraQuarterTurns ?? cameraQuarterTurns,
      resolutionPreset: config?.resolutionPreset ?? resolutionPreset,
      imageFormatGroup: config?.imageFormatGroup ?? imageFormatGroup,
      preferredLensDirection:
          config?.preferredLensDirection ?? preferredLensDirection,
      lockCaptureOrientation:
          config?.lockCaptureOrientation ?? lockCaptureOrientation,
      foregroundBuilder: config?.foregroundBuilder ?? foregroundBuilder,
      previewTransformBuilder:
          previewTransformBuilder ?? previewTransformBuilder,
      onEntitySaving: config?.onEntitySaving ?? onEntitySaving,
      onError: config?.onError ?? onError,
      onXFileCaptured: config?.onXFileCaptured ?? onXFileCaptured);
}
