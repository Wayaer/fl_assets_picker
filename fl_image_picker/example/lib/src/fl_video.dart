import 'dart:io';

import 'package:fl_video/fl_video.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FlVideoPlayerWithImagePicker extends StatefulWidget {
  const FlVideoPlayerWithImagePicker({
    super.key,
    required this.controller,
    this.autoPlay = true,
    this.looping = true,
    this.cover = const SizedBox(),
    this.loading = const CircularProgressIndicator(),
    this.error = const Icon(Icons.info_outline),
    this.controls,
  });

  /// 预览
  final VideoPlayerController controller;

  /// 是否自动播放
  final bool autoPlay;

  /// 始终循环播放
  final bool looping;

  /// 封面
  final Widget cover;

  /// loading
  final Widget loading;

  /// 错误 UI
  final Widget error;

  /// [CupertinoControls]、[MaterialControls]
  final Widget? controls;

  @override
  State<FlVideoPlayerWithImagePicker> createState() =>
      _FlVideoPlayerWithImagePickerState();

  /// 根据 [value] 不同的值 转换不同的 [VideoPlayerController]
  static VideoPlayerController? buildVideoPlayerController(dynamic value) {
    if (value != null) {
      if (value is String && value.startsWith('http')) {
        return VideoPlayerController.networkUrl(Uri.parse(value));
      } else if (value is File) {
        return VideoPlayerController.file(value);
      } else if (value is String) {
        return VideoPlayerController.asset(value);
      }
    }
    return null;
  }
}

class _FlVideoPlayerWithImagePickerState
    extends State<FlVideoPlayerWithImagePicker> with WidgetsBindingObserver {
  FlVideoPlayerController? flController;

  late VideoPlayerController controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initController();
    });
  }

  void initController() async {
    controller = widget.controller;
    flController?.pause();
    flController?.dispose();
    flController = FlVideoPlayerController(
        placeholder: widget.cover,
        deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
        controls: widget.controls ??
            CupertinoControls(
                loading: widget.loading,
                enableFullscreen: false,
                enableSubtitle: false,
                enableVolume: false),
        showControlsOnInitialize: true,
        allowedScreenSleep: false,
        autoInitialize: true,
        isLive: false,
        videoPlayerController: controller,
        autoPlay: widget.autoPlay,
        looping: widget.looping);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return flController == null
        ? widget.cover
        : Padding(
            padding: EdgeInsets.only(bottom: bottom == 0 ? 10 : bottom),
            child: FlVideoPlayer(controller: flController!));
  }

  @override
  void didUpdateWidget(covariant FlVideoPlayerWithImagePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != controller) initController();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive) {
      flController?.pause();
    }
  }

  @override
  void dispose() {
    super.dispose();
    flController?.pause();
    flController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }
}
