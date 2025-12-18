import '../models/graph.dart';
import '../models/node.dart';
import '../models/search_result.dart';
import 'ucs.dart'; // استفاده از PriorityQueue

/// الگوریتم A* (A-Star) - جستجوی هیوریستیک
///
/// این الگوریتم از هیوریستیک (تخمین فاصله تا هدف) برای راهنمایی جستجو استفاده می‌کند.
/// f(n) = g(n) + h(n)
/// g(n) = هزینه واقعی از شروع تا n
/// h(n) = تخمین هزینه از n تا هدف (هیوریستیک)
///
/// اگر هیوریستیک admissible باشد (هرگز بیش‌تخمین نزند)، A* بهینه است.
class AStar {
  /// اجرای الگوریتم A*
  static SearchResult search(Graph graph, GraphNode start, GraphNode goal) {
    // صف اولویت‌دار بر اساس f(n) = g(n) + h(n)
    final PriorityQueue<_AStarNode> frontier = PriorityQueue<_AStarNode>(
      (a, b) => a.fScore.compareTo(b.fScore),
    );

    // محاسبه هیوریستیک برای نود شروع
    final startH = graph.heuristic(start, goal);
    frontier.add(_AStarNode(start, 0, startH));

    // مجموعه نودهای بررسی شده
    final Set<GraphNode> explored = {};

    // نقشه برای ردیابی مسیر
    final Map<GraphNode, GraphNode> cameFrom = {};

    // g(n): هزینه واقعی از شروع تا n
    final Map<GraphNode, double> gScore = {start: 0};

    // لیست مراحل برای نمایش انیمیشن
    final List<SearchStep> steps = [];

    int nodesExplored = 0;

    while (frontier.isNotEmpty) {
      // نودی با کمترین f(n) را برمی‌داریم
      final currentItem = frontier.removeFirst();
      final current = currentItem.node;

      // مرحله جاری را ذخیره می‌کنیم
      steps.add(SearchStep(
        currentNode: current,
        frontier: frontier.toList().map((e) => e.node).toList(),
        explored: List.from(explored),
        description:
            'بررسی نود ${current.id} (g=${currentItem.gScore.toStringAsFixed(1)}, h=${currentItem.hScore.toStringAsFixed(1)}, f=${currentItem.fScore.toStringAsFixed(1)})',
      ));

      nodesExplored++;

      // اگر به هدف رسیدیم
      if (current == goal) {
        final path = _reconstructPath(cameFrom, start, goal);
        return SearchResult(
          path: path,
          steps: steps,
          pathFound: true,
          nodesExplored: nodesExplored,
        );
      }

      // این نود را به بررسی شده‌ها اضافه می‌کنیم
      explored.add(current);

      // همسایه‌های این نود را بررسی می‌کنیم
      final neighbors = graph.getNeighbors(current);
      for (var edge in neighbors) {
        final neighbor = edge.to;

        // اگر قبلاً بررسی شده، رد می‌کنیم
        if (explored.contains(neighbor)) continue;

        // محاسبه g(neighbor) = g(current) + cost(current, neighbor)
        final tentativeG = gScore[current]! + edge.cost;

        // اگر مسیر جدید بهتر است
        if (!gScore.containsKey(neighbor) || tentativeG < gScore[neighbor]!) {
          // به‌روزرسانی مسیر
          cameFrom[neighbor] = current;
          gScore[neighbor] = tentativeG;

          // محاسبه h(neighbor) و f(neighbor)
          final h = graph.heuristic(neighbor, goal);

          frontier.add(_AStarNode(neighbor, tentativeG, h));
        }
      }
    }

    // اگر مسیری پیدا نشد
    return SearchResult(
      path: [],
      steps: steps,
      pathFound: false,
      nodesExplored: nodesExplored,
    );
  }

  /// بازسازی مسیر از نود شروع تا هدف
  static List<GraphNode> _reconstructPath(
    Map<GraphNode, GraphNode> cameFrom,
    GraphNode start,
    GraphNode goal,
  ) {
    final path = <GraphNode>[];
    GraphNode? current = goal;

    while (current != null) {
      path.add(current);
      if (current == start) break;
      current = cameFrom[current];
    }

    return path.reversed.toList();
  }
}

/// کلاس کمکی برای نگهداری نود و امتیازهای g, h, f در A*
class _AStarNode {
  final GraphNode node;
  final double gScore; // هزینه واقعی از شروع
  final double hScore; // تخمین هیوریستیک تا هدف
  final double fScore; // g + h

  _AStarNode(this.node, this.gScore, this.hScore)
      : fScore = gScore + hScore;
}
