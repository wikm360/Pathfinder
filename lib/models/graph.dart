import 'dart:math';
import 'package:flutter/material.dart';
import 'node.dart';
import 'edge.dart';

// تابع کمکی برای max
T max<T extends Comparable<T>>(T a, T b) => a.compareTo(b) > 0 ? a : b;
T min<T extends Comparable<T>>(T a, T b) => a.compareTo(b) < 0 ? a : b;

/// کلاس گراف که شامل تمام نود‌ها و یال‌هاست
class Graph {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final bool isDirected;

  Graph({required this.nodes, required this.edges, this.isDirected = false});

  /// ایجاد گراف تصادفی
  factory Graph.random({
    required int nodeCount,
    required Size canvasSize,
    double edgeProbability = 0.3, // احتمال اتصال بین دو نود
    bool isDirected = false,
  }) {
    final random = Random();
    final nodes = <GraphNode>[];

    // محاسبه فاصله مناسب بین نودها
    final minDistance = max(
      80.0,
      min(canvasSize.width, canvasSize.height) / (nodeCount * 0.5),
    );

    // ایجاد نودها با فاصله مناسب از هم
    for (int i = 0; i < nodeCount; i++) {
      Offset position;
      int attempts = 0;

      do {
        position = Offset(
          random.nextDouble() * (canvasSize.width - 150) + 75,
          random.nextDouble() * (canvasSize.height - 150) + 75,
        );
        attempts++;

        // بررسی فاصله از نودهای دیگر
        bool tooClose = false;
        for (var existingNode in nodes) {
          if ((existingNode.position - position).distance < minDistance) {
            tooClose = true;
            break;
          }
        }

        if (!tooClose || attempts > 50) {
          break;
        }
      } while (true);

      nodes.add(GraphNode(id: i.toString(), position: position));
    }

    final edges = <GraphEdge>[];

    // ایجاد یال‌های تصادفی
    for (int i = 0; i < nodes.length; i++) {
      for (int j = 0; j < nodes.length; j++) {
        if (i == j) continue;

        // در گراف غیر جهت‌دار، فقط یک بار برای هر جفت بررسی می‌کنیم (مثلا i < j)
        if (!isDirected && i > j) continue;

        // با احتمال مشخص یال ایجاد می‌کنیم
        if (random.nextDouble() < edgeProbability) {
          final cost = (random.nextDouble() * 9 + 1); // هزینه بین 1 تا 10

          if (isDirected) {
            // یال یک طرفه
            edges.add(GraphEdge(from: nodes[i], to: nodes[j], cost: cost));
          } else {
            // یال دو طرفه (undirected graph)
            edges.add(GraphEdge(from: nodes[i], to: nodes[j], cost: cost));
            edges.add(GraphEdge(from: nodes[j], to: nodes[i], cost: cost));
          }
        }
      }
    }

    // اطمینان از اینکه گراف connected است
    _ensureConnectivity(nodes, edges, random, isDirected);

    return Graph(nodes: nodes, edges: edges, isDirected: isDirected);
  }

  /// اطمینان از اتصال گراف (هر نود حداقل یک یال داشته باشد)
  static void _ensureConnectivity(
    List<GraphNode> nodes,
    List<GraphEdge> edges,
    Random random,
    bool isDirected,
  ) {
    for (var node in nodes) {
      bool hasEdge = edges.any((e) => e.from == node || e.to == node);
      if (!hasEdge && nodes.length > 1) {
        // اگر نود یالی نداره، یکی بهش وصل می‌کنیم
        var otherNode = nodes.firstWhere((n) => n != node);
        final cost = (random.nextDouble() * 9 + 1);

        if (isDirected) {
          // در گراف جهت‌دار، حداقل یک یال خروجی یا ورودی می‌دهیم
          if (random.nextBool()) {
            edges.add(GraphEdge(from: node, to: otherNode, cost: cost));
          } else {
            edges.add(GraphEdge(from: otherNode, to: node, cost: cost));
          }
        } else {
          edges.add(GraphEdge(from: node, to: otherNode, cost: cost));
          edges.add(GraphEdge(from: otherNode, to: node, cost: cost));
        }
      }
    }
  }

  /// گرفتن همسایه‌های یک نود
  List<GraphEdge> getNeighbors(GraphNode node) {
    return edges.where((edge) => edge.from == node).toList();
  }

  /// محاسبه هیوریستیک (فاصله اقلیدسی) برای A*
  double heuristic(GraphNode from, GraphNode goal) {
    final dx = from.position.dx - goal.position.dx;
    final dy = from.position.dy - goal.position.dy;
    return sqrt(dx * dx + dy * dy) / 100; // نرمالایز شده
  }
}
