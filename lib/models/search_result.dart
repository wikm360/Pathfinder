import 'node.dart';

/// نتیجه جستجو که شامل مسیر و مراحل جستجو است
class SearchResult {
  final List<GraphNode> path; // مسیر نهایی از شروع تا هدف
  final List<SearchStep> steps; // تمام مراحل جستجو برای نمایش انیمیشن
  final bool pathFound; // آیا مسیر پیدا شد؟
  final int nodesExplored; // تعداد نودهای بررسی شده

  SearchResult({
    required this.path,
    required this.steps,
    required this.pathFound,
    required this.nodesExplored,
  });

  SearchResult.notFound()
      : path = [],
        steps = [],
        pathFound = false,
        nodesExplored = 0;
}

/// هر مرحله از جستجو برای نمایش گام به گام
class SearchStep {
  final GraphNode currentNode; // نود فعلی که داریم بررسی می‌کنیم
  final List<GraphNode> frontier; // نودهای در صف یا استک
  final List<GraphNode> explored; // نودهای بررسی شده
  final String description; // توضیح این مرحله

  SearchStep({
    required this.currentNode,
    required this.frontier,
    required this.explored,
    required this.description,
  });
}
