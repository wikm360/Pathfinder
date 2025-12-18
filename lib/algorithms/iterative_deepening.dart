import '../models/graph.dart';
import '../models/node.dart';
import '../models/search_result.dart';

/// الگوریتم ID (Iterative Deepening) - جستجوی عمقی تکراری
///
/// این الگوریتم DFS را با محدودیت عمق مختلف تکرار می‌کند.
/// از عمق 0 شروع می‌کند و تا زمانی که هدف پیدا شود عمق را افزایش می‌دهد.
/// ترکیبی از مزایای BFS (پیدا کردن کوتاه‌ترین مسیر) و DFS (استفاده کم از حافظه)
class IterativeDeepening {
  static int _nodesExplored = 0;
  static List<SearchStep> _allSteps = [];

  /// اجرای الگوریتم Iterative Deepening
  static SearchResult search(Graph graph, GraphNode start, GraphNode goal) {
    _nodesExplored = 0;
    _allSteps = [];

    // از عمق 0 شروع می‌کنیم و تا پیدا کردن هدف افزایش می‌دهیم
    for (int depth = 0; depth < 1000; depth++) {
      _allSteps.add(SearchStep(
        currentNode: start,
        frontier: [start],
        explored: [],
        description: 'شروع جستجو با عمق محدود $depth',
      ));

      // DFS با محدودیت عمق
      final result = _depthLimitedSearch(
        graph,
        start,
        goal,
        depth,
        {},
        {},
      );

      if (result.pathFound) {
        return SearchResult(
          path: result.path,
          steps: _allSteps,
          pathFound: true,
          nodesExplored: _nodesExplored,
        );
      }
    }

    // اگر مسیری پیدا نشد
    return SearchResult(
      path: [],
      steps: _allSteps,
      pathFound: false,
      nodesExplored: _nodesExplored,
    );
  }

  /// DFS با محدودیت عمق
  static SearchResult _depthLimitedSearch(
    Graph graph,
    GraphNode current,
    GraphNode goal,
    int depthLimit,
    Map<GraphNode, GraphNode> cameFrom,
    Set<GraphNode> explored,
  ) {
    _nodesExplored++;

    _allSteps.add(SearchStep(
      currentNode: current,
      frontier: [],
      explored: List.from(explored),
      description: 'بررسی نود ${current.id} در عمق ${cameFrom.length}',
    ));

    // اگر به هدف رسیدیم
    if (current == goal) {
      final path = _reconstructPath(cameFrom, current, goal);
      return SearchResult(
        path: path,
        steps: _allSteps,
        pathFound: true,
        nodesExplored: _nodesExplored,
      );
    }

    // اگر به محدودیت عمق رسیدیم
    if (depthLimit <= 0) {
      return SearchResult.notFound();
    }

    explored.add(current);

    // بررسی همسایه‌ها
    final neighbors = graph.getNeighbors(current);
    for (var edge in neighbors) {
      final neighbor = edge.to;

      // جلوگیری از حلقه
      if (!explored.contains(neighbor)) {
        final newCameFrom = Map<GraphNode, GraphNode>.from(cameFrom);
        newCameFrom[neighbor] = current;

        final result = _depthLimitedSearch(
          graph,
          neighbor,
          goal,
          depthLimit - 1,
          newCameFrom,
          Set.from(explored),
        );

        if (result.pathFound) {
          return result;
        }
      }
    }

    return SearchResult.notFound();
  }

  /// بازسازی مسیر
  static List<GraphNode> _reconstructPath(
    Map<GraphNode, GraphNode> cameFrom,
    GraphNode start,
    GraphNode goal,
  ) {
    final path = <GraphNode>[];
    GraphNode? current = goal;

    while (current != null) {
      path.add(current);
      if (cameFrom.isEmpty || !cameFrom.containsKey(current)) break;
      current = cameFrom[current];
    }

    return path.reversed.toList();
  }
}
