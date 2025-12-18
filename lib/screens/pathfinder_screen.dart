import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../models/graph.dart';
import '../models/node.dart';
import '../models/search_result.dart';
import '../algorithms/bfs.dart';
import '../algorithms/dfs.dart';
import '../algorithms/ucs.dart';
import '../algorithms/iterative_deepening.dart';
import '../algorithms/astar.dart';
import '../widgets/interactive_graph_view.dart';

class PathfinderScreen extends StatefulWidget {
  const PathfinderScreen({super.key});

  @override
  State<PathfinderScreen> createState() => _PathfinderScreenState();
}

class _PathfinderScreenState extends State<PathfinderScreen> {
  // مدل گراف
  Graph? graph;

  // نودهای انتخاب شده
  GraphNode? selectedStart;
  GraphNode? selectedGoal;

  // نتیجه جستجو
  SearchResult? searchResult;

  // انیمیشن
  int currentStep = 0;
  Timer? animationTimer;
  bool isAnimating = false;

  // الگوریتم انتخاب شده
  String selectedAlgorithm = 'BFS';

  // تنظیمات
  final TextEditingController nodeCountController = TextEditingController(text: '10');
  double animationSpeed = 500; // میلی‌ثانیه
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _generateGraph();
    }
  }

  @override
  void dispose() {
    animationTimer?.cancel();
    nodeCountController.dispose();
    super.dispose();
  }

  /// ایجاد گراف تصادفی
  void _generateGraph() {
    setState(() {
      animationTimer?.cancel();
      isAnimating = false;
      currentStep = 0;
      searchResult = null;
      selectedStart = null;
      selectedGoal = null;

      final nodeCount = int.tryParse(nodeCountController.text) ?? 10;
      final clampedCount = nodeCount.clamp(3, 30);

      // اندازه کانوس بر اساس اندازه صفحه (بزرگتر برای فضای بیشتر)
      final size = MediaQuery.of(context).size;
      final canvasWidth = size.width > 800 ? 1200.0 : size.width * 1.5;
      final canvasHeight = size.height > 600 ? 1000.0 : size.height * 1.5;

      graph = Graph.random(
        nodeCount: clampedCount,
        canvasSize: Size(canvasWidth, canvasHeight),
        edgeProbability: 0.25,
      );
    });
  }

  /// انتخاب نود با کلیک
  void _onNodeTap(Offset position) {
    if (graph == null || isAnimating) return;

    // پیدا کردن نزدیک‌ترین نود به موقعیت کلیک
    GraphNode? tappedNode;
    double minDistance = 30; // حداکثر فاصله برای تشخیص کلیک

    for (var node in graph!.nodes) {
      final distance = (node.position - position).distance;
      if (distance < minDistance) {
        minDistance = distance;
        tappedNode = node;
      }
    }

    if (tappedNode != null) {
      setState(() {
        if (selectedStart == null) {
          selectedStart = tappedNode;
        } else if (selectedGoal == null && tappedNode != selectedStart) {
          selectedGoal = tappedNode;
        } else {
          // ریست کردن انتخاب‌ها
          selectedStart = tappedNode;
          selectedGoal = null;
          searchResult = null;
          currentStep = 0;
        }
      });
    }
  }

  /// اجرای الگوریتم جستجو
  void _runSearch() {
    if (graph == null || selectedStart == null || selectedGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً نود شروع و هدف را انتخاب کنید'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isAnimating = true;
      currentStep = 0;

      // اجرای الگوریتم انتخاب شده
      switch (selectedAlgorithm) {
        case 'BFS':
          searchResult = BFS.search(graph!, selectedStart!, selectedGoal!);
          break;
        case 'DFS':
          searchResult = DFS.search(graph!, selectedStart!, selectedGoal!);
          break;
        case 'UCS':
          searchResult = UCS.search(graph!, selectedStart!, selectedGoal!);
          break;
        case 'ID':
          searchResult = IterativeDeepening.search(graph!, selectedStart!, selectedGoal!);
          break;
        case 'A*':
          searchResult = AStar.search(graph!, selectedStart!, selectedGoal!);
          break;
      }
    });

    // شروع انیمیشن
    _startAnimation();
  }

  /// شروع انیمیشن گام به گام
  void _startAnimation() {
    animationTimer?.cancel();

    if (searchResult == null || searchResult!.steps.isEmpty) {
      setState(() {
        isAnimating = false;
      });
      return;
    }

    animationTimer = Timer.periodic(
      Duration(milliseconds: animationSpeed.toInt()),
      (timer) {
        if (currentStep < searchResult!.steps.length - 1) {
          setState(() {
            currentStep++;
          });
        } else {
          timer.cancel();
          setState(() {
            isAnimating = false;
          });

          // نمایش نتیجه نهایی
          _showResultDialog();
        }
      },
    );
  }

  /// نمایش دیالوگ نتیجه
  void _showResultDialog() {
    if (searchResult == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          searchResult!.pathFound ? '✓ مسیر پیدا شد!' : '✗ مسیر یافت نشد',
          style: TextStyle(
            color: searchResult!.pathFound ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الگوریتم: $selectedAlgorithm'),
            const SizedBox(height: 8),
            Text('نودهای بررسی شده: ${searchResult!.nodesExplored}'),
            const SizedBox(height: 8),
            if (searchResult!.pathFound)
              Text('طول مسیر: ${searchResult!.path.length} نود'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('متوجه شدم'),
          ),
        ],
      ),
    );
  }

  /// ریست کردن
  void _reset() {
    setState(() {
      animationTimer?.cancel();
      isAnimating = false;
      currentStep = 0;
      searchResult = null;
      selectedStart = null;
      selectedGoal = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: const Text(
          'مسیریاب هوشمند گراف',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF16213e),
        elevation: 0,
      ),
      body: isWideScreen ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  /// طرح‌بندی برای صفحات بزرگ (دسکتاپ)
  Widget _buildWideLayout() {
    return Row(
      children: [
        // پنل کنترل
        Container(
          width: 320,
          color: const Color(0xFF16213e),
          child: _buildControlPanel(),
        ),
        // نمایش گراف
        Expanded(
          child: _buildGraphView(),
        ),
      ],
    );
  }

  /// طرح‌بندی برای صفحات کوچک (موبایل)
  Widget _buildNarrowLayout() {
    return Column(
      children: [
        // نمایش گراف
        Expanded(
          child: _buildGraphView(),
        ),
        // پنل کنترل
        Container(
          height: 200,
          color: const Color(0xFF16213e),
          child: SingleChildScrollView(
            child: _buildControlPanel(),
          ),
        ),
      ],
    );
  }

  /// پنل کنترل
  Widget _buildControlPanel() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // تنظیمات گراف
          _buildSection(
            'تنظیمات گراف',
            [
              TextField(
                controller: nodeCountController,
                decoration: const InputDecoration(
                  labelText: 'تعداد نودها (3-30)',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFF1a1a2e),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: isAnimating ? null : _generateGraph,
                icon: const Icon(Icons.refresh),
                label: const Text('ایجاد گراف جدید'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0f3460),
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // انتخاب الگوریتم
          _buildSection(
            'الگوریتم',
            [
              DropdownButtonFormField<String>(
                initialValue: selectedAlgorithm,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFF1a1a2e),
                ),
                dropdownColor: const Color(0xFF1a1a2e),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'BFS', child: Text('BFS - جستجوی سطحی')),
                  DropdownMenuItem(value: 'DFS', child: Text('DFS - جستجوی عمقی')),
                  DropdownMenuItem(value: 'UCS', child: Text('UCS - هزینه یکنواخت')),
                  DropdownMenuItem(value: 'ID', child: Text('ID - عمقی تکراری')),
                  DropdownMenuItem(value: 'A*', child: Text('A* - هیوریستیک')),
                ],
                onChanged: isAnimating ? null : (value) {
                  setState(() {
                    selectedAlgorithm = value!;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // سرعت انیمیشن
          _buildSection(
            'سرعت انیمیشن',
            [
              Slider(
                value: animationSpeed,
                min: 100,
                max: 2000,
                divisions: 19,
                label: '${animationSpeed.toInt()} ms',
                onChanged: (value) {
                  setState(() {
                    animationSpeed = value;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // دکمه‌های اجرا
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (isAnimating || selectedStart == null || selectedGoal == null)
                      ? null
                      : _runSearch,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('اجرا'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isAnimating ? null : _reset,
                  icon: const Icon(Icons.clear),
                  label: const Text('ریست'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // راهنما
          _buildSection(
            'راهنما',
            [
              _buildLegendItem(Colors.green, 'نود شروع'),
              _buildLegendItem(Colors.red, 'نود هدف'),
              _buildLegendItem(Colors.orange, 'در حال بررسی'),
              _buildLegendItem(Colors.yellow[700]!, 'در صف'),
              _buildLegendItem(Colors.grey[400]!, 'بررسی شده'),
              _buildLegendItem(Colors.green[400]!, 'مسیر نهایی'),
            ],
          ),

          if (searchResult != null && !isAnimating)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _buildSection(
                'نتیجه',
                [
                  Text(
                    searchResult!.pathFound ? 'مسیر پیدا شد ✓' : 'مسیر یافت نشد ✗',
                    style: TextStyle(
                      color: searchResult!.pathFound ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'نودهای بررسی شده: ${searchResult!.nodesExplored}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (searchResult!.pathFound)
                    Text(
                      'طول مسیر: ${searchResult!.path.length}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// نمایش گراف
  Widget _buildGraphView() {
    if (graph == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // گرفتن اطلاعات مرحله جاری
    List<GraphNode> currentExplored = [];
    List<GraphNode> currentFrontier = [];
    GraphNode? currentNode;
    String? stepDescription;

    if (searchResult != null && currentStep < searchResult!.steps.length) {
      final step = searchResult!.steps[currentStep];
      currentExplored = step.explored;
      currentFrontier = step.frontier;
      currentNode = step.currentNode;
      stepDescription = step.description;
    }

    return Container(
      color: const Color(0xFF0f3460),
      child: Column(
        children: [
          // نمایش توضیحات مرحله
          if (stepDescription != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF1a1a2e),
              child: Text(
                stepDescription,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // نمایش گراف با قابلیت تعاملی
          Expanded(
            child: InteractiveGraphView(
              graph: graph!,
              selectedStart: selectedStart,
              selectedGoal: selectedGoal,
              path: (searchResult != null && !isAnimating)
                  ? searchResult!.path
                  : [],
              explored: currentExplored,
              frontier: currentFrontier,
              currentNode: currentNode,
              onNodeTap: _onNodeTap,
              isAnimating: isAnimating,
            ),
          ),

          // نمایش وضعیت
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1a1a2e),
            child: Text(
              _getStatusText(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    if (selectedStart == null) {
      return 'روی یک نود کلیک کنید تا نود شروع را انتخاب کنید';
    } else if (selectedGoal == null) {
      return 'روی نود دیگری کلیک کنید تا نود هدف را انتخاب کنید';
    } else if (isAnimating) {
      return 'در حال اجرای الگوریتم... (مرحله ${currentStep + 1} از ${searchResult?.steps.length ?? 0})';
    } else if (searchResult != null) {
      return 'جستجو تکمیل شد. برای شروع مجدد، دکمه ریست را بزنید یا نود جدید انتخاب کنید';
    } else {
      return 'دکمه "اجرا" را بزنید تا الگوریتم $selectedAlgorithm اجرا شود';
    }
  }
}
