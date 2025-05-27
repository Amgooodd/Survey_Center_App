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
  Map<String, List<String>> questionOptions = {};
  List<String> originalQuestionOrder = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchSurveyAnswers();
  }

  Future<void> fetchSurveyAnswers() async {
    try {
      
      final surveyDoc = await FirebaseFirestore.instance
          .collection('surveys')
          .doc(widget.surveyId)
          .get();
      
      if (surveyDoc.exists) {
        final questions = surveyDoc.data()?['questions'] as List<dynamic>?;
        if (questions != null) {
          
          originalQuestionOrder = questions.map((q) => q['title'] as String).toList();
          
          for (var question in questions) {
            if (question['options'] != null) {
              questionOptions[question['title']] = 
                List<String>.from(question['options'] as List<dynamic>);
            }
          }
        }
      }

      
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

      
      filteredQuestionAnswerCounts = {};
      for (String question in originalQuestionOrder) {
        if (questionAnswerCounts.containsKey(question) && questionOptions.containsKey(question)) {
          filteredQuestionAnswerCounts[question] = questionAnswerCounts[question]!;
        }
      }

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

  Color getColorForOption(String question, String option) {
    final options = questionOptions[question] ?? [];
    final index = options.indexOf(option);
    final totalOptions = options.length;

    final List<Color> allColors = [
      const Color(0xFF006400),              
      Colors.green,                         
      Colors.orange,                        
      Colors.red,                           
      const Color.fromARGB(255, 165, 0, 0), 
      Colors.purple,                        
      Colors.blue,
      Colors.teal,
      Colors.brown,
      const Color.fromARGB(255, 255, 128, 0),  
      Colors.indigo,
      Colors.pink,
      const Color.fromARGB(255, 128, 0, 128),  
      Colors.cyan,
      const Color.fromARGB(255, 0, 128, 128),  
    ];

    if (totalOptions == 3) {
      
      final threeOptionsColors = [
        Colors.green,
        Colors.orange,
        Colors.red,
      ];
      return index >= 0 && index < threeOptionsColors.length ? threeOptionsColors[index] : Colors.grey;
    } else {
      
      return index >= 0 && index < allColors.length ? allColors[index] : Colors.grey;
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

  Widget buildTable(Map<String, int> answers) {
    final total = answers.values.fold(0, (a, b) => a + b);
    return DataTable(
      columns: const [
        DataColumn(
            label:
                Text("Answer", style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text("Frequency")),
        DataColumn(label: Text("Percentage")),
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
                  ...originalQuestionOrder.where((question) => 
                    filteredQuestionAnswerCounts.containsKey(question)
                  ).map((question) {
                    return buildChartsAndTableForQuestion(
                        question, filteredQuestionAnswerCounts[question]!);
                  }).toList(),
                ],
              ),
            ),
    );
  }

  Widget buildChartsAndTableForQuestion(String question, Map<String, int> answers) {
    final total = answers.values.fold(0, (a, b) => a + b);
    
    
    final sortedAnswers = Map.fromEntries(
      questionOptions[question]?.where((option) => answers.containsKey(option))
          .map((option) => MapEntry(option, answers[option] ?? 0)) ??
      answers.entries
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 253, 200, 0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color.fromARGB(255, 253, 200, 0), width: 1),
          ),
          child: Text(
            question,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 28, 51, 95),
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
                    sections: sortedAnswers.entries.map((entry) {
                      final value = entry.value;
                      final percentage = (value / total) * 100;
                      return PieChartSectionData(
                        value: value.toDouble(),
                        color: getColorForOption(question, entry.key),
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
                    barGroups: sortedAnswers.entries.toList().asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: item.value.toDouble(),
                            width: 16,
                            color: getColorForOption(question, item.key),
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
                            if (index < sortedAnswers.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  sortedAnswers.keys.elementAt(index),
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
        buildTable(sortedAnswers),
        const Divider(thickness: 2, height: 40),
      ],
    );
  }
}
