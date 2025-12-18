import '../models/graph.dart';
import '../models/node.dart';
import '../models/search_result.dart';

/// الگوریتم UCS (Uniform Cost Search) - جستجوی با هزینه یکنواخت
///
/// این الگوریتم نودها را بر اساس کمترین هزینه مسیر از شروع بررسی می‌کند.
/// از یک صف اولویت‌دار (Priority Queue) استفاده می‌کند.
/// تضمین می‌کند که ارزان‌ترین مسیر پیدا شود.
class UCS {
  /// اجرای الگوریتم UCS
  static SearchResult search(Graph graph, GraphNode start, GraphNode goal) {
    // صف اولویت‌دار برای نگهداری نودها با هزینه‌شان
    final PriorityQueue<_PriorityNode> frontier = PriorityQueue<_PriorityNode>(
      (a, b) => a.cost.compareTo(b.cost),
    );
    frontier.add(_PriorityNode(start, 0));

    // مجموعه نودهای بررسی شده
    final Set<GraphNode> explored = {};

    // نقشه برای ردیابی مسیر
    final Map<GraphNode, GraphNode> cameFrom = {};

    // نقشه برای ذخیره هزینه رسیدن به هر نود
    final Map<GraphNode, double> costSoFar = {start: 0};

    // لیست مراحل برای نمایش انیمیشن
    final List<SearchStep> steps = [];

    int nodesExplored = 0;

    while (frontier.isNotEmpty) {
      // نودی با کمترین هزینه را برمی‌داریم
      final currentItem = frontier.removeFirst();
      final current = currentItem.node;

      // مرحله جاری را ذخیره می‌کنیم
      steps.add(SearchStep(
        currentNode: current,
        frontier: frontier.toList().map((e) => e.node).toList(),
        explored: List.from(explored),
        description:
            'بررسی نود ${current.id} (هزینه: ${currentItem.cost.toStringAsFixed(1)})',
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

        // محاسبه هزینه جدید برای رسیدن به همسایه
        final newCost = costSoFar[current]! + edge.cost;

        // اگر همسایه بررسی نشده یا مسیر جدید ارزان‌تر است
        if (!explored.contains(neighbor) &&
            (!costSoFar.containsKey(neighbor) ||
                newCost < costSoFar[neighbor]!)) {
          costSoFar[neighbor] = newCost;
          frontier.add(_PriorityNode(neighbor, newCost));
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

/// کلاس کمکی برای نگهداری نود و هزینه در صف اولویت‌دار
class _PriorityNode {
  final GraphNode node;
  final double cost;

  _PriorityNode(this.node, this.cost);
}

/// پیاده‌سازی صف اولویت‌دار
class PriorityQueue<T> {
  final List<T> _items = [];
  final Comparator<T> _comparator;

  PriorityQueue(this._comparator);

  void add(T item) {
    _items.add(item);
    _items.sort(_comparator);
  }

  T removeFirst() {
    return _items.removeAt(0);
  }

  bool get isNotEmpty => _items.isNotEmpty;

  List<T> toList() => List.from(_items);
}
