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
  final List<String> _departments = ['CS', 'Stat', 'Math','PHY','Biology','chemistry'];
  final ValueNotifier<String> _progressText = ValueNotifier<String>('');
  OverlayEntry? _overlayEntry;

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

  void _showProgressOverlay(BuildContext context) {
    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: Container(
            height: 60,
            color: Colors.black87,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ValueListenableBuilder<String>(
              valueListenable: _progressText,
              builder: (context, value, child) {
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Deleting...',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Text(
                            value,
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                          SizedBox(height: 4),
                          Container(
                            height: 2,
                            child: LinearProgressIndicator(
                              backgroundColor: Colors.grey[800],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color.fromARGB(255, 253, 200, 0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  Future<void> _deleteAllInCollection(String collectionName) async {
    if (collectionName == 'surveys') {
      final surveysCollection = FirebaseFirestore.instance.collection('surveys');
      final snapshot = await surveysCollection.get();
      
      List<List<DocumentSnapshot>> chunks = [];
      int chunkSize = 500;
      
      for (var i = 0; i < snapshot.docs.length; i += chunkSize) {
        chunks.add(
          snapshot.docs.sublist(
            i,
            i + chunkSize > snapshot.docs.length ? snapshot.docs.length : i + chunkSize
          )
        );
      }

      int processedDocs = 0;
      int totalDocs = snapshot.docs.length;

      for (var chunk in chunks) {
        WriteBatch backupBatch = FirebaseFirestore.instance.batch();
        WriteBatch deleteBatch = FirebaseFirestore.instance.batch();
        
        for (var doc in chunk) {
          
          backupBatch.set(
            FirebaseFirestore.instance.collection('backup').doc(doc.id),
            {
              ...doc.data() as Map<String, dynamic>,
              'backupTimestamp': FieldValue.serverTimestamp(),
            }
          );
          
          
          deleteBatch.delete(doc.reference);
          
          processedDocs++;
          _progressText.value = 'Processing surveys: ${processedDocs}/${totalDocs}...';
        }
        
        await backupBatch.commit();
        await deleteBatch.commit();
      }
    } else {
      final collection = FirebaseFirestore.instance.collection(collectionName);
      final snapshot = await collection.get();
      
      List<List<DocumentSnapshot>> chunks = [];
      int chunkSize = 500;
      
      for (var i = 0; i < snapshot.docs.length; i += chunkSize) {
        chunks.add(
          snapshot.docs.sublist(
            i,
            i + chunkSize > snapshot.docs.length ? snapshot.docs.length : i + chunkSize
          )
        );
      }

      int processedDocs = 0;
      int totalDocs = snapshot.docs.length;

      for (var chunk in chunks) {
        WriteBatch batch = FirebaseFirestore.instance.batch();
        
        for (var doc in chunk) {
          batch.delete(doc.reference);
          processedDocs++;
          _progressText.value = 'Deleting ${processedDocs}/${totalDocs} students...';
        }
        
        await batch.commit();
      }
    }
  }

  Future<void> _deleteAllStudents() async {
    try {
      _showProgressOverlay(context);
      await _deleteAllInCollection('students');
      _overlayEntry?.remove();
      _overlayEntry = null;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("All student data deleted successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to delete students: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resetAllSurveys() async {
    try {
      _showProgressOverlay(context);
      _progressText.value = 'Starting survey reset...';
      
      
      await _deleteAllInCollection('surveys');
      
      
      final notificationsSnapshot = await FirebaseFirestore.instance.collection('notifications').get();
      final responsesSnapshot = await FirebaseFirestore.instance.collection('students_responses').get();
      
      int totalDocs = notificationsSnapshot.docs.length + responsesSnapshot.docs.length;
      int processedDocs = 0;
      
      
      List<List<DocumentSnapshot>> notificationChunks = [];
      for (var i = 0; i < notificationsSnapshot.docs.length; i += 500) {
        notificationChunks.add(
          notificationsSnapshot.docs.sublist(
            i,
            i + 500 > notificationsSnapshot.docs.length ? notificationsSnapshot.docs.length : i + 500
          )
        );
      }
      
      for (var chunk in notificationChunks) {
        WriteBatch batch = FirebaseFirestore.instance.batch();
        for (var doc in chunk) {
          batch.delete(doc.reference);
          processedDocs++;
          _progressText.value = 'Deleting related data: ${processedDocs}/${totalDocs}...';
        }
        await batch.commit();
      }
      
      
      List<List<DocumentSnapshot>> responseChunks = [];
      for (var i = 0; i < responsesSnapshot.docs.length; i += 500) {
        responseChunks.add(
          responsesSnapshot.docs.sublist(
            i,
            i + 500 > responsesSnapshot.docs.length ? responsesSnapshot.docs.length : i + 500
          )
        );
      }
      
      for (var chunk in responseChunks) {
        WriteBatch batch = FirebaseFirestore.instance.batch();
        for (var doc in chunk) {
          batch.delete(doc.reference);
          processedDocs++;
          _progressText.value = 'Deleting related data: ${processedDocs}/${totalDocs}...';
        }
        await batch.commit();
      }
      
      _overlayEntry?.remove();
      _overlayEntry = null;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("All surveys and related data deleted successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to reset surveys: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resetEverything() async {
    try {
      _showProgressOverlay(context);
      _progressText.value = 'Starting full app reset...';
      
      
      final surveysSnapshot = await FirebaseFirestore.instance.collection('surveys').get();
      final notificationsSnapshot = await FirebaseFirestore.instance.collection('notifications').get();
      final responsesSnapshot = await FirebaseFirestore.instance.collection('students_responses').get();
      final studentsSnapshot = await FirebaseFirestore.instance.collection('students').get();
      
      int totalDocs = surveysSnapshot.docs.length + 
                      notificationsSnapshot.docs.length + 
                      responsesSnapshot.docs.length + 
                      studentsSnapshot.docs.length;
      int processedDocs = 0;
      
      
      await _deleteAllInCollection('surveys');
      processedDocs += surveysSnapshot.docs.length;
      _progressText.value = 'Resetting app: ${processedDocs}/${totalDocs}...';
      
      
      final collections = [
        ('notifications', notificationsSnapshot),
        ('students_responses', responsesSnapshot),
        ('students', studentsSnapshot)
      ];
      
    
      for (var (_, snapshot) in collections) {
        List<List<DocumentSnapshot>> chunks = [];
        for (var i = 0; i < snapshot.docs.length; i += 500) {
          chunks.add(
            snapshot.docs.sublist(
              i,
              i + 500 > snapshot.docs.length ? snapshot.docs.length : i + 500
            )
          );
        }
        
        for (var chunk in chunks) {
          WriteBatch batch = FirebaseFirestore.instance.batch();
          for (var doc in chunk) {
            batch.delete(doc.reference);
            processedDocs++;
            _progressText.value = 'Resetting app: ${processedDocs}/${totalDocs}...';
          }
          await batch.commit();
        }
      }
      
      _overlayEntry?.remove();
      _overlayEntry = null;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("App reset completed successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to reset app: $e"),
          backgroundColor: Colors.red,
        ),
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

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
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

  double _calculateTitleFontSize() {
    if (title.length > 50) {
      return 14.0;
    } else if (title.length > 30) {
      return 15.0;
    }
    return 16.0;
  }

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
        constraints: BoxConstraints(minHeight: 160),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: _calculateTitleFontSize(),
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
                    SizedBox(height: 8),
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
                    SizedBox(height: 8),
                    Row(
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
                                settings: RouteSettings(
                                  arguments: ModalRoute.of(context)?.settings.arguments,
                                ),
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