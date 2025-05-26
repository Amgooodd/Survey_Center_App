import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SurveyHistoryPage extends StatefulWidget {
  final String studentId;
  const SurveyHistoryPage({super.key, required this.studentId});

  @override
  _SurveyHistoryPageState createState() => _SurveyHistoryPageState();
}

class _SurveyHistoryPageState extends State<SurveyHistoryPage> {
  String? _editingResponseId;
  final Map<String, dynamic> _editedAnswers = {};
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, bool> _isExpanded = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<String> _existingSurveyIds = [];

  @override
  void initState() {
    super.initState();
    _fetchExistingSurveyIds();
  }

  @override
  void dispose() {
    _textControllers.forEach((key, controller) => controller.dispose());
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchExistingSurveyIds() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('surveys').get();
    setState(() {
      _existingSurveyIds = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Responses history", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 28, 51, 95),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search surveys...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('students_responses')
                  .where('studentId', isEqualTo: widget.studentId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("An error occurred: ${snapshot.error}"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No survey responses found."));
                }

                final filteredResponses = snapshot.data!.docs.where((response) {
                  return _existingSurveyIds.contains(response['surveyId']);
                }).toList();

                return ListView.builder(
                  itemCount: filteredResponses.length,
                  itemBuilder: (context, index) {
                    var response = filteredResponses[index];
                    final responseId = response.id;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('surveys')
                          .doc(response['surveyId'])
                          .get(),
                      builder: (context, surveySnapshot) {
                        if (surveySnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Card(
                            child: ListTile(
                              title: Text("Loading survey..."),
                            ),
                          );
                        }

                        if (surveySnapshot.hasError) {
                          return Card(
                            child: ListTile(
                              title: Text(
                                  "Error loading survey: ${surveySnapshot.error}"),
                            ),
                          );
                        }

                        if (!surveySnapshot.hasData || !surveySnapshot.data!.exists) {
                          return SizedBox.shrink();
                        }

                        var survey = surveySnapshot.data!;
                        final questions = survey['questions'] as List<dynamic>? ?? [];
                        final answers =
                            response['answers'] as Map<String, dynamic>? ?? {};
                        
                        
                        final surveyName = survey['name']?.toString().toLowerCase() ?? '';
                        if (_searchQuery.isNotEmpty && !surveyName.contains(_searchQuery)) {
                          return SizedBox.shrink();
                        }

                        return Card(
                          margin: const EdgeInsets.all(10),
                          color: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 5,
                                  spreadRadius: 2,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                            child: StatefulBuilder(
                              builder: (context, setInnerState) {
                                return ExpansionTile(
                                  title: Text(
                                    survey['name'] ?? "Unnamed Survey",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: const Color.fromARGB(255, 28, 51, 95),
                                    ),
                                  ),
                                  initiallyExpanded: _isExpanded[responseId] ?? false,
                                  onExpansionChanged: (bool expanded) {
                                    setInnerState(() {
                                      _isExpanded[responseId] = expanded;
                                    });
                                  },
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Your Answers:",
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold)),
                                          SizedBox(height: 10),
                                          ...questions.map<Widget>((question) {
                                            final answer =
                                                answers[question['title']] ?? "";

                                            if (_editingResponseId == responseId) {
                                              if (question['type'] ==
                                                  'multiple_choice') {
                                                _editedAnswers[question['title']] =
                                                    answer;
                                              } else {
                                                final controllerKey =
                                                    '${responseId}${question['title']}';
                                                if (!_textControllers
                                                    .containsKey(controllerKey)) {
                                                  _textControllers[controllerKey] =
                                                      TextEditingController(
                                                          text: answer);
                                                }
                                              }
                                            }

                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    question['title'] ??
                                                        "Untitled Question",
                                                    style: TextStyle(
                                                        fontWeight: FontWeight.bold)),
                                                SizedBox(height: 5),
                                                _editingResponseId == responseId
                                                    ? _buildEditableAnswer(
                                                        question, answer)
                                                    : Text(answer.toString()),
                                                SizedBox(height: 10),
                                              ],
                                            );
                                          }).toList(),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        studentId: widget.studentId,
        hist: true,
      ),
    );
  }

  Widget _buildEditableAnswer(
      Map<String, dynamic> question, dynamic currentAnswer) {
    if (question['type'] == 'multiple_choice') {
      if (_editingResponseId != null &&
          !_editedAnswers.containsKey(question['title'])) {
        _editedAnswers[question['title']] = currentAnswer;
      }

      return StatefulBuilder(
        builder: (context, setInnerState) {
          return Column(
            children: question['options']?.map<Widget>((option) {
                  return RadioListTile(
                    title: Text(option),
                    value: option,
                    groupValue: _editedAnswers[question['title']],
                    onChanged: (value) {
                      setInnerState(() {
                        _editedAnswers[question['title']] = value;
                      });
                    },
                    activeColor: Colors.blue,
                  );
                }).toList() ??
                [],
          );
        },
      );
    } else {
      final controllerKey = '${_editingResponseId}${question['title']}';
      return TextField(
        controller: _textControllers[controllerKey],
        decoration: InputDecoration(
          border: OutlineInputBorder(),
        ),
      );
    }
  }
}

class BottomNavigationBarWidget extends StatelessWidget {
  final String studentId;

  final bool homee;
  final bool hist;

  const BottomNavigationBarWidget({
    super.key,
    required this.studentId,
    this.homee = false,
    this.hist = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 28, 51, 95),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          BottomNavItem(
            icon: Icons.home,
            label: "Home",
            isSelected: homee,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          BottomNavItem(
            icon: Icons.history,
            label: "Survey History",
            isSelected: hist,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SurveyHistoryPage(
                    studentId: studentId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  const BottomNavItem({
    super.key,
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: isSelected ? Colors.white : Colors.blueGrey, size: 24),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? Colors.white : Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }
}
