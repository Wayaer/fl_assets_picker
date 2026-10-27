import 'package:fl_image_picker/fl_image_picker.dart';
import 'package:fl_video/fl_video.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 自定义 FlImageBuilder：图片支持缩放预览，视频使用 fl_video 播放
class DemoImageBuilder extends StatelessWidget {
  const DemoImageBuilder(this.file, {super.key, this.isThumbnail = true});

  final FlXFile file;

  /// 是否作为网格缩略图展示
  final bool isThumbnail;

  @override
  Widget build(BuildContext context) {
    switch (file.type) {
      case AssetType.image:
        final ImageProvider? provider = file.toImageProvider();
        if (provider != null) {
          final image = Image(
            image: provider,
            fit: isThumbnail ? BoxFit.cover : BoxFit.contain,
            errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
              return const _PreviewUnsupported(icon: Icons.broken_image_outlined, label: '图片加载失败');
            },
          );
          if (isThumbnail) return SizedBox.expand(child: image);
          return InteractiveViewer(minScale: 1, maxScale: 5, child: Center(child: image));
        }
        break;
      case AssetType.video:
        if (isThumbnail) {
          return const _VideoThumbnail();
        }
        final VideoPlayerController? controller = FlVideoView.buildController(file.realValue);
        if (controller != null) {
          return FlVideoView(controller: controller);
        }
        break;
      case AssetType.media:
        break;
    }
    return const _PreviewUnsupported(icon: Icons.visibility_off_outlined, label: '暂不支持预览');
  }
}

class _PreviewUnsupported extends StatelessWidget {
  const _PreviewUnsupported({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: scheme.onSurfaceVariant),
            const SizedBox(height: 6),
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _VideoThumbnail extends StatelessWidget {
  const _VideoThumbnail();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF25303B), Color(0xFF111821)],
        ),
      ),
      child: Center(child: Icon(Icons.movie_outlined, color: Colors.white70, size: 30)),
    );
  }
}

/// fl_video 播放器封装：自动初始化并循环播放，使用 Material 控制面板
class FlVideoView extends StatefulWidget {
  const FlVideoView({super.key, required this.controller});

  final VideoPlayerController controller;

  /// 根据 realValue 构建 VideoPlayerController
  static VideoPlayerController? buildController(dynamic value) {
    if (value is XFile) {
      return buildController(value.path);
    }
    if (value is File) {
      if (kIsWeb) return null;
      return VideoPlayerController.file(value);
    }
    if (value is String && value.isNotEmpty) {
      if (value.startsWith('http') || value.startsWith('blob:')) {
        return VideoPlayerController.networkUrl(Uri.parse(value));
      }
      if (kIsWeb) return VideoPlayerController.asset(value);
      return VideoPlayerController.file(File(value));
    }
    return null;
  }

  @override
  State<FlVideoView> createState() => _FlVideoViewState();
}

class _FlVideoViewState extends State<FlVideoView> {
  late final FlVideoPlayerController controller = FlVideoPlayerController(
    videoPlayerController: widget.controller,
    autoInitialize: true,
    autoPlay: true,
    looping: true,
    controls: FlMaterialControls(),
    placeholder: const ColoredBox(
      color: Colors.black,
      child: Center(child: CircularProgressIndicator(color: Colors.white70)),
    ),
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FlVideoPlayer(controller: controller);
}
