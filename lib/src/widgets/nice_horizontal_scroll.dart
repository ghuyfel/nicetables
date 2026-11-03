import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A horizontal [Scrollable] whose child is NOT moved; instead descendants
/// wrapped in [NiceHorizontalShift] translate themselves by the scroll
/// offset.
///
/// This is what lets the table keep one vertical list for header, rows and
/// expanded details while pinned columns stay put: each row lays out as
/// `[pinned cells][shifted scrolling cells]`, all driven by one offset.
class NiceHorizontalScroller extends StatelessWidget {
  /// Creates the scroller.
  const NiceHorizontalScroller({
    required this.controller,
    required this.contentWidth,
    required this.builder,
    super.key,
  });

  /// Drives and reports the horizontal position.
  final ScrollController controller;

  /// Full width of the table: pinned block plus scrolling columns.
  final double contentWidth;

  /// Builds the child; [NiceHorizontalShift] descendants read [offset].
  final Widget Function(BuildContext context, ViewportOffset offset) builder;

  @override
  Widget build(BuildContext context) => Scrollable(
        controller: controller,
        axisDirection: AxisDirection.right,
        physics: const ClampingScrollPhysics(),
        viewportBuilder: (context, offset) => _HorizontalViewport(
          offset: offset,
          contentWidth: contentWidth,
          child: builder(context, offset),
        ),
      );
}

class _HorizontalViewport extends SingleChildRenderObjectWidget {
  const _HorizontalViewport({
    required this.offset,
    required this.contentWidth,
    required super.child,
  });

  final ViewportOffset offset;
  final double contentWidth;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHorizontalViewport(offset: offset, contentWidth: contentWidth);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderHorizontalViewport renderObject,
  ) {
    renderObject
      ..offset = offset
      ..contentWidth = contentWidth;
  }
}

class _RenderHorizontalViewport extends RenderProxyBox {
  _RenderHorizontalViewport({
    required ViewportOffset offset,
    required double contentWidth,
  })  : _offset = offset,
        _contentWidth = contentWidth;

  ViewportOffset _offset;
  ViewportOffset get offset => _offset;
  set offset(ViewportOffset value) {
    if (identical(value, _offset)) return;
    _offset = value;
    markNeedsLayout();
  }

  double _contentWidth;
  double get contentWidth => _contentWidth;
  set contentWidth(double value) {
    if (value == _contentWidth) return;
    _contentWidth = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
    } else {
      child.layout(constraints, parentUsesSize: true);
      size = child.size;
    }
    // [contentWidth] is the full table width (pinned block plus scrolling
    // columns), so the scroll extent is simply what does not fit. Each
    // shift widget clamps the same offset against its own narrower width.
    _offset.applyViewportDimension(size.width);
    _offset.applyContentDimensions(0, math.max(0, _contentWidth - size.width));
  }
}

/// Translates its child horizontally by the [ViewportOffset] of the
/// enclosing [NiceHorizontalScroller], clipping to its own bounds.
///
/// The child is laid out at [contentWidth] regardless of the available
/// width. Hit testing and paint transforms follow the shift.
class NiceHorizontalShift extends SingleChildRenderObjectWidget {
  /// Creates a shifted box.
  const NiceHorizontalShift({
    required this.offset,
    required this.contentWidth,
    required super.child,
    super.key,
  });

  /// The scroll offset to follow.
  final ViewportOffset offset;

  /// Width to lay the child out at.
  final double contentWidth;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderNiceHorizontalShift(offset: offset, contentWidth: contentWidth);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderNiceHorizontalShift renderObject,
  ) {
    renderObject
      ..offset = offset
      ..contentWidth = contentWidth;
  }
}

/// Render object behind [NiceHorizontalShift].
class RenderNiceHorizontalShift extends RenderProxyBox {
  /// Creates the render object.
  RenderNiceHorizontalShift({
    required ViewportOffset offset,
    required double contentWidth,
  })  : _offset = offset,
        _contentWidth = contentWidth;

  ViewportOffset _offset;

  /// The scroll offset followed.
  ViewportOffset get offset => _offset;
  set offset(ViewportOffset value) {
    if (identical(value, _offset)) return;
    if (attached) _offset.removeListener(markNeedsPaint);
    _offset = value;
    if (attached) _offset.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  double _contentWidth;

  /// Width the child is laid out at.
  double get contentWidth => _contentWidth;
  set contentWidth(double value) {
    if (value == _contentWidth) return;
    _contentWidth = value;
    markNeedsLayout();
  }

  double get _dx {
    final max = math.max(0.0, _contentWidth - size.width);
    return -_offset.pixels.clamp(0.0, max);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _offset.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _offset.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(
      BoxConstraints(
        minWidth: _contentWidth,
        maxWidth: _contentWidth,
        minHeight: constraints.minHeight,
        maxHeight: constraints.maxHeight,
      ),
      parentUsesSize: true,
    );
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : math.min(_contentWidth, constraints.maxWidth);
    size = constraints.constrain(Size(width, child.size.height));
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      (context, offset) => context.paintChild(child, offset + Offset(_dx, 0)),
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    if (!(Offset.zero & size).contains(position)) return false;
    return result.addWithPaintOffset(
      offset: Offset(_dx, 0),
      position: position,
      hitTest: (result, transformed) =>
          child.hitTest(result, position: transformed),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.translateByDouble(_dx, 0, 0, 1);
  }
}
