import 'dart:io';

import 'package:assets_picker/assets_picker.dart';
import 'package:flutter/material.dart';

class PickerVideoPlayer extends StatefulWidget {
  const PickerVideoPlayer({
    Key? key,
    this.file,
    this.url,
    this.path,
    this.autoPlay = true,
    this.cover,
    this.loading = const CircularProgressIndicator(),
    this.error = const Icon(Icons.info_outline),
  })  : assert(file != null || url != null || path != null),
        super(key: key);
  final File? file;
  final String? url;
  final String? path;
  final bool autoPlay;
  final Widget? cover;
  final Widget loading;
  final Widget error;

  @override
  State<PickerVideoPlayer> createState() => _PickerVideoPlayerState();
}

enum _VideoPlayState {
  /// 加载中
  isBuffering,

  /// 播放中
  isPlaying,

  /// 暂停中
  isPause,

  /// 播放结束
  isFinished,

  /// 未初始化
  isInitialized,
}

class _PickerVideoPlayerState extends State<PickerVideoPlayer>
    with WidgetsBindingObserver {
  VideoPlayerController? controller;

  ValueNotifier<_VideoPlayState> playState =
      ValueNotifier(_VideoPlayState.isInitialized);
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
    controller?.pause();
    controller?.removeListener(listener);
    controller?.dispose();
    if (path != null) {
      controller = VideoPlayerController.asset(path!);
    } else if (file != null) {
      controller = VideoPlayerController.file(file!);
    } else if (url != null) {
      controller = VideoPlayerController.network(url!);
    }
    controller!.addListener(listener);
    await controller!.initialize();
    if (mounted) setState(() {});
    Future.delayed(const Duration(milliseconds: 200), () {
      controller?.play();
    });
  }

  void listener() {
    if (controller == null) return;
    if (controller!.value.isBuffering) {
      if (!controller!.value.isPlaying) {
        playState.value = _VideoPlayState.isPlaying;
      } else {
        playState.value = _VideoPlayState.isBuffering;
      }
    } else {
      if (controller!.value.isPlaying) {
        playState.value = _VideoPlayState.isPlaying;
      } else {
        playState.value = _VideoPlayState.isPause;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget current = controller == null
        ? widget.cover ?? const SizedBox()
        : AspectRatio(
            aspectRatio: controller!.value.aspectRatio,
            child: VideoPlayer(controller!));
    return GestureDetector(
      onDoubleTap: controlsTap,
      child: Stack(children: [
        current,
        Center(child: controls),
      ]),
    );
  }

  Widget get controls => ValueListenableBuilder(
      valueListenable: playState,
      builder: (_, _VideoPlayState value, __) {
        switch (value) {
          case _VideoPlayState.isBuffering:
            return widget.loading;
          case _VideoPlayState.isPlaying:
            return const SizedBox();
          case _VideoPlayState.isInitialized:
            return widget.error;
          case _VideoPlayState.isPause:
            return centerPlayButton(show: true, isPlaying: false);
          case _VideoPlayState.isFinished:
            return centerPlayButton(show: true, isFinished: true);
        }
      });

  void controlsTap() {
    bool? isPlaying = controller?.value.isPlaying;
    if (isPlaying == true) {
      controller?.pause();
    } else if (isPlaying == false) {
      controller?.play();
    }
  }

  Widget centerPlayButton(
          {bool show = false,
          bool isPlaying = false,
          bool isFinished = false}) =>
      _CenterPlayButton(
          backgroundColor: Colors.black87,
          show: show,
          onPressed: controlsTap,
          iconColor: Colors.white,
          isPlaying: isPlaying,
          isFinished: isFinished);

  @override
  void didUpdateWidget(covariant PickerVideoPlayer oldWidget) {
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
        controller?.pause();
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.resumed:
        controller?.pause();
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    super.dispose();
    controller?.pause();
    controller?.removeListener(listener);
    controller?.dispose();
    playState.dispose();
    WidgetsBinding.instance?.removeObserver(this);
  }
}

class _CenterPlayButton extends StatelessWidget {
  const _CenterPlayButton({
    Key? key,
    required this.backgroundColor,
    this.iconColor,
    required this.show,
    required this.isPlaying,
    required this.isFinished,
    this.onPressed,
  }) : super(key: key);

  final Color backgroundColor;
  final Color? iconColor;
  final bool show;
  final bool isPlaying, isFinished;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Container(
      color: Colors.transparent,
      alignment: Alignment.center,
      child: AnimatedOpacity(
          opacity: show ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration:
                  BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
              child: IconButton(
                  iconSize: 32,
                  icon: isFinished
                      ? Icon(Icons.replay, color: iconColor)
                      : _AnimatedPlayPause(
                          color: iconColor, playing: isPlaying),
                  onPressed: onPressed))));
}

class _AnimatedPlayPause extends StatefulWidget {
  const _AnimatedPlayPause({
    Key? key,
    required this.playing,
    this.size,
    this.color,
  }) : super(key: key);

  final double? size;
  final bool playing;
  final Color? color;

  @override
  _AnimatedPlayPauseState createState() => _AnimatedPlayPauseState();
}

class _AnimatedPlayPauseState extends State<_AnimatedPlayPause>
    with SingleTickerProviderStateMixin {
  late final animationController = AnimationController(
      vsync: this,
      value: widget.playing ? 1 : 0,
      duration: const Duration(milliseconds: 400));

  @override
  void didUpdateWidget(_AnimatedPlayPause oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing != oldWidget.playing) {
      if (widget.playing) {
        animationController.forward();
      } else {
        animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedIcon(
      color: widget.color,
      size: widget.size,
      icon: AnimatedIcons.play_pause,
      progress: animationController);
}
