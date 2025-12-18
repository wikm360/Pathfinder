import '../models/graph.dart';
import '../models/node.dart';
import '../models/search_result.dart';

/// الگوریتم DFS (Depth-First Search) - جستجوی عمق محور
///
/// این الگوریتم از یک استک (Stack) استفاده می‌کند و تا انتهای هر مسیر
/// پیش می‌رود و سپس برمی‌گردد (Backtracking).
/// مسیر پیدا شده لزوماً کوتاه‌ترین نیست.
class DFS {
  /// اجرای الگوریتم DFS
  static SearchResult search(Graph graph, GraphNode start, GraphNode goal) {
    // استک برای نگهداری نودهایی که باید بررسی شوند (LIFO)
    final List<GraphNode> frontier = [start];

    // مجموعه نودهای بررسی شده
    final Set<GraphNode> explored = {};

    // نقشه برای ردیابی مسیر
    final Map<GraphNode, GraphNode> cameFrom = {};

    // لیست مراحل برای نمایش انیمیشن
    final List<SearchStep> steps = [];

    int nodesExplored = 0;

    // تا وقتی استک خالی نشده
    while (frontier.isNotEmpty) {
      // نود آخر استک را برمی‌داریم (LIFO)
      final current = frontier.removeLast();

      // اگر قبلاً بررسی شده، رد می‌کنیم
      if (explored.contains(current)) continue;

      // مرحله جاری را ذخیره می‌کنیم
      steps.add(SearchStep(
        currentNode: current,
        frontier: List.from(frontier),
        explored: List.from(explored),
        description: 'بررسی نود ${current.id} (عمق محور)',
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

      // همسایه‌های این نود را به استک اضافه می‌کنیم
      final neighbors = graph.getNeighbors(current);
      for (var edge in neighbors) {
        final neighbor = edge.to;

        // اگر بررسی نشده و در استک نیست
        if (!explored.contains(neighbor) && !frontier.contains(neighbor)) {
          frontier.add(neighbor); // به انتهای استک اضافه می‌شود
          cameFrom[neighbor] = current;
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
