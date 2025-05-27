import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/Bottom_bar.dart';
import 'dart:math' as math;

class DataPage extends StatefulWidget {
  const DataPage({super.key});
  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> with WidgetsBindingObserver {
  Map<String, int> departmentCounts = {};
  Map<String, Color> departmentColors = {};
  int totalStudents = 0;
  int totalSurveys = 0;
  bool isLoading = true;
  String? errorMessage;
  List<MapEntry<String, int>> sortedDepartments = [];
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  
  final List<Color> baseColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.cyan,
    Colors.amber,
    Colors.deepOrange,
    Colors.lightBlue,
    Colors.deepPurple,
    Colors.lime,
    Colors.brown,
    Colors.blueGrey,
    Colors.lightGreen,
    Colors.yellow,
    Colors.indigoAccent,
    Colors.deepOrangeAccent,
    Colors.lightBlueAccent,
    Colors.pinkAccent,
    Colors.purpleAccent,
    Colors.tealAccent,
    Colors.cyanAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.amberAccent,
    Colors.limeAccent,
    Colors.redAccent,
    Colors.blueAccent,
    Colors.deepPurpleAccent,
  ];

  Color generateDistinctColor() {
    if (departmentColors.length < baseColors.length) {
      
      return baseColors[departmentColors.length];
    }

    
    double goldenRatio = 0.618033988749895;
    double hue = departmentColors.length * goldenRatio;
    hue = hue - hue.floor();  

    
    return HSVColor.fromAHSV(
      1.0,  
      hue * 360,  
      0.85,  
      0.9,  
    ).toColor();
  }

  double calculateColorDistance(Color c1, Color c2) {
    int rmean = ((c1.red + c2.red) ~/ 2);
    int r = c1.red - c2.red;
    int g = c1.green - c2.green;
    int b = c1.blue - c2.blue;
    return math.sqrt((((512 + rmean) * r * r) >> 8) + 4 * g * g + (((767 - rmean) * b * b) >> 8));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.delayed(Duration.zero, () {
      if (mounted) fetchData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      fetchData();
    }
  }

  Future<void> fetchData() async {
    if (!mounted) return;

    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final surveysSnapshot = await FirebaseFirestore.instance
          .collection('surveys')
          .get()
          .timeout(const Duration(seconds: 30));

      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .get()
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;

      totalSurveys = surveysSnapshot.size;
      departmentCounts = {};
      totalStudents = 0;

      
      departmentColors.clear();

      if (studentsSnapshot.docs.isNotEmpty) {
        for (var doc in studentsSnapshot.docs) {
          final data = doc.data();
          final department = data['group'] ?? 'Unknown';
          departmentCounts[department] = (departmentCounts[department] ?? 0) + 1;
          totalStudents++;
        }

        
        for (String department in departmentCounts.keys) {
          if (!departmentColors.containsKey(department)) {
            departmentColors[department] = generateDistinctColor();
          }
        }
      }

      sortedDepartments = departmentCounts.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error in fetchData: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = "Error loading data";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Students Analytics',
              style: TextStyle(color: Colors.white)),
          backgroundColor: const Color.fromARGB(255, 28, 51, 95),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.popUntil(
                context,
                (route) => route.settings.name == '/firsrforadminn',
              );
            },
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
        bottomNavigationBar: const BottomNavigationBarWidget(anall: true),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Students Analytics',
              style: TextStyle(color: Colors.white)),
          backgroundColor: const Color.fromARGB(255, 28, 51, 95),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.popUntil(
                context,
                (route) => route.settings.name == '/firsrforadminn',
              );
            },
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(errorMessage!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: fetchData,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const BottomNavigationBarWidget(anall: true),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students Analytics',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 28, 51, 95),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.popUntil(
              context,
              (route) => route.settings.name == '/firsrforadminn',
            );
          },
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () async {
          await fetchData();
        },
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EAF6),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1A237E),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.people,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'NUMBER OFF STUDENTS',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                            Text(
                              totalStudents.toString(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFF4A148C),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.assignment,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'NUMBER OF SURVEYS',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A148C),
                              ),
                            ),
                            Text(
                              totalSurveys.toString(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A148C),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F5FE),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0288D1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.school,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'NUMBER OF DEPARTMENTS',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0288D1),
                              ),
                            ),
                            Text(
                              departmentCounts.length.toString(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0288D1),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        color: const Color(0xFF1A237E).withOpacity(0.2),
                      ),
                      const Text(
                        'DEPARTMENT ANALYSIS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        color: const Color(0xFF1A237E).withOpacity(0.2),
                      ),
                    ],
                  ),
                ),

                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text(
                    'PIE CHART',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 40),

                if (sortedDepartments.isNotEmpty) ...[
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 40,
                        startDegreeOffset: 180,
                        sections: sortedDepartments.map((entry) {
                          final percentage = (entry.value / totalStudents) * 100;
                          return PieChartSectionData(
                            value: entry.value.toDouble(),
                            title: '${percentage.toStringAsFixed(1)}%',
                            color: departmentColors[entry.key] ?? Colors.grey,
                            radius: 100,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            showTitle: true,
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: sortedDepartments.length,
                      itemBuilder: (context, index) {
                        final entry = sortedDepartments[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: departmentColors[entry.key] ?? Colors.grey,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${entry.value}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: departmentColors[entry.key] ?? Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "STUDENTS PER DEPARTMENT",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  Container(
                    height: 250,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: sortedDepartments.isEmpty
                            ? 10
                            : (sortedDepartments
                                    .map((e) => e.value)
                                    .reduce((a, b) => a > b ? a : b) *
                                1.2),
                        barGroups: sortedDepartments.asMap().entries.map((entry) {
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value.value.toDouble(),
                                color: departmentColors[entry.value.key] ?? Colors.grey,
                                width: 16,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4)),
                              ),
                            ],
                          );
                        }).toList(),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) return const SizedBox.shrink();
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          drawHorizontalLine: true,
                          horizontalInterval: 2,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.black12,
                              strokeWidth: 1,
                              dashArray: [5, 5],
                            );
                          },
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: const Border(
                            bottom: BorderSide(
                              color: Colors.black26,
                              width: 1,
                            ),
                            left: BorderSide(
                              color: Colors.black26,
                              width: 1,
                            ),
                          ),
                        ),
                        barTouchData: BarTouchData(
                          enabled: true,
                          handleBuiltInTouches: true,
                          touchTooltipData: BarTouchTooltipData(
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${sortedDepartments[groupIndex].key}\n${rod.toY.toInt()} students',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                          touchCallback: (FlTouchEvent event, BarTouchResponse? touchResponse) {
                            if (touchResponse == null || touchResponse.spot == null) {
                              return;
                            }
                            if (event is FlTapUpEvent) {
                              final int index = touchResponse.spot!.touchedBarGroupIndex;
                              if (index >= 0 && index < sortedDepartments.length) {
                                final entry = sortedDepartments[index];
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            entry.key,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${entry.value} students',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: departmentColors[entry.key],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavigationBarWidget(anall: true),
    );
  }
}
