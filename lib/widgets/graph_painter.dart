import 'dart:math';
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
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final costPaint = Paint()
      ..color = const Color(0xFF151628)
      ..style = PaintingStyle.fill;

    final costBorderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final Set<String> drawnEdges = {};

    for (var edge in graph.edges) {
      // در گراف غیر جهت‌دار، از رسم دوباره یال‌های برگشتی جلوگیری می‌کنیم
      if (!graph.isDirected) {
        final edgeKey = _getEdgeKey(edge.from, edge.to);
        if (drawnEdges.contains(edgeKey)) continue;
        drawnEdges.add(edgeKey);
      }

      // رسم خط یال
      canvas.drawLine(edge.from.position, edge.to.position, edgePaint);

      // اگر گراف جهت‌دار است، فلش رسم می‌کنیم
      if (graph.isDirected) {
        _drawArrow(canvas, edge.from.position, edge.to.position, edgePaint);
      }

      // رسم هزینه یال در وسط
      final midPoint = Offset(
        (edge.from.position.dx + edge.to.position.dx) / 2,
        (edge.from.position.dy + edge.to.position.dy) / 2,
      );

      // پس‌زمینه تیره برای خوانایی بهتر
      canvas.drawCircle(midPoint, 10, costPaint);
      canvas.drawCircle(midPoint, 10, costBorderPaint);

      // متن هزینه
      final textSpan = TextSpan(
        text: edge.cost.toStringAsFixed(1),
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 9,
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

  /// رسم فلش برای یال‌های جهت‌دار
  void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    const double arrowSize = 10.0;
    const double nodeRadius = 20.0; // شعاع تقریبی نود

    final double angle = atan2(to.dy - from.dy, to.dx - from.dx);

    // محاسبه نقطه پایان فلش (روی محیط دایره نود مقصد)
    final endPoint = Offset(
      to.dx - nodeRadius * cos(angle),
      to.dy - nodeRadius * sin(angle),
    );

    final path = Path();
    path.moveTo(endPoint.dx, endPoint.dy);
    path.lineTo(
      endPoint.dx - arrowSize * cos(angle - pi / 6),
      endPoint.dy - arrowSize * sin(angle - pi / 6),
    );
    path.lineTo(
      endPoint.dx - arrowSize * cos(angle + pi / 6),
      endPoint.dy - arrowSize * sin(angle + pi / 6),
    );
    path.close();

    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  /// رسم مسیر نهایی
  void _drawPath(Canvas canvas) {
    // رسم هاله درخشان زیر مسیر
    final glowPaint = Paint()
      ..color = const Color(0xFF7000FF).withOpacity(0.5)
      ..strokeWidth = 12
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..style = PaintingStyle.stroke;

    final pathPaint = Paint()
      ..color =
          const Color(0xFF7000FF) // Neon Purple
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < path.length - 1; i++) {
      canvas.drawLine(path[i].position, path[i + 1].position, glowPaint);
      canvas.drawLine(path[i].position, path[i + 1].position, pathPaint);
    }
  }

  /// رسم نودها
  void _drawNodes(Canvas canvas) {
    for (var node in graph.nodes) {
      Color nodeColor = const Color(
        0xFF00F0FF,
      ).withOpacity(0.3); // Default Cyan
      Color borderColor = const Color(0xFF00F0FF);
      double nodeSize = 18;
      bool hasGlow = false;

      // رنگ‌بندی بر اساس وضعیت نود
      if (node == selectedStart) {
        nodeColor = const Color(0xFF00FF9D); // Neon Green
        borderColor = Colors.white;
        nodeSize = 22;
        hasGlow = true;
      } else if (node == selectedGoal) {
        nodeColor = const Color(0xFFFF0055); // Neon Pink
        borderColor = Colors.white;
        nodeSize = 22;
        hasGlow = true;
      } else if (path.contains(node)) {
        nodeColor = const Color(0xFF7000FF); // Neon Purple
        borderColor = Colors.white;
        nodeSize = 20;
        hasGlow = true;
      } else if (node == currentNode) {
        nodeColor = const Color(0xFF00F0FF); // Cyan
        borderColor = Colors.white;
        nodeSize = 22;
        hasGlow = true;
      } else if (explored.contains(node)) {
        nodeColor = Colors.grey.withOpacity(0.3);
        borderColor = Colors.grey;
      } else if (frontier.contains(node)) {
        nodeColor = const Color(0xFFFFD600); // Yellow
        borderColor = Colors.white;
      }

      // رسم درخشش (Glow)
      if (hasGlow) {
        final glowPaint = Paint()
          ..color = nodeColor.withOpacity(0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(node.position, nodeSize + 5, glowPaint);
      }

      // رسم دایره نود
      final nodePaint = Paint()
        ..color = nodeColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(node.position, nodeSize, nodePaint);

      // رسم حاشیه
      final borderPaint = Paint()
        ..color = borderColor
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
