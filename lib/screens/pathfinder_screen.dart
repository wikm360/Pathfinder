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
import '../widgets/glass_container.dart';

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
  final TextEditingController nodeCountController = TextEditingController(
    text: '10',
  );
  double animationSpeed = 500; // میلی‌ثانیه
  bool isDirected = false; // گراف جهت‌دار
  bool _initialized = false;
  bool _isConfigOpen = false; // وضعیت پنل تنظیمات

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
        isDirected: isDirected,
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
          searchResult = IterativeDeepening.search(
            graph!,
            selectedStart!,
            selectedGoal!,
          );
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
        backgroundColor: const Color(0xFF151628),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          searchResult!.pathFound ? 'مسیر یافت شد' : 'مسیر یافت نشد',
          style: TextStyle(
            color: searchResult!.pathFound
                ? const Color(0xFF00FF9D)
                : const Color(0xFFFF0055),
            fontWeight: FontWeight.bold,
            fontFamily: 'Vazir',
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultRow('الگوریتم:', selectedAlgorithm),
            const SizedBox(height: 8),
            _buildResultRow(
              'نودهای بررسی شده:',
              '${searchResult!.nodesExplored}',
            ),
            const SizedBox(height: 8),
            if (searchResult!.pathFound)
              _buildResultRow(
                'طول مسیر:',
                '${searchResult!.path.length - 1} یال',
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'متوجه شدم',
              style: TextStyle(color: Color(0xFF00F0FF), fontFamily: 'Vazir'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontFamily: 'Vazir'),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Vazir',
          ),
        ),
      ],
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
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'مسیریاب',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isConfigOpen ? Icons.close : Icons.settings,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isConfigOpen = !_isConfigOpen;
              });
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          // پس‌زمینه کهکشانی (می‌تواند یک تصویر یا گرادینت باشد)
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [Color(0xFF1a1a2e), Color(0xFF0f0f1a), Colors.black],
              ),
            ),
          ),

          // نمایش گراف (تمام صفحه)
          Positioned.fill(child: _buildGraphView()),

          // پنل تنظیمات (Overlay)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutBack,
            top: isMobile ? (_isConfigOpen ? 100 : -600) : 80,
            left: Directionality.of(context) == TextDirection.rtl
                ? (_isConfigOpen ? 20 : (isMobile ? 20 : -400))
                : null,
            right: Directionality.of(context) == TextDirection.ltr
                ? (_isConfigOpen ? 20 : (isMobile ? 20 : -400))
                : null,
            bottom: isMobile ? (_isConfigOpen ? 20 : null) : 80,
            width: isMobile ? size.width - 40 : 350,
            height: isMobile ? null : null, // ارتفاع خودکار در دسکتاپ
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isConfigOpen ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !_isConfigOpen,
                child: GlassContainer(
                  color: Colors.black.withOpacity(0.6),
                  blur: 15,
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(child: _buildControlPanel()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// پنل کنترل
  Widget _buildControlPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'تنظیمات مسیریاب',
          style: TextStyle(
            color: Color(0xFF00F0FF),
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Vazir',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // ردیف اول: تعداد نود و نوع گراف
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildSection('تعداد نودها', [
                TextField(
                  controller: nodeCountController,
                  decoration: InputDecoration(
                    hintText: '3-30',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF00F0FF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF00F0FF)),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Vazir',
                  ),
                  textAlign: TextAlign.center,
                ),
              ]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSection('نوع گراف', [
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'جهت‌دار',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'Vazir',
                        ),
                      ),
                      Switch(
                        value: isDirected,
                        onChanged: isAnimating
                            ? null
                            : (value) {
                                setState(() {
                                  isDirected = value;
                                });
                              },
                        activeColor: const Color(0xFF00F0FF),
                        activeTrackColor: const Color(
                          0xFF00F0FF,
                        ).withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // دکمه ایجاد گراف جدید
        ElevatedButton(
          onPressed: isAnimating ? null : _generateGraph,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00F0FF),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            'تولید گراف جدید',
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazir'),
          ),
        ),

        const SizedBox(height: 24),
        const Divider(color: Colors.white24),
        const SizedBox(height: 24),

        // انتخاب الگوریتم
        _buildSection('الگوریتم جستجو', [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedAlgorithm,
                dropdownColor: const Color(0xFF151628),
                isExpanded: true,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Vazir',
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFF00F0FF),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'BFS',
                    child: Text('جستجوی سطح اول (BFS)'),
                  ),
                  DropdownMenuItem(
                    value: 'DFS',
                    child: Text('جستجوی عمق اول (DFS)'),
                  ),
                  DropdownMenuItem(
                    value: 'UCS',
                    child: Text('جستجوی هزینه یکنواخت (UCS)'),
                  ),
                  DropdownMenuItem(
                    value: 'ID',
                    child: Text('جستجوی عمیق تکرار‌شونده (ID)'),
                  ),
                  DropdownMenuItem(value: 'A*', child: Text('جستجوی A*')),
                ],
                onChanged: isAnimating
                    ? null
                    : (value) {
                        setState(() {
                          selectedAlgorithm = value!;
                        });
                      },
              ),
            ),
          ),
        ]),

        const SizedBox(height: 20),

        // سرعت انیمیشن
        _buildSection('سرعت اجرا', [
          Row(
            children: [
              const Text(
                'کند',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontFamily: 'Vazir',
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF7000FF),
                    inactiveTrackColor: Colors.white.withOpacity(0.2),
                    thumbColor: const Color(0xFF00F0FF),
                    overlayColor: const Color(0xFF00F0FF).withOpacity(0.2),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                  ),
                  child: Slider(
                    value: 2100 - animationSpeed,
                    min: 100,
                    max: 2000,
                    divisions: 19,
                    onChanged: (value) {
                      setState(() {
                        animationSpeed = 2100 - value;
                      });
                    },
                  ),
                ),
              ),
              const Text(
                'تند',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontFamily: 'Vazir',
                ),
              ),
            ],
          ),
        ]),

        const SizedBox(height: 24),

        // دکمه ریست
        ElevatedButton(
          onPressed: isAnimating ? null : _reset,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            elevation: 0,
          ),
          child: const Text(
            'بازنشانی وضعیت',
            style: TextStyle(fontFamily: 'Vazir'),
          ),
        ),

        const SizedBox(height: 24),

        // راهنما
        _buildSection('راهنمای نقشه', [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildLegendChip(const Color(0xFF00FF9D), 'شروع'),
              _buildLegendChip(const Color(0xFFFF0055), 'هدف'),
              _buildLegendChip(const Color(0xFFFFD600), 'در صف'),
              _buildLegendChip(const Color(0xFF00F0FF), 'بررسی شده'),
              _buildLegendChip(Colors.grey, 'مشاهده شده'),
              _buildLegendChip(const Color(0xFF7000FF), 'مسیر نهایی'),
            ],
          ),
        ]),

        if (searchResult != null && !isAnimating)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: searchResult!.pathFound
                    ? const Color(0xFF00FF9D).withOpacity(0.1)
                    : const Color(0xFFFF0055).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: searchResult!.pathFound
                      ? const Color(0xFF00FF9D)
                      : const Color(0xFFFF0055),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    searchResult!.pathFound
                        ? 'مسیر بهینه یافت شد'
                        : 'مسیری بین دو نقطه وجود ندارد',
                    style: TextStyle(
                      color: searchResult!.pathFound
                          ? const Color(0xFF00FF9D)
                          : const Color(0xFFFF0055),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Vazir',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'تعداد گام‌ها: ${searchResult!.path.length - 1}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Vazir',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLegendChip(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
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
            color: Color(0xFF00F0FF),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  // حذف متد _buildLegendItem چون با _buildLegendChip جایگزین شد

  /// نمایش گراف
  Widget _buildGraphView() {
    if (graph == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
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

    return Stack(
      children: [
        // گراف تعاملی
        InteractiveGraphView(
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

        // نمایش توضیحات مرحله (پایین صفحه)
        if (stepDescription != null)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Center(
              child: GlassContainer(
                color: Colors.black.withOpacity(0.5),
                blur: 10,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Text(
                  stepDescription,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

        // نمایش وضعیت (بالای صفحه)
        Positioned(
          top: 50,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isConfigOpen
                  ? 0.0
                  : 1.0, // وقتی تنظیمات باز است مخفی شود
              child: GlassContainer(
                color: const Color(0xFF151628).withOpacity(0.4),
                blur: 5,
                borderRadius: BorderRadius.circular(30),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Text(
                  _getStatusText(),
                  style: const TextStyle(
                    color: Color(0xFF00F0FF),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),

        // دکمه اجرا (شناور در پایین صفحه)
        if (!isAnimating && searchResult == null)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isConfigOpen ? 0.0 : 1.0,
                child: Container(
                  height: 60,
                  width: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: (selectedStart != null && selectedGoal != null)
                            ? const Color(0xFF00FF9D).withOpacity(0.4)
                            : Colors.transparent,
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: (selectedStart == null || selectedGoal == null)
                        ? null
                        : _runSearch,
                    icon: const Icon(Icons.play_arrow, size: 28),
                    label: const Text(
                      'شروع جستجو',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF9D),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ),
          ),

        // دکمه ریست (وقتی نتیجه نمایش داده می‌شود)
        if (searchResult != null && !isAnimating)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isConfigOpen ? 0.0 : 1.0,
                child: Container(
                  height: 50,
                  width: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF0055).withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      'جستجوی مجدد',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF0055),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
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
