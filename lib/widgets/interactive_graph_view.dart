import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../models/graph.dart';
import '../models/node.dart';
import 'graph_painter.dart';
import 'glass_container.dart';

/// ویجت تعاملی برای نمایش گراف با قابلیت زوم، پن و درگ نودها
class InteractiveGraphView extends StatefulWidget {
  final Graph graph;
  final GraphNode? selectedStart;
  final GraphNode? selectedGoal;
  final List<GraphNode> path;
  final List<GraphNode> explored;
  final List<GraphNode> frontier;
  final GraphNode? currentNode;
  final Function(Offset)? onNodeTap;
  final bool isAnimating;

  const InteractiveGraphView({
    super.key,
    required this.graph,
    this.selectedStart,
    this.selectedGoal,
    this.path = const [],
    this.explored = const [],
    this.frontier = const [],
    this.currentNode,
    this.onNodeTap,
    this.isAnimating = false,
  });

  @override
  State<InteractiveGraphView> createState() => _InteractiveGraphViewState();
}

class _InteractiveGraphViewState extends State<InteractiveGraphView>
    with SingleTickerProviderStateMixin {
  // تنظیمات زوم و پن
  double _scale = 1.0;
  double _lastScale = 1.0;
  Offset _offset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;
  Offset _lastOffset = Offset.zero;

  // انیمیشن برای ریست کردن نما
  late AnimationController _resetController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _offsetAnimation;

  // درگ کردن نود
  GraphNode? _draggingNode;
  Offset? _dragStartPosition;
  bool _isDragging = false;
  bool _isPanning = false;

  @override
  void initState() {
    super.initState();
    _resetController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 500),
        )..addListener(() {
          setState(() {
            _scale = _scaleAnimation.value;
            _offset = _offsetAnimation.value;
          });
        });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          // تشخیص تپ برای انتخاب نود
          onTapUp: (details) {
            // فقط اگر درگ یا پن نکرده باشیم
            if (widget.isAnimating || _isDragging || _isPanning) return;

            // تبدیل موقعیت تپ به مختصات گراف
            final localPosition = _transformPosition(details.localPosition);

            // ابتدا بررسی می‌کنیم آیا روی نودی کلیک شده
            final tappedNode = _findNodeAtPosition(localPosition);

            if (widget.onNodeTap != null) {
              // اگر روی نود کلیک شده، موقعیت نود را ارسال می‌کنیم
              // اگر روی فضای خالی کلیک شده، همان موقعیت را ارسال می‌کنیم
              if (tappedNode != null) {
                widget.onNodeTap!(tappedNode.position);
              } else {
                // اگر روی نود کلیک نشده، شاید کاربر خواسته نود جدید بسازد (اگر قابلیت اضافه شود)
                // فعلا فقط موقعیت را می‌فرستیم
                widget.onNodeTap!(localPosition);
              }
            }
          },

          // شروع درگ نود یا پن/زوم
          onScaleStart: (details) {
            if (widget.isAnimating) return;

            final localPosition = _transformPosition(details.localFocalPoint);
            final node = _findNodeAtPosition(localPosition);

            if (node != null && details.pointerCount == 1) {
              // شروع درگ نود
              setState(() {
                _draggingNode = node;
                _dragStartPosition = details.localFocalPoint;
                _isDragging = true;
              });
            } else {
              // شروع پن کردن یا زوم
              setState(() {
                _startFocalPoint = details.localFocalPoint;
                _lastOffset = _offset;
                _lastScale = _scale;
                _isPanning = true;
              });
            }
          },

          // در حال درگ یا پن/زوم
          onScaleUpdate: (details) {
            if (_draggingNode != null) {
              // جابجایی نود (فقط با یک انگشت)
              if (details.pointerCount == 1) {
                final delta =
                    (details.localFocalPoint - _dragStartPosition!) / _scale;

                setState(() {
                  _draggingNode!.position += delta;
                  _dragStartPosition = details.localFocalPoint;
                });
              }
            } else {
              // پن کردن و زوم
              setState(() {
                // محاسبه مقیاس جدید
                final newScale = (_lastScale * details.scale).clamp(0.3, 3.0);

                // محاسبه آفست جدید برای زوم حول نقطه فوکال
                // فرمول: newOffset = focalPoint - (focalPoint - oldOffset) * (newScale / oldScale)
                final focalPoint = details.localFocalPoint;
                _offset =
                    focalPoint -
                    (focalPoint - _lastOffset) * (newScale / _lastScale);

                // اضافه کردن جابجایی پن (اگر اسکیل تغییر نکرده باشد یا همزمان)
                // در واقع details.focalPointDelta جابجایی لحظه‌ای را می‌دهد
                // اما چون ما از _lastOffset استفاده می‌کنیم، باید جابجایی کل را از شروع در نظر بگیریم
                // یا از focalPointDelta استفاده کنیم.
                // روش دقیق‌تر برای ترکیب هر دو:
                _offset +=
                    (details.localFocalPoint - _startFocalPoint) *
                        (newScale / _lastScale) -
                    (details.localFocalPoint - _startFocalPoint);
                // ساده‌تر:
                _scale = newScale;
                _offset =
                    _lastOffset + (details.localFocalPoint - _startFocalPoint);
              });
            }
          },

          // پایان درگ یا پن/زوم
          onScaleEnd: (details) {
            setState(() {
              _draggingNode = null;
              _dragStartPosition = null;
            });

            // بعد از یک فریم، فلگ‌های درگ و پن را ریست می‌کنیم
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                setState(() {
                  _isDragging = false;
                  _isPanning = false;
                });
              }
            });
          },

          child: Listener(
            // زوم با ماوس ویل
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                final delta = event.scrollDelta.dy;
                final newScale = (_scale - delta * 0.001).clamp(0.3, 3.0);

                setState(() {
                  _scale = newScale;
                });
              }
            },

            child: Stack(
              children: [
                // پس‌زمینه شطرنجی (Grid) که با پن جابجا می‌شود
                Positioned.fill(
                  child: CustomPaint(
                    painter: GridPainter(offset: _offset, scale: _scale),
                  ),
                ),

                // نمایش گراف
                ClipRect(
                  child: Transform(
                    transform: Matrix4.identity()
                      ..translate(_offset.dx, _offset.dy, 0)
                      ..scale(_scale, _scale, 1),
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: GraphPainter(
                        graph: widget.graph,
                        selectedStart: widget.selectedStart,
                        selectedGoal: widget.selectedGoal,
                        path: widget.path,
                        explored: widget.explored,
                        frontier: widget.frontier,
                        currentNode: widget.currentNode,
                      ),
                    ),
                  ),
                ),

                // کنترل‌های زوم و ابزارهای جانبی
                Positioned(
                  bottom: 30,
                  right: Directionality.of(context) == TextDirection.ltr
                      ? 20
                      : null,
                  left: Directionality.of(context) == TextDirection.rtl
                      ? 20
                      : null,
                  child: _buildFloatingToolbar(),
                ),

                // نمایش مقیاس زوم (بالا سمت چپ)
                Positioned(
                  top: 100,
                  left: Directionality.of(context) == TextDirection.ltr
                      ? 20
                      : null,
                  right: Directionality.of(context) == TextDirection.rtl
                      ? 20
                      : null,
                  child: _buildZoomIndicator(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildZoomIndicator() {
    return GlassContainer(
      color: Colors.black.withOpacity(0.3),
      blur: 10,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.zoom_in, size: 14, color: Colors.white.withOpacity(0.7)),
          const SizedBox(width: 6),
          Text(
            '${(_scale * 100).toInt()}%',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'Vazir',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingToolbar() {
    return GlassContainer(
      color: Colors.black.withOpacity(0.4),
      blur: 15,
      padding: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToolbarButton(
            icon: Icons.add,
            onPressed: () {
              setState(() {
                _scale = (_scale + 0.2).clamp(0.3, 3.0);
              });
            },
            color: const Color(0xFF00F0FF),
          ),
          const SizedBox(height: 8),
          _buildToolbarButton(
            icon: Icons.remove,
            onPressed: () {
              setState(() {
                _scale = (_scale - 0.2).clamp(0.3, 3.0);
              });
            },
            color: const Color(0xFF00F0FF),
          ),
          const SizedBox(height: 8),
          Container(height: 1, width: 24, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 8),
          _buildToolbarButton(
            icon: Icons.center_focus_strong,
            onPressed: _resetView,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  /// بازگشت به نمای اولیه با انیمیشن
  void _resetView() {
    _scaleAnimation = Tween<double>(begin: _scale, end: 1.0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutBack),
    );

    _offsetAnimation = Tween<Offset>(begin: _offset, end: Offset.zero).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutBack),
    );

    _resetController.forward(from: 0);
  }

  /// تبدیل موقعیت صفحه به مختصات گراف
  Offset _transformPosition(Offset screenPosition) {
    return (screenPosition - _offset) / _scale;
  }

  /// پیدا کردن نود در موقعیت مشخص
  GraphNode? _findNodeAtPosition(Offset position) {
    const nodeRadius = 40.0; // افزایش شعاع برای انتخاب راحت‌تر (قبلا 30 بود)

    GraphNode? closestNode;
    double minDistance = nodeRadius;

    // پیدا کردن نزدیک‌ترین نود
    for (var node in widget.graph.nodes) {
      final distance = (node.position - position).distance;
      if (distance < minDistance) {
        minDistance = distance;
        closestNode = node;
      }
    }

    return closestNode;
  }
}

/// رسم شبکه پس‌زمینه (Grid)
class GridPainter extends CustomPainter {
  final Offset offset;
  final double scale;

  GridPainter({required this.offset, required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1.0;

    final secondaryPaint = Paint()
      ..color = Colors.white.withOpacity(0.01)
      ..strokeWidth = 0.5;

    // اندازه هر خانه شبکه (با تغییر زوم تغییر می‌کند اما نه خطی)
    final double step = 50.0 * scale;
    final double subStep = step / 5;

    // محاسبه شروع رسم بر اساس آفست
    final double startX = offset.dx % step;
    final double startY = offset.dy % step;

    // رسم خطوط اصلی
    for (double x = startX; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = startY; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // رسم خطوط فرعی (فقط در زوم بالا)
    if (scale > 0.8) {
      for (double x = offset.dx % subStep; x < size.width; x += subStep) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), secondaryPaint);
      }
      for (double y = offset.dy % subStep; y < size.height; y += subStep) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), secondaryPaint);
      }
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) {
    return oldDelegate.offset != offset || oldDelegate.scale != scale;
  }
}
