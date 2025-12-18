import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../models/graph.dart';
import '../models/node.dart';
import 'graph_painter.dart';

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

class _InteractiveGraphViewState extends State<InteractiveGraphView> {
  // تنظیمات زوم و پن
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;
  Offset _lastOffset = Offset.zero;

  // درگ کردن نود
  GraphNode? _draggingNode;
  Offset? _dragStartPosition;
  bool _isDragging = false;
  bool _isPanning = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
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
                widget.onNodeTap!(localPosition);
              }
            }
          },

          // شروع درگ نود یا پن
          onPanStart: (details) {
            if (widget.isAnimating) return;

            final localPosition = _transformPosition(details.localPosition);
            final node = _findNodeAtPosition(localPosition);

            if (node != null) {
              // شروع درگ نود
              setState(() {
                _draggingNode = node;
                _dragStartPosition = details.localPosition;
                _isDragging = false; // هنوز درگ نشده، منتظر حرکت هستیم
              });
            } else {
              // شروع پن کردن صفحه
              _startFocalPoint = details.localPosition;
              _lastOffset = _offset;
              _isPanning = false;
            }
          },

          // در حال درگ
          onPanUpdate: (details) {
            if (_draggingNode != null) {
              // جابجایی نود
              final delta = (details.localPosition - _dragStartPosition!) / _scale;

              // اگر حرکت معنادار بود، علامت بزن که داریم درگ می‌کنیم
              if (delta.distance > 2) {
                _isDragging = true;
              }

              setState(() {
                _draggingNode!.position += delta;
                _dragStartPosition = details.localPosition;
              });
            } else {
              // پن کردن صفحه
              final movement = details.localPosition - _startFocalPoint;

              // اگر حرکت معنادار بود، علامت بزن که داریم پن می‌کنیم
              if (movement.distance > 2) {
                _isPanning = true;
              }

              setState(() {
                _offset = _lastOffset + movement;
              });
            }
          },

          // پایان درگ
          onPanEnd: (details) {
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

          onPanCancel: () {
            setState(() {
              _draggingNode = null;
              _dragStartPosition = null;
            });

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

                // کنترل‌های زوم
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: _buildZoomControls(),
                ),

                // نمایش مقیاس زوم
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'زوم: ${(_scale * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                // راهنما
                if (!widget.isAnimating)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            '🖱️ اسکرول: زوم',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '👆 کلیک روی نود: انتخاب',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '✋ کشیدن نود: جابجایی نود',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '✋ کشیدن فضا: جابجایی صفحه',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// کنترل‌های زوم
  Widget _buildZoomControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              setState(() {
                _scale = (_scale + 0.2).clamp(0.3, 3.0);
              });
            },
            tooltip: 'زوم این',
          ),
          Container(
            height: 1,
            width: 40,
            color: Colors.white24,
          ),
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.white),
            onPressed: () {
              setState(() {
                _scale = (_scale - 0.2).clamp(0.3, 3.0);
              });
            },
            tooltip: 'زوم اوت',
          ),
          Container(
            height: 1,
            width: 40,
            color: Colors.white24,
          ),
          IconButton(
            icon: const Icon(Icons.center_focus_strong, color: Colors.white),
            onPressed: _resetView,
            tooltip: 'بازگشت به حالت اولیه',
          ),
        ],
      ),
    );
  }

  /// بازگشت به نمای اولیه
  void _resetView() {
    setState(() {
      _scale = 1.0;
      _offset = Offset.zero;
    });
  }

  /// تبدیل موقعیت صفحه به مختصات گراف
  Offset _transformPosition(Offset screenPosition) {
    return (screenPosition - _offset) / _scale;
  }

  /// پیدا کردن نود در موقعیت مشخص
  GraphNode? _findNodeAtPosition(Offset position) {
    const nodeRadius = 30.0; // شعاع بزرگتر برای انتخاب آسان‌تر

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
