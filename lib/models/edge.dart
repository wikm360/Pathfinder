import 'node.dart';

/// کلاس یال که نمایانگر اتصال بین دو نود است
class GraphEdge {
  final GraphNode from;
  final GraphNode to;
  final double cost; // هزینه یال برای الگوریتم‌هایی مثل UCS و A*

  GraphEdge({
    required this.from,
    required this.to,
    required this.cost,
  });

  @override
  String toString() => 'Edge(${from.id} -> ${to.id}, cost: $cost)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GraphEdge &&
          runtimeType == other.runtimeType &&
          from == other.from &&
          to == other.to;

  @override
  int get hashCode => from.hashCode ^ to.hashCode;
}
