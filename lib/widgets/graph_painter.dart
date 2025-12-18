import 'package:flutter/material.dart';
import '../models/graph.dart';
import '../models/node.dart';

/// ویجت سفارشی برای رسم گراف
class GraphPainter extends CustomPainter {
  final Graph graph;
  final GraphNode? selectedStart;
  final GraphNode? selectedGoal;
  final List<GraphNode> path;
  final List<GraphNode> explored;
  final List<GraphNode> frontier;
  final GraphNode? currentNode;

  GraphPainter({
    required this.graph,
    this.selectedStart,
    this.selectedGoal,
    this.path = const [],
    this.explored = const [],
    this.frontier = const [],
    this.currentNode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // رسم یال‌ها
    _drawEdges(canvas);

    // رسم مسیر نهایی (با رنگ سبز)
    if (path.length > 1) {
      _drawPath(canvas);
    }

    // رسم نودها
    _drawNodes(canvas);
  }

  /// رسم یال‌ها
  void _drawEdges(Canvas canvas) {
    final edgePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final costPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Set<String> drawnEdges = {};

    for (var edge in graph.edges) {
      // برای جلوگیری از رسم دوباره یال‌های دوطرفه
      final edgeKey = _getEdgeKey(edge.from, edge.to);
      if (drawnEdges.contains(edgeKey)) continue;
      drawnEdges.add(edgeKey);

      canvas.drawLine(edge.from.position, edge.to.position, edgePaint);

      // رسم هزینه یال در وسط
      final midPoint = Offset(
        (edge.from.position.dx + edge.to.position.dx) / 2,
        (edge.from.position.dy + edge.to.position.dy) / 2,
      );

      // پس‌زمینه سفید برای خوانایی بهتر
      canvas.drawCircle(midPoint, 12, costPaint);

      // متن هزینه
      final textSpan = TextSpan(
        text: edge.cost.toStringAsFixed(1),
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        midPoint - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  /// رسم مسیر نهایی
  void _drawPath(Canvas canvas) {
    final pathPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < path.length - 1; i++) {
      canvas.drawLine(path[i].position, path[i + 1].position, pathPaint);
    }
  }

  /// رسم نودها
  void _drawNodes(Canvas canvas) {
    for (var node in graph.nodes) {
      Color nodeColor = Colors.blue[300]!;
      double nodeSize = 20;

      // رنگ‌بندی بر اساس وضعیت نود
      if (node == selectedStart) {
        nodeColor = Colors.green;
        nodeSize = 25;
      } else if (node == selectedGoal) {
        nodeColor = Colors.red;
        nodeSize = 25;
      } else if (path.contains(node)) {
        nodeColor = Colors.green[400]!;
        nodeSize = 22;
      } else if (node == currentNode) {
        nodeColor = Colors.orange;
        nodeSize = 23;
      } else if (explored.contains(node)) {
        nodeColor = Colors.grey[400]!;
      } else if (frontier.contains(node)) {
        nodeColor = Colors.yellow[700]!;
      }

      // رسم دایره نود
      final nodePaint = Paint()
        ..color = nodeColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(node.position, nodeSize, nodePaint);

      // رسم حاشیه
      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(node.position, nodeSize, borderPaint);

      // رسم شماره نود
      final textSpan = TextSpan(
        text: node.id,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        node.position - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  String _getEdgeKey(GraphNode from, GraphNode to) {
    final ids = [from.id, to.id]..sort();
    return '${ids[0]}-${ids[1]}';
  }

  @override
  bool shouldRepaint(GraphPainter oldDelegate) {
    return oldDelegate.selectedStart != selectedStart ||
        oldDelegate.selectedGoal != selectedGoal ||
        oldDelegate.path != path ||
        oldDelegate.explored != explored ||
        oldDelegate.frontier != frontier ||
        oldDelegate.currentNode != currentNode;
  }
}
