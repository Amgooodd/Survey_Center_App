import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_questionnaire/screens/AdminHome/recycle_bin_page.dart';
import 'package:student_questionnaire/screens/Auth/login_page.dart';
import '../../widgets/Bottom_bar.dart';
import 'survey_details.dart';

class FirstForAdmin extends StatefulWidget {
  const FirstForAdmin({super.key});

  @override
  _FirstForAdminState createState() => _FirstForAdminState();
}

class _FirstForAdminState extends State<FirstForAdmin> {
  late Stream<List<DocumentSnapshot>> _surveysStream;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _selectedDepartments = {};
  String _selectedSortOption = 'newest';
  final List<String> _departments = ['CS', 'Stat', 'Math'];

  @override
  void initState() {
    super.initState();
    _surveysStream = FirebaseFirestore.instance
        .collection('surveys')
        .snapshots()
        .map((snapshot) => snapshot.docs);
    _sortSurveys();
  }

  void _clearFilter(String department) {
    setState(() {
      _selectedDepartments.remove(department);
    });
  }

  void _sortSurveys() {
    setState(() {});
  }

  Future<void> _deleteAllInCollection(String collectionName) async {
    if (collectionName == 'surveys') {
      final surveysCollection =
          FirebaseFirestore.instance.collection('surveys');
      final snapshot = await surveysCollection.get();
      for (var doc in snapshot.docs) {
        await FirebaseFirestore.instance.collection('backup').doc(doc.id).set({
          ...doc.data(),
          'backupTimestamp': FieldValue.serverTimestamp(),
        });

        await doc.reference.delete();
      }
    } else {
      final collection = FirebaseFirestore.instance.collection(collectionName);
      final snapshot = await collection.get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }
  }

