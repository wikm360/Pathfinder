import 'package:flutter/material.dart';

/// کلاس نود که نمایانگر هر گره در گراف است
class GraphNode {
  final String id;
  Offset position; // موقعیت نود برای رسم گرافیکی

  GraphNode({
    required this.id,
    required this.position,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GraphNode && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Node($id)';
}
