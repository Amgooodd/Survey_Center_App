import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'dart:math';

class SurveyAnalysisPage extends StatefulWidget {
  final String surveyId;

  const SurveyAnalysisPage({super.key, required this.surveyId});

  @override
  State<SurveyAnalysisPage> createState() => _SurveyAnalysisPageState();
}

class _SurveyAnalysisPageState extends State<SurveyAnalysisPage> {
  Map<String, Map<String, int>> questionAnswerCounts = {};
  Map<String, Map<String, int>> filteredQuestionAnswerCounts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchSurveyAnswers();
  }

  Future<void> fetchSurveyAnswers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('students_responses')
          .where('surveyId', isEqualTo: widget.surveyId)
          .get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final answers = Map<String, dynamic>.from(data['answers'] ?? {});
        answers.forEach((question, answer) {
          questionAnswerCounts.putIfAbsent(question, () => {});
          questionAnswerCounts[question]![answer] =
              (questionAnswerCounts[question]![answer] ?? 0) + 1;
        });
      }

      // Filter questions with more than 3 unique answers
      filteredQuestionAnswerCounts = Map.from(questionAnswerCounts)
        ..removeWhere((question, answers) => answers.length > 3);

      setState(() {
        _loading = false;
      });
    } catch (e) {
      print("Error fetching survey answers: $e");
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> exportToExcel() async {
    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];
    int rowIndex = 1;
    filteredQuestionAnswerCounts.forEach((question, answers) {
      sheet.getRangeByIndex(rowIndex, 1).setText(question);
      rowIndex++;
      sheet.getRangeByIndex(rowIndex, 1).setText("الإجابة");
      sheet.getRangeByIndex(rowIndex, 2).setText("عدد الطلاب");
      sheet.getRangeByIndex(rowIndex, 3).setText("النسبة %");
      rowIndex++;
      final total = answers.values.fold(0, (a, b) => a + b);
      for (var entry in answers.entries) {
        final percent = (entry.value / total) * 100;
        sheet.getRangeByIndex(rowIndex, 1).setText(entry.key);
        sheet.getRangeByIndex(rowIndex, 2).setNumber(entry.value.toDouble());
        sheet
            .getRangeByIndex(rowIndex, 3)
            .setText("${percent.toStringAsFixed(1)}%");
        rowIndex++;
      }
      rowIndex++;
    });
  }

  Widget buildChartsForQuestion(String question, Map<String, int> answers) {
    final total = answers.values.fold(0, (a, b) => a + b);
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
      Colors.brown,
      Colors.lime,
      Colors.deepOrange,
      Colors.lightBlue,
      Colors.lightGreen,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.teal, width: 1),
          ),
          child: Text(
            question,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 180,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    sections:
                        answers.entries.toList().asMap().entries.map((entry) {
                      final index = entry.key;
                      final value = entry.value;
                      final percentage = (value.value / total) * 100;
                      return PieChartSectionData(
                        value: value.value.toDouble(),
                        color: colors[index],
                        title: "${percentage.toStringAsFixed(1)}%",
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                    pieTouchData: PieTouchData(enabled: true),
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 800),
                  swapAnimationCurve: Curves.easeInOut,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (answers.values.reduce(max)).toDouble() + 2,
                    barGroups:
                        answers.entries.toList().asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: item.value.toDouble(),
                            width: 16,
                            color: colors[index],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }).toList(),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            int index = value.toInt();
                            if (index < answers.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  answers.keys.elementAt(index),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        buildTable(answers),
        const Divider(thickness: 2, height: 40),
      ],
    );
  }

  Widget buildTable(Map<String, int> answers) {
    final total = answers.values.fold(0, (a, b) => a + b);
    return DataTable(
      columns: const [
        DataColumn(
            label:
                Text("Answer", style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text("Frequency")),
        DataColumn(label: Text("Percentage %")),
      ],
      rows: answers.entries.map((entry) {
        final percentage = (entry.value / total) * 100;
        return DataRow(cells: [
          DataCell(Text(entry.key)),
          DataCell(Text(entry.value.toString())),
          DataCell(Text("${percentage.toStringAsFixed(1)}%")),
        ]);
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Students answers', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 28, 51, 95),
        /*actions: [
          IconButton(
            icon: const Icon(
              Icons.table_chart,
              color: Colors.white,
            ),
            tooltip: 'تصدير Excel',
            onPressed: _loading ? null : exportToExcel,
          ),
        ],*/
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (filteredQuestionAnswerCounts.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          "No answers for this survey found yet please wait for the responses <3",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ...filteredQuestionAnswerCounts.entries.map((entry) {
                    return buildChartsAndTableForQuestion(
                        entry.key, entry.value);
                  }).toList(),
                ],
              ),
            ),
    );
  }

  Widget buildChartsAndTableForQuestion(
      String question, Map<String, int> answers) {
    final total = answers.values.fold(0, (a, b) => a + b);
    final List<Color> colors = [
      Colors.green,
      Colors.red,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
      Colors.brown,
      Colors.lime,
      Colors.deepOrange,
      Colors.lightBlue,
      Colors.lightGreen,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 253, 200, 0),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: Color.fromARGB(255, 253, 200, 0), width: 1),
          ),
          child: Text(
            question,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 28, 51, 95),
            ),
          ),
        ),
        SizedBox(height: 30),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 180,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 20,
                    sections:
                        answers.entries.toList().asMap().entries.map((entry) {
                      final index = entry.key;
                      final value = entry.value;
                      final percentage = (value.value / total) * 100;
                      return PieChartSectionData(
                        value: value.value.toDouble(),
                        color: colors[index],
                        title: "${percentage.toStringAsFixed(1)}%",
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                    pieTouchData: PieTouchData(enabled: true),
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 800),
                  swapAnimationCurve: Curves.easeInOut,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (answers.values.reduce(max)).toDouble() + 2,
                    barGroups:
                        answers.entries.toList().asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: item.value.toDouble(),
                            width: 16,
                            color: colors[index],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }).toList(),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            int index = value.toInt();
                            if (index < answers.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  answers.keys.elementAt(index),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        buildTable(answers),
        const Divider(thickness: 2, height: 40),
      ],
    );
  }
}
