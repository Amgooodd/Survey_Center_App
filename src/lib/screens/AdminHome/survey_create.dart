import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../widgets/Bottom_bar.dart';

class CreateSurvey extends StatefulWidget {
  const CreateSurvey({super.key});
  @override
  _CreateSurveyState createState() => _CreateSurveyState();
}

class _CreateSurveyState extends State<CreateSurvey> {
  final TextEditingController _surveyNameController = TextEditingController();
  List<Map<String, dynamic>> _questions = [];
  bool _isSubmitting = false;

  final List<String> _departments = [
    'All',
    'Stat',
    'Math',
    'CS',
    'Chemistry',
    'biology',
    'PHY'
  ];
  List<String> _selectedDepartments = [];
  bool _allowMultipleSubmissions = false;
  DateTime? _deadline;
  bool _requireExactGroupCombination = false;
  bool _showOnlySelectedDepartments = false;

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp().then((_) {}).catchError((error) {
      print("Firebase initialization error: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Firebase initialization failed. Please check your configuration.")),
      );
    });
  }

  void _addQuestion(bool istextfield) {
    setState(() {
      final questionNumber = _questions.length + 1;
      if (istextfield) {
        _questions.add({
          'title': 'textfield $questionNumber',
          'type': 'textfield',
        });
      } else {
        _questions.add({
          'title': 'Question $questionNumber',
          'type': 'multiple_choice',
          'options': ['موافق تماماً', 'موافق', 'إلى حد ما', 'غير موافق', 'غير موافق تماماً'],
        });
      }
    });
  }

  Future<void> _addSurveyToDatabase(
      String surveyName, List<Map<String, dynamic>> questions) async {
    try {
      if (_selectedDepartments.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please select at least one department.")),
        );
        return;
      }

      String currentUserId =
          FirebaseAuth.instance.currentUser?.uid ?? "unknown";

      final surveyRef =
          await FirebaseFirestore.instance.collection('surveys').add({
        'name': surveyName,
        'questions': questions
            .map((q) => q['type'] == 'multiple_choice'
                ? {
                    'title': q['title'],
                    'options': q['options'],
                    'type': q['type'],
                  }
                : {
                    'title': q['title'],
                    'type': q['type'],
                  })
            .toList(),
        'timestamp': FieldValue.serverTimestamp(),
        'departments':
            _selectedDepartments.map((d) => d.toUpperCase()).toList(),
        'allow_multiple_submissions': _allowMultipleSubmissions,
        'deadline': _deadline,
        'require_exact_group_combination': _requireExactGroupCombination,
        'show_only_selected_departments': _showOnlySelectedDepartments,
        'madyby': currentUserId,
      });
      await _createNotificationsForSurvey(
          surveyRef.id, surveyName, _selectedDepartments);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Survey added successfully!")),
      );
    } catch (e) {
      print("Error adding survey: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add survey. Please try again.")),
      );
    }
  }

  Future<void> _createNotificationsForSurvey(
      String surveyId, String surveyName, List<String> departments) async {
    try {
      List<String> surveyDeptsUpper = departments
          .map((d) => d.toUpperCase())
          .where((d) => d != 'ALL')
          .toList()
        ..sort();

      final studentsQuery = FirebaseFirestore.instance.collection('students');
      int recipientCount = 0;

      if (departments.contains('All')) {
        QuerySnapshot snapshot = await studentsQuery.get();
        recipientCount = snapshot.size;
      } else {
        if (_requireExactGroupCombination) {
          if (surveyDeptsUpper.length <= 2) {
            final exactGroup = surveyDeptsUpper.join('/');
            QuerySnapshot snapshot =
                await studentsQuery.where('group', isEqualTo: exactGroup).get();
            recipientCount = snapshot.size;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      "Exact match can only be used with one or two departments")),
            );
            return;
          }
        } else if (_showOnlySelectedDepartments) {
          Set<String> processedIds = {};
          for (String dept in surveyDeptsUpper) {
            QuerySnapshot snapshot =
                await studentsQuery.where('group', isEqualTo: dept).get();
            for (var doc in snapshot.docs) {
              if (!processedIds.contains(doc.id)) {
                processedIds.add(doc.id);
                recipientCount++;
              }
            }
          }
        } else {
          QuerySnapshot allStudentsSnapshot = await studentsQuery.get();
          Set<String> processedIds = {};
          for (var doc in allStudentsSnapshot.docs) {
            String group = (doc.data() as Map<String, dynamic>)['group'] ?? '';
            List<String> groupComponents =
                group.split('/').map((e) => e.trim().toUpperCase()).toList();
            for (String dept in surveyDeptsUpper) {
              if (groupComponents.contains(dept)) {
                if (!processedIds.contains(doc.id)) {
                  processedIds.add(doc.id);
                  recipientCount++;
                }
                break;
              }
            }
          }
        }
      }

      if (recipientCount == 0) {
        print("No students found matching the criteria: $surveyDeptsUpper");
        return;
      }

      print("Found $recipientCount potential recipients");

      await FirebaseFirestore.instance
          .collection('surveys')
          .doc(surveyId)
          .update({'recipientCount': recipientCount});

      await FirebaseFirestore.instance.collection('notifications').add({
        'surveyId': surveyId,
        'title': 'New Survey: $surveyName',
        'body': 'A new survey is available for your department',
        'departments': departments,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': {},
        'surveyName': surveyName,
        'type': 'global',
        'targetDepartments': surveyDeptsUpper,
        'requireExactGroup': _requireExactGroupCombination,
        'showOnlySelectedDepartments': _showOnlySelectedDepartments,
      });

      print("Successfully created global notification for survey");
    } catch (e) {
      print("Error creating notification: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to create notification: $e")),
      );
    }
  }

  void _finishSurvey() async {
    if (_isSubmitting) return;

    final String surveyName = _surveyNameController.text.trim();
    if (_selectedDepartments.isEmpty ||
        surveyName.isEmpty ||
        _questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Please enter a survey name, select at least one department, and add at least one question."),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _addSurveyToDatabase(surveyName, _questions);
      _surveyNameController.clear();
      setState(() {
        _questions = [];
        _selectedDepartments = [];
        _deadline = null;
        _requireExactGroupCombination = false;
        _isSubmitting = false;
      });

      Navigator.popUntil(
        context,
        (route) => route.settings.name == '/firsrforadminn',
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to create survey. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDeadline() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _deadline = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Create Survey", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 28, 51, 95),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.popUntil(
              context,
              (route) => route.settings.name == '/firsrforadminn',
            );
          },
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Create Survey Name",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Colors.black),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _surveyNameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter survey name",
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Select Departments",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Colors.black),
              ),
              SizedBox(height: 10),
              
              Container(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _departments.map((department) {
                    bool isSelectable = department == 'All' ||
                        !_selectedDepartments.contains('All');
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(department),
                        selected: _selectedDepartments.contains(department),
                        onSelected: (isSelected) {
                          if (!isSelectable) return;
                          setState(() {
                            if (department == 'All') {
                              _selectedDepartments = isSelected ? ['All'] : [];
                            } else {
                              if (isSelected) {
                                _selectedDepartments.add(department);
                              } else {
                                _selectedDepartments.remove(department);
                              }
                            }
                          });
                        },
                        backgroundColor: isSelectable ? null : Colors.grey[300],
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (_selectedDepartments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Selected: ${_selectedDepartments.join(', ')}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 28, 51, 95),
                    ),
                  ),
                ),
              SizedBox(height: 10),
              Column(
                children: [
                  SwitchListTile(
                    title: Text("Exact Department"),
                    subtitle: Text("Only this specific department"),
                    value: _requireExactGroupCombination,
                    onChanged: _selectedDepartments.contains('All') ||
                            _selectedDepartments.length > 2
                        ? null
                        : (value) {
                            setState(() {
                              _requireExactGroupCombination = value;
                              if (value) _showOnlySelectedDepartments = false;
                            });
                          },
                  ),
                  SwitchListTile(
                    title: Text("Separate Departments"),
                    subtitle: Text("Don't include double departments"),
                    value: _showOnlySelectedDepartments,
                    onChanged: _selectedDepartments.contains('All') ||
                            _selectedDepartments.length < 2
                        ? null
                        : (value) {
                            setState(() {
                              _showOnlySelectedDepartments = value;
                              if (value) _requireExactGroupCombination = false;
                            });
                          },
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                "Set Deadline",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Colors.black),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 253, 200, 0),
                ),
                onPressed: _selectDeadline,
                child: Text(
                  _deadline != null
                      ? DateFormat('yyyy-MM-dd HH:mm').format(_deadline!)
                      : "Add Deadline",
                  style: TextStyle(color: Colors.black),
                ),
              ),
              SizedBox(height: 30),
              Text(
                "Submission Settings",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Colors.black),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_allowMultipleSubmissions
                          ? Color.fromARGB(255, 253, 200, 0)
                          : Colors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _allowMultipleSubmissions = false),
                    child: Text("Once", style: TextStyle(color: Colors.black)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _allowMultipleSubmissions
                          ? Color.fromARGB(255, 253, 200, 0)
                          : Colors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _allowMultipleSubmissions = true),
                    child: Text("Multiple Times",
                        style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
              SizedBox(height: 30),
              Text(
                "Create Survey Questions",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Colors.black),
              ),
              SizedBox(height: 20),
              ..._questions.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            question['title'],
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          color: Colors.red,
                          iconSize: 24,
                          splashColor: Colors.red.withOpacity(0.2),
                          onPressed: () => _deleteQuestion(index),
                        ),
                      ],
                    ),
                    if (question['type'] == 'multiple_choice')
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            question['title'] = value;
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[200],
                          hintText: "Edit the question",
                        ),
                      ),
                    if (question['type'] == 'multiple_choice')
                      Column(
                        children: [
                          ...question['options']
                              .asMap()
                              .entries
                              .map((optionEntry) {
                            final optionIndex = optionEntry.key;
                            final option = optionEntry.value;

                            if (question['controllers'] == null) {
                              question['controllers'] = [];
                            }

                            if (optionIndex >= question['controllers'].length) {
                              question['controllers']
                                  .add(TextEditingController(text: option));
                            } else {
                              if (question['controllers'][optionIndex].text !=
                                  option) {
                                question['controllers'][optionIndex].text =
                                    option;
                              }
                            }

                            return Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: question['controllers']
                                        [optionIndex],
                                    onChanged: (newValue) {
                                      _editOption(
                                          question, optionIndex, newValue);
                                    },
                                    decoration: InputDecoration(
                                      labelText: "Option ${optionIndex + 1}",
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  color: Colors.red,
                                  iconSize: 24,
                                  splashColor: Colors.red.withOpacity(0.2),
                                  onPressed: () {
                                    setState(() {
                                      final controller = question['controllers']
                                          .removeAt(optionIndex);
                                      controller.dispose();
                                      question['options'].removeAt(optionIndex);
                                    });
                                  },
                                ),
                              ],
                            );
                          }).toList(),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.add),
                                onPressed: () {
                                  setState(() {
                                    final newOption = 'New Option';
                                    question['options'].add(newOption);

                                    if (question['controllers'] == null) {
                                      question['controllers'] = [];
                                    }
                                    question['controllers'].add(
                                        TextEditingController(text: newOption));
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    if (question['type'] == 'textfield')
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            question['title'] = value;
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[200],
                          hintText: "Edit the textfield question",
                        ),
                      ),
                    SizedBox(height: 20),
                  ],
                );
              }),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 253, 200, 0)),
                    onPressed: () => _addQuestion(false),
                    child: Text("Add Multiple Choice Question",
                        style: TextStyle(color: Colors.black)),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 253, 200, 0)),
                    onPressed: () => _addQuestion(true),
                    child: Text("Add Textfield Question",
                        style: TextStyle(color: Colors.black)),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSubmitting 
                        ? Colors.grey 
                        : Color.fromARGB(255, 253, 200, 0),
                    ),
                    onPressed: _isSubmitting ? null : _finishSurvey,
                    child: _isSubmitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text("Creating Survey...",
                                  style: TextStyle(color: Colors.black)),
                            ],
                          )
                        : Text("Finish the survey",
                            style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        survv: true,
      ),
    );
  }

  void _editOption(Map<String, dynamic> question, int index, String newValue) {
    setState(() {
      question['options'][index] = newValue;
    });
  }

  void _deleteQuestion(int index) {
    setState(() {
      _questions.removeAt(index);

      for (int i = 0; i < _questions.length; i++) {
        final question = _questions[i];
        if (question['title'].startsWith('Question ')) {
          question['title'] = 'Question ${i + 1}';
        } else if (question['title'].startsWith('textfield ')) {
          question['title'] = 'textfield ${i + 1}';
        }
      }
    });
  }
}
