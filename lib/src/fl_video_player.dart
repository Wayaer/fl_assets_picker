import 'dart:io';

import 'package:assets_picker/assets_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PickerFlVideoPlayer extends StatefulWidget {
  const PickerFlVideoPlayer({
    Key? key,
    this.file,
    this.url,
    this.path,
    this.autoPlay = true,
    this.looping = true,
    this.cover,
    this.loading = const CircularProgressIndicator(),
    this.error = const Icon(Icons.info_outline),
    this.controls,
  })  : assert(file != null || url != null || path != null),
        super(key: key);
  final File? file;
  final String? url;
  final String? path;

  /// 是否自动播放
  final bool autoPlay;

  /// 始终循环播放
  final bool looping;

  /// 封面
  final Widget? cover;

  /// loading
  final Widget loading;

  /// 错误 UI
  final Widget error;

  /// [CupertinoControls]、[MaterialControls]
  final Widget? controls;

  @override
  State<PickerFlVideoPlayer> createState() => _PickerFlVideoPlayerState();
}

class _PickerFlVideoPlayerState extends State<PickerFlVideoPlayer>
    with WidgetsBindingObserver {
  FlVideoPlayerController? flController;

  File? file;
  String? url;
  String? path;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      initController();
    });
  }

  void initController() async {
    file = widget.file;
    path = widget.path;
    url = widget.url;
    flController?.pause();
    flController?.dispose();
    VideoPlayerController? videoPlayerController;
    if (path != null) {
      videoPlayerController = VideoPlayerController.asset(path!);
    } else if (file != null) {
      videoPlayerController = VideoPlayerController.file(file!);
    } else if (url != null) {
      videoPlayerController = VideoPlayerController.network(url!);
    }
    if (videoPlayerController == null) return;
    flController = FlVideoPlayerController(
        placeholder: widget.cover,
        deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
        controls: widget.controls ?? CupertinoControls(loading: widget.loading),
        showControlsOnInitialize: true,
        allowedScreenSleep: false,
        autoInitialize: true,
        isLive: false,
        videoPlayerController: videoPlayerController,
        autoPlay: widget.autoPlay,
        looping: widget.looping);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return flController == null
        ? widget.cover ?? const SizedBox()
        : Padding(
            padding: EdgeInsets.only(bottom: bottom == 0 ? 10 : bottom),
            child: FlVideoPlayer(controller: flController!));
  }

  @override
  void didUpdateWidget(covariant PickerFlVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.file != null && widget.file != file) ||
        (widget.path != null && widget.path != path) ||
        (widget.url != null && widget.url != url)) {
      initController();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.inactive:
        flController?.pause();
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.resumed:
        flController?.pause();
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    super.dispose();
    flController?.pause();
    flController?.dispose();
    WidgetsBinding.instance?.removeObserver(this);
  }
}