  Future<void> _resetAllSurveys() async {
    try {
      await _deleteAllInCollection('surveys');

      await FirebaseFirestore.instance.collection('notifications').get().then(
          (snap) =>
              Future.wait(snap.docs.map((doc) => doc.reference.delete())));
      await FirebaseFirestore.instance
          .collection('students_responses')
          .get()
          .then((snap) =>
              Future.wait(snap.docs.map((doc) => doc.reference.delete())));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("All surveys and related data deleted")),
      );
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to reset surveys: $e")),
      );
    }
  }

  Future<void> _deleteAllStudents() async {
    try {
      await _deleteAllInCollection('students');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("All student data deleted")),
      );
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete students: $e")),
      );
    }
  }

  Future<void> _resetEverything() async {
    try {
      await _deleteAllInCollection('surveys');

      await _deleteAllInCollection('notifications');
      await _deleteAllInCollection('students_responses');
      await _deleteAllInCollection('students');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("All data reset except admins")),
      );
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Reset failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bool isSuperAdmin = (args?['isSuperAdmin'] as bool?) ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(isSuperAdmin ? "Home " : "Home ",
            style: TextStyle(
              color: Colors.white,
            )),
        backgroundColor: const Color.fromARGB(255, 28, 51, 95),
        leading: IconButton(
          icon: Icon(Icons.logout, color: Colors.red),
          onPressed: () async {
            bool? confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(
                  "Confirm Logout",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Text(
                  "Are you sure you want to log out?",
                  style: TextStyle(color: Colors.black),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      "Yes, Logout",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              logout(context);
            }
          },
        ),
        centerTitle: true,
        actions: isSuperAdmin
            ? [
                PopupMenuButton<String>(
                  icon: Icon(Icons.settings, color: Colors.white),
                  onSelected: (value) async {
                    bool? confirmedFirst = false;
                    bool? confirmedSecond = false;
                    bool? confirmedThird = false;
                    switch (value) {
                      case 'reset_surveys':
                        confirmedFirst = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              "Warning",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                            content: Text(
                              "This will delete all surveys, notifications, and responses. Continue?",
                              style: TextStyle(color: Colors.black),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  "Yes",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirmedFirst != null && confirmedFirst) {
                          confirmedSecond = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                "Warning again",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                              content: Text(
                                "Are you sure? This action cannot be undone.",
                                style: TextStyle(color: Colors.black),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(
                                    "Yes",
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirmedSecond != null && confirmedSecond) {
                            confirmedThird = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor:
                                    Color.fromARGB(255, 253, 200, 0),
                                title: Text(
                                  "Final Warning",
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                ),
                                content: Text(
                                  "LAST CHANCE: Proceed with deleting all surveys and related data?",
                                  style: TextStyle(
                                    color: Colors.black,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(
                                      "Cancel",
                                      style: TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(
                                      "Proceed",
                                      style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirmedThird != null && confirmedThird) {
                              await _resetAllSurveys();
                            }
                          }
                        }
                        break;
                      case 'delete_students':
                        confirmedFirst = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              "Warning",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                            content: Text(
                              "This will delete all student data. Continue?",
                              style: TextStyle(color: Colors.black),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  "Yes",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirmedFirst != null && confirmedFirst) {
                          confirmedSecond = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                "Warning again",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                              content: Text(
                                "Are you sure? This action cannot be undone.",
                                style: TextStyle(color: Colors.black),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(
                                    "Yes",
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirmedSecond != null && confirmedSecond) {
                            confirmedThird = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor:
                                    Color.fromARGB(255, 253, 200, 0),
                                title: Text(
                                  "Final Warning",
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                ),
                                content: Text(
                                  "LAST CHANCE: Proceed with deleting all student data?",
                                  style: TextStyle(
                                    color: Colors.black,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(
                                      "Cancel",
                                      style: TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(
                                      "Proceed",
                                      style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirmedThird != null && confirmedThird) {
                              await _deleteAllStudents();
                            }
                          }
                        }
                        break;
                      case 'reset_all':
                        confirmedFirst = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              "Warning",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                            content: Text(
                              "This will delete all data except admins. Continue?",
                              style: TextStyle(color: Colors.black),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  "Yes",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirmedFirst != null && confirmedFirst) {
                          confirmedSecond = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                "Warning again",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                              content: Text(
                                "Are you sure? This action cannot be undone.",
                                style: TextStyle(color: Colors.black),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(
                                    "Yes",
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirmedSecond != null && confirmedSecond) {
                            confirmedThird = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor:
                                    Color.fromARGB(255, 253, 200, 0),
                                title: Text(
                                  "Final Warning",
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                ),
                                content: Text(
                                  "LAST CHANCE: Proceed with deleting all data except admins?",
                                  style: TextStyle(
                                    color: Colors.black,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(
                                      "Cancel",
                                      style: TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(
                                      "Proceed",
                                      style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirmedThird != null && confirmedThird) {
                              await _resetEverything();
                            }
                          }
                        }
                        break;
                      case 'recyclebin':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecycleBinPage(),
                          ),
                        );
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'reset_surveys',
                      child: Row(
                        children: [
                          Icon(Icons.note_alt_outlined, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Delete All Surveys'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete_students',
                      child: Row(
                        children: [
                          Icon(Icons.people_alt, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Delete All Students'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'reset_all',
                      child: Row(
                        children: [
                          Icon(Icons.lock_reset, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Reset the app'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'recyclebin',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.blueGrey),
                          SizedBox(width: 10),
                          Text('Recycle bin'),
                        ],
                      ),
                    ),
                  ],
                ),
              ]
            : [],
      ),
      backgroundColor: Colors.white,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search),
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
                    SizedBox(width: 10),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.filter_list),
                      itemBuilder: (context) => _departments.map((department) {
                        return PopupMenuItem<String>(
                          value: department,
                          child: Row(
                            children: [
                              Checkbox(
                                value:
                                    _selectedDepartments.contains(department),
                                onChanged: (value) {
                                  setState(() {
                                    if (value!) {
                                      _selectedDepartments.add(department);
                                    } else {
                                      _selectedDepartments.remove(department);
                                    }
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                              Text(department),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                if (_selectedDepartments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Wrap(
                      spacing: 8.0,
                      children: _selectedDepartments.map((department) {
                        return Chip(
                          label: Text(department),
                          deleteIcon: Icon(Icons.close, size: 16),
                          onDeleted: () => _clearFilter(department),
                        );
                      }).toList(),
                    ),
                  ),
                SizedBox(height: 10),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('admins')
                      .doc(args?['adminId'])
                      .get(),
                  builder: (context, snapshot) {
                    String adminName = "Admin";
                    if (snapshot.hasData && snapshot.data != null) {
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>?;
                      adminName = data?['name'] ?? "Admin";
                    }
                    return Text(
                      'Welcome Dr. $adminName',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 28, 51, 95),
                      ),
                    );
                  },
                ),
                SizedBox(height: 10),
                Container(
                  width: 350,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(6),
                    image: const DecorationImage(
                      image: AssetImage("assets/adminmain.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Your available surveys :',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 28, 51, 95),
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  height: 340,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 2.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 28, 51, 95),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          height: 40,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              DropdownButton<String>(
                                value: _selectedSortOption,
                                icon: const Icon(
                                  Icons.sort,
                                  size: 24,
                                  color: Colors.white,
                                ),
                                underline: const SizedBox(),
                                dropdownColor:
                                    const Color.fromARGB(255, 28, 51, 95),
                                style: const TextStyle(color: Colors.white),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'newest',
                                    child: Text('Newest First'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'oldest',
                                    child: Text('Oldest First'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'a-z',
                                    child: Text('A-Z'),
                                  ),
                                ],
                                onChanged: (String? value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedSortOption = value;
                                      _sortSurveys();
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: StreamBuilder<List<DocumentSnapshot>>(
                            stream: _surveysStream,
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Center(
                                    child: Text('Error: ${snapshot.error}'));
                              }

                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                    child: CircularProgressIndicator());
                              }

                              if (snapshot.data == null ||
                                  snapshot.data!.isEmpty) {
                                return Center(
                                    child: Text(
                                  "No surveys available.",
                                  style: TextStyle(
                                    color:
                                        const Color.fromARGB(255, 28, 51, 95),
                                  ),
                                ));
                              }

                              String currentUserId =
                                  FirebaseAuth.instance.currentUser?.uid ?? "";

                              final filteredSurveys =
                                  snapshot.data!.where((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final name =
                                    data['name']?.toString().toLowerCase() ??
                                        '';
                                final departments = (data['departments']
                                            as List<dynamic>?)
                                        ?.map((d) => d.toString().toLowerCase())
                                        .toSet() ??
                                    {};
                                final createdBy =
                                    data['madyby']?.toString() ?? '';
                                if (!isSuperAdmin) {
                                  return createdBy == currentUserId &&
                                      name.contains(_searchQuery) &&
                                      (_selectedDepartments.isEmpty ||
                                          _selectedDepartments.every((dep) =>
                                              departments.contains(
                                                  dep.toLowerCase())));
                                } else {
                                  return name.contains(_searchQuery) &&
                                      (_selectedDepartments.isEmpty ||
                                          _selectedDepartments.every((dep) =>
                                              departments.contains(
                                                  dep.toLowerCase())));
                                }
                              }).toList();

                              filteredSurveys.sort((a, b) {
                                final aData = a.data() as Map<String, dynamic>;
                                final bData = b.data() as Map<String, dynamic>;

                                switch (_selectedSortOption) {
                                  case 'newest':
                                    final aTimestamp =
                                        aData['timestamp'] as Timestamp?;
                                    final bTimestamp =
                                        bData['timestamp'] as Timestamp?;
                                    if (aTimestamp == null ||
                                        bTimestamp == null) return 0;
                                    return bTimestamp.compareTo(aTimestamp);
                                  case 'oldest':
                                    final aTimestamp =
                                        aData['timestamp'] as Timestamp?;
                                    final bTimestamp =
                                        bData['timestamp'] as Timestamp?;
                                    if (aTimestamp == null ||
                                        bTimestamp == null) return 0;
                                    return aTimestamp.compareTo(bTimestamp);
                                  case 'a-z':
                                    final aName = aData['name']
                                            ?.toString()
                                            .toLowerCase() ??
                                        '';
                                    final bName = bData['name']
                                            ?.toString()
                                            .toLowerCase() ??
                                        '';
                                    return aName.compareTo(bName);
                                  default:
                                    return 0;
                                }
                              });
                              return Column(
                                children: filteredSurveys.map((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final questions = data['questions'] ?? [];
                                  final departments =
                                      (data['departments'] as List<dynamic>?)
                                              ?.map((d) => d.toString())
                                              .join(', ') ??
                                          'Unknown Departments';
                                  final timestamp =
                                      data['timestamp'] as Timestamp?;
                                  final formattedTime = timestamp != null
                                      ? '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}'
                                      : 'N/A';

                                  return SurveyCard(
                                    title: data['name'] ?? 'Unnamed Survey',
                                    subtitle:
                                        'Number of questions : ${questions.length} questions',
                                    departments: departments,
                                    createdAt: formattedTime,
                                    survey: doc,
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBarWidget(homee: true),
    );
  }
}

class SurveyCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String departments;
  final String createdAt;
  final DocumentSnapshot survey;

  const SurveyCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.departments,
    required this.createdAt,
    required this.survey,
  });

  Future<Map<String, int>> _getResponseStats() async {
    try {
      
      final responseQuery = await FirebaseFirestore.instance
          .collection('students_responses')
          .where('surveyId', isEqualTo: survey.id)
          .get();

      
      final uniqueRespondents = responseQuery.docs
          .map((doc) => doc.data()['studentId']?.toString())
          .whereType<String>()
          .toSet()
          .length;

      
      final recipientCount = (survey.data() as Map<String, dynamic>)['recipientCount'] as int? ?? 0;

      return {
        'unique': uniqueRespondents,
        'total': recipientCount,
      };
    } catch (e) {
      print("Error getting response stats: $e");
      return {'unique': 0, 'total': 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 5,
              spreadRadius: 2,
              offset: Offset(0, 2),
            )
          ],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 28, 51, 95),
                              ),
                            ),
                          ),
                          FutureBuilder<Map<String, int>>(
                            future: _getResponseStats(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                );
                              }
                              
                              final unique = snapshot.data?['unique'] ?? 0;
                              final total = snapshot.data?['total'] ?? 0;
                              
                              return Text(
                                '$unique/$total responses',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color.fromARGB(255, 43, 77, 140),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: const Color.fromARGB(255, 70, 94, 105)),
                    ),
                    Text(
                      'Departments: $departments',
                      style: TextStyle(
                          fontSize: 12,
                          color: const Color.fromARGB(255, 70, 94, 105)),
                    ),
                    Text(
                      'Created at: $createdAt',
                      style: TextStyle(
                          fontSize: 12,
                          color: const Color.fromARGB(255, 70, 94, 105)),
                    ),
                    Flexible(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 253, 200, 0),
                                minimumSize: Size(100, 36),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8)),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SurveyDetailsScreen(survey: survey),
                                ),
                              );
                            },
                            child: Text(
                              'View Details',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}