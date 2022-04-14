import 'dart:ui' as ui;

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

class PreviewAssets extends StatelessWidget {
  const PreviewAssets(
      {Key? key,
      required this.itemCount,
      required this.itemBuilder,
      this.controller,
      this.header,
      this.footer,
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
  final Widget? header;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.black.withOpacity(0.9),
        child: Column(children: <Widget>[
          header ??
              Container(
                  alignment: Alignment.bottomRight,
                  margin: const EdgeInsets.only(right: 12),
                  height: MediaQueryData.fromWindow(ui.window).padding.top + 44,
                  child: const CloseButton(color: Colors.white)),
          Expanded(
              child: ExtendedImageGesturePageView.builder(
            controller: controller,
            itemCount: itemCount,
            itemBuilder: itemBuilder,
            physics: physics,
            scrollDirection: scrollDirection,
            reverse: reverse,
            pageSnapping: pageSnapping,
            onPageChanged: onPageChanged,
            canScrollPage: canScrollPage,
          )),
          if (footer != null) footer!
        ]));
  }
}
