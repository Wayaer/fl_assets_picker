import 'dart:ui' as ui;

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

class FlPreviewAssets extends StatelessWidget {
  const FlPreviewAssets(
      {Key? key,
      required this.itemCount,
      required this.itemBuilder,
      this.controller,
      this.close,
      this.overlay,
      this.pageSnapping = true,
      this.reverse = false,
      this.scrollDirection = Axis.horizontal,
      this.canScrollPage,
      this.physics,
      this.onPageChanged})
      : super(key: key);

  final int? itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ExtendedPageController? controller;
  final bool pageSnapping;
  final bool reverse;
  final Axis scrollDirection;
  final CanScrollPage? canScrollPage;
  final ScrollPhysics? physics;
  final ValueChanged<int>? onPageChanged;

  /// 关闭按钮
  final Widget? close;

  /// 在图片的上层
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.black.withOpacity(0.9),
        child: Stack(children: <Widget>[
          Container(
              width: double.infinity,
              height: double.infinity,
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).viewPadding.top,
                  bottom: MediaQuery.of(context).viewPadding.bottom),
              child: ExtendedImageGesturePageView.builder(
                  controller: controller,
                  itemCount: itemCount,
                  itemBuilder: itemBuilder,
                  physics: physics,
                  scrollDirection: scrollDirection,
                  reverse: reverse,
                  pageSnapping: pageSnapping,
                  onPageChanged: onPageChanged,
                  canScrollPage: canScrollPage)),
          close ??
              Container(
                  alignment: Alignment.bottomRight,
                  margin: EdgeInsets.only(
                      right: 12,
                      top:
                          MediaQueryData.fromWindow(ui.window).viewPadding.top +
                              12),
                  height: 40,
                  child: const CloseButton(color: Colors.white)),
          if (overlay != null) overlay!,
        ]));
  }
}
