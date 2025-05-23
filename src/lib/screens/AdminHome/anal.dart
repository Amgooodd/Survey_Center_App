import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/Bottom_bar.dart';

class DataPage extends StatefulWidget {
  const DataPage({super.key});
  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> with WidgetsBindingObserver {
  Map<String, int> departmentCounts = {};
  int totalStudents = 0;
  int totalSurveys = 0;
  bool isLoading = true;
  String? errorMessage;
  List<MapEntry<String, int>> sortedDepartments = [];

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

      if (studentsSnapshot.docs.isNotEmpty) {
        for (var doc in studentsSnapshot.docs) {
          final data = doc.data();
          final department = data['group'] ?? 'Unknown';
          departmentCounts[department] =
              (departmentCounts[department] ?? 0) + 1;
          totalStudents++;
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

  Widget buildInfoCard(String title, int count, IconData icon, Color color) {
    return Card(
      color: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$count",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];

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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 150,
                child: buildInfoCard(
                  "NUMBER OFF STUDENTS",
                  totalStudents,
                  Icons.people,
                  const Color.fromARGB(255, 28, 51, 95),
                ),
              ),
              SizedBox(width: 12),
              SizedBox(
                width: 150,
                child: buildInfoCard(
                  "NUMBER OF SURVEYS",
                  totalSurveys,
                  Icons.assignment,
                  Colors.deepPurple,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 150,
                child: buildInfoCard(
                  "NUMBER OF DEPARTMENTS",
                  departmentCounts.length,
                  Icons.school,
                  Colors.blue,
                ),
              ),
              const SizedBox(height: 20),
              Divider(),
              const SizedBox(height: 10),
              Text(
                " DEPARTMENT ANALYSIS",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Divider(),
              const SizedBox(height: 10),
              if (sortedDepartments.isNotEmpty) ...[
                const Text(
                  "PIE CHART",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  height: 270,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      sections: sortedDepartments.map((entry) {
                        final index =
                            sortedDepartments.indexOf(entry) % colors.length;
                        final percentage = (entry.value / totalStudents) * 100;
                        return PieChartSectionData(
                          value: entry.value.toDouble(),
                          title:
                              "${entry.key}\n${percentage.toStringAsFixed(1)}%",
                          color: colors[index],
                          radius: 70,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          titlePositionPercentageOffset: 0.6,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Divider(),
                const SizedBox(height: 10),
                const Text(
                  "BAR CHART",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Container(
                  height: 250,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                        final index = entry.key;
                        final dept = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: dept.value.toDouble(),
                              color: colors[index % colors.length],
                              width: 16,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value < 0 ||
                                  value >= sortedDepartments.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  sortedDepartments[value.toInt()].key.length >
                                          5
                                      ? sortedDepartments[value.toInt()]
                                              .key
                                              .substring(0, 5) +
                                          '...'
                                      : sortedDepartments[value.toInt()].key,
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                            reservedSize: 30,
                          ),
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
                        drawVerticalLine: true,
                        drawHorizontalLine: true,
                        horizontalInterval: 2,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.black,
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: Colors.black,
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          );
                        },
                        checkToShowHorizontalLine: (value) => value % 2 == 0,
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.black,
                            width: 1,
                          ),
                          left: BorderSide(
                            color: Colors.black,
                            width: 1,
                          ),
                        ),
                      ),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 100),
                Icon(Icons.bar_chart, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  "No department data available",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavigationBarWidget(anall: true),
      /*floatingActionButton: FloatingActionButton(
        onPressed: fetchData,
        backgroundColor: const Color.fromARGB(255, 28, 51, 95),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),*/
    );
  }
}
