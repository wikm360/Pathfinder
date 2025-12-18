import 'dart:collection';
import '../models/graph.dart';
import '../models/node.dart';
import '../models/search_result.dart';

/// الگوریتم BFS (Breadth-First Search) - جستجوی سطح به سطح
///
/// این الگوریتم از یک صف (Queue) استفاده می‌کند و تمام نودهای یک سطح را
/// قبل از رفتن به سطح بعدی بررسی می‌کند.
/// تضمین می‌کند که کوتاه‌ترین مسیر (از نظر تعداد یال) پیدا شود.
class BFS {
  /// اجرای الگوریتم BFS
  static SearchResult search(Graph graph, GraphNode start, GraphNode goal) {
    // صف برای نگهداری نودهایی که باید بررسی شوند (FIFO)
    final Queue<GraphNode> frontier = Queue<GraphNode>();
    frontier.add(start);

    // مجموعه نودهای بررسی شده
    final Set<GraphNode> explored = {};

    // نقشه برای ردیابی مسیر (هر نود از کجا آمده)
    final Map<GraphNode, GraphNode> cameFrom = {};

    // لیست مراحل برای نمایش انیمیشن
    final List<SearchStep> steps = [];

    int nodesExplored = 0;

    // تا وقتی صف خالی نشده
    while (frontier.isNotEmpty) {
      // نود اول صف را برمی‌داریم
      final current = frontier.removeFirst();

      // مرحله جاری را ذخیره می‌کنیم
      steps.add(SearchStep(
        currentNode: current,
        frontier: List.from(frontier),
        explored: List.from(explored),
        description: 'بررسی نود ${current.id}',
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

        // اگر این نود قبلاً بررسی نشده و در صف نیست
        if (!explored.contains(neighbor) && !frontier.contains(neighbor)) {
          frontier.add(neighbor);
          cameFrom[neighbor] = current; // ردیابی مسیر
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

    // از هدف به سمت شروع برمی‌گردیم
    while (current != null) {
      path.add(current);
      if (current == start) break;
      current = cameFrom[current];
    }

    // مسیر را معکوس می‌کنیم (از شروع به هدف)
    return path.reversed.toList();
  }
}
