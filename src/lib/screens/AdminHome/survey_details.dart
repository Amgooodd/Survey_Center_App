import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:student_questionnaire/Features/download_excel.dart';
import 'package:student_questionnaire/screens/AdminHome/answer_view_page.dart';
import 'surveys_analytics.dart';

class SurveyDetailsScreen extends StatefulWidget {
  final DocumentSnapshot survey;
  const SurveyDetailsScreen({super.key, required this.survey});

  @override
  _SurveyDetailsScreenState createState() => _SurveyDetailsScreenState();
}

class _SurveyDetailsScreenState extends State<SurveyDetailsScreen> {
  Future<void> _deleteSurvey() async {
    try {
      final surveyDoc = await FirebaseFirestore.instance
          .collection('surveys')
          .doc(widget.survey.id)
          .get();

      if (surveyDoc.exists) {
        await FirebaseFirestore.instance
            .collection('backup')
            .doc(widget.survey.id)
            .set({
          ...?surveyDoc.data(),
          'backupTimestamp': FieldValue.serverTimestamp(),
        });
      }

      await FirebaseFirestore.instance
          .collection('surveys')
          .doc(widget.survey.id)
          .delete();

      final notificationQuery = await FirebaseFirestore.instance
          .collection('notifications')
          .where('surveyId', isEqualTo: widget.survey.id)
          .get();
      for (var doc in notificationQuery.docs) {
        await doc.reference.delete();
      }

      final responsesQuery = await FirebaseFirestore.instance
          .collection('students_responses')
          .where('surveyId', isEqualTo: widget.survey.id)
          .get();
      for (var doc in responsesQuery.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Survey deleted successfully")),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/firsrforadminn',
        (route) => false,
      );
    } catch (e) {
      print("Error deleting survey: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete survey: $e")),
      );
    }
  }

  bool _forceExpired = false;
  Future<void> _endSurvey() async {
    setState(() {
      _forceExpired = true;
    });
    await FirebaseFirestore.instance
        .collection('surveys')
        .doc(widget.survey.id)
        .update({
      'deadline': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Survey has been ended and marked as expired.")),
    );
  }

  Future<void> _resetSurvey() async {
    setState(() {
      _forceExpired = false;
    });
    await FirebaseFirestore.instance
        .collection('surveys')
        .doc(widget.survey.id)
        .update({
      'deadline': null,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Survey has been reset and is now active.")),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this survey?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.popUntil(
                  context,
                  (route) => route.settings.name == '/firsrforadminn',
                );
                await _deleteSurvey();
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditQuestionDialog(Map<String, dynamic> question) async {
    TextEditingController questionController =
        TextEditingController(text: question['title']);
    List<TextEditingController> optionControllers = [];
    if (question['type'] == 'multiple_choice') {
      optionControllers = List.from(question['options'] ?? [])
          .map((option) => TextEditingController(text: option))
          .toList();
    }
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Edit Question'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: questionController,
                    decoration:
                        const InputDecoration(labelText: 'Question Text'),
                  ),
                  const SizedBox(height: 10),
                  if (question['type'] == 'multiple_choice') ...[
                    ...optionControllers.asMap().entries.map((entry) {
                      int index = entry.key;
                      return Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: entry.value,
                              decoration: InputDecoration(
                                  labelText: 'Option ${index + 1}'),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setStateDialog(() {
                                optionControllers.removeAt(index);
                              });
                            },
                          ),
                        ],
                      );
                    }),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setStateDialog(() {
                              optionControllers
                                  .add(TextEditingController(text: ''));
                            });
                          },
                        ),
                        const Text('Add Option'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  List<String> updatedOptions = optionControllers
                      .map((controller) => controller.text.trim())
                      .where((text) => text.isNotEmpty)
                      .toList();
                  final updatedQuestion = {
                    'title': questionController.text.trim(),
                    'type': question['type'],
                    'options': updatedOptions,
                  };
                  await FirebaseFirestore.instance
                      .collection('surveys')
                      .doc(widget.survey.id)
                      .update({
                    'questions': FieldValue.arrayRemove([question]),
                  });
                  await FirebaseFirestore.instance
                      .collection('surveys')
                      .doc(widget.survey.id)
                      .update({
                    'questions': FieldValue.arrayUnion([updatedQuestion]),
                  });
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteQuestion(Map<String, dynamic> question) async {
    await FirebaseFirestore.instance
        .collection('surveys')
        .doc(widget.survey.id)
        .update({
      'questions': FieldValue.arrayRemove([question]),
    });
  }

  Future<void> _showAddQuestionDialog(String type) async {
    TextEditingController questionController = TextEditingController();
    List<TextEditingController> optionControllers = [];
    if (type == 'multiple_choice') {
      optionControllers =
          List.generate(3, (index) => TextEditingController(text: ''));
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(
                'Add ${type == 'multiple_choice' ? 'Multiple Choice' : 'Feedback'} Question'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: questionController,
                    decoration:
                        const InputDecoration(labelText: 'Question Text'),
                  ),
                  if (type == 'multiple_choice') ...[
                    const SizedBox(height: 10),
                    ...optionControllers.asMap().entries.map((entry) {
                      int index = entry.key;
                      return Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: entry.value,
                              decoration: InputDecoration(
                                  labelText: 'Option ${index + 1}'),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setStateDialog(() {
                                optionControllers.removeAt(index);
                              });
                            },
                          ),
                        ],
                      );
                    }),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setStateDialog(() {
                              optionControllers
                                  .add(TextEditingController(text: ''));
                            });
                          },
                        ),
                        const Text('Add Option'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final questionText = questionController.text.trim();
                  if (questionText.isEmpty) return;
                  List<String> options = [];
                  if (type == 'multiple_choice') {
                    options = optionControllers
                        .map((controller) => controller.text.trim())
                        .where((text) => text.isNotEmpty)
                        .toList();
                    if (options.isEmpty) return;
                  }
                  final newQuestion = {
                    'title': questionText,
                    'type': type,
                    if (type == 'multiple_choice') 'options': options,
                  };
                  await FirebaseFirestore.instance
                      .collection('surveys')
                      .doc(widget.survey.id)
                      .update({
                    'questions': FieldValue.arrayUnion([newQuestion]),
                  });
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddQuestionTypeDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.list),
                title: const Text('Multiple Choice'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddQuestionDialog('multiple_choice');
                },
              ),
              ListTile(
                leading: const Icon(Icons.feedback),
                title: const Text('Feedback'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddQuestionDialog('feedback');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('surveys')
          .doc(widget.survey.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Survey Details')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final document = snapshot.data!;
        if (!document.exists || document.data() == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Survey Details')),
            body: const Center(child: Text('This survey has been deleted')),
          );
        }

        final data = document.data()! as Map<String, dynamic>;
        final questions = data['questions'] ?? [];
        final departments =
            (data['departments'] as List?)?.join(', ') ?? 'Unknown Departments';
        final timestamp = data['timestamp'] as Timestamp?;
        final formattedTime = timestamp != null
            ? '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}'
            : 'N/A';
        final deadline = data['deadline'] as Timestamp?;
        final formattedDeadline = deadline != null
            ? DateFormat('yyyy-MM-dd HH:mm').format(deadline.toDate())
            : 'No deadline';

        final bool isActuallyExpired =
            deadline != null && deadline.toDate().isBefore(DateTime.now());
        final bool showAsExpired = _forceExpired || isActuallyExpired;

        return Scaffold(
          appBar: AppBar(
            title: Text(data['name'] ?? 'Unnamed Survey',
                style: const TextStyle(color: Colors.white)),
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
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.settings, color: Colors.white),
                onSelected: (value) async {
                  switch (value) {
                    case 'download':
                      await SurveyExporter()
                          .exportSurveyResponses(widget.survey.id);
                      break;
                    case 'end':
                      await _endSurvey();
                      break;
                    case 'reset':
                      await _resetSurvey();
                      break;
                    case 'delete':
                      _showDeleteConfirmation();
                      break;
                    case 'analytics':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SurveyAnalysisPage(surveyId: widget.survey.id),
                        ),
                      );
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'download',
                    child: Row(
                      children: [
                        Icon(Icons.download, color: Colors.green),
                        SizedBox(width: 10),
                        Text('Download responses'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'end',
                    child: Row(
                      children: [
                        Icon(Icons.stop_circle, color: Colors.orange),
                        SizedBox(width: 10),
                        Text('End Survey'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'reset',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, color: Colors.blue),
                        SizedBox(width: 10),
                        Text('Reset Survey'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 10),
                        Text('Delete Survey'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Departments: $departments',
                    style: const TextStyle(fontSize: 15)),
                Text('Created At: $formattedTime',
                    style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      'Deadline: $formattedDeadline',
                      style: TextStyle(
                        fontSize: 15,
                        color: showAsExpired
                            ? Colors.red
                            : (deadline != null ? Colors.green : Colors.grey),
                      ),
                    ),
                    if (showAsExpired)
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Text(
                          '(Expired)',
                          style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const Text('Questions:',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final question = questions[index];
                      return Card(
                        child: ListTile(
                          title: Text(question['title'] ?? 'No Question Text'),
                          subtitle: question['type'] == 'multiple_choice'
                              ? Text(
                                  'Options: ${question['options'].join(', ')}')
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    _showEditQuestionDialog(question),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteQuestion(question),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AnswerViewPage(surveyId: widget.survey.id),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.list_alt, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'View Answers',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SurveyAnalysisPage(surveyId: widget.survey.id),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 253, 200, 0),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.analytics, color: Colors.black),
                          SizedBox(width: 10),
                          Text(
                            'Analytics',
                            style: TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color.fromARGB(255, 28, 51, 95),
            onPressed: _showAddQuestionTypeDialog,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}
