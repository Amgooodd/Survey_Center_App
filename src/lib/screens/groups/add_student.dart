import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:student_questionnaire/screens/groups/groups_details.dart';

import '../../widgets/Bottom_bar.dart';

class AddStudentScreen extends StatefulWidget {
  final String groupId;
  const AddStudentScreen({required this.groupId, super.key});

  @override
  _AddStudentScreenState createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _studentNameController = TextEditingController();
  bool _isLoading = false;

  final Map<String, String> groupNameMap = {
    'STAT/CS': 'STAT / CS',
    'Math/CS': 'Math/CS',
  };

  Future<void> _addStudentToDatabase(String groupId) async {
    setState(() {
      _isLoading = true;
    });

    final String studentId = _studentIdController.text.trim();
    final String studentName = _studentNameController.text.trim();

    if (studentId.length != 14) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Student ID must be exactly 14 digits long.")),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (studentId.isNotEmpty && studentName.isNotEmpty) {
      try {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('students')
            .doc(studentId)
            .get();

        if (docSnapshot.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "Student ID already exists. Please enter a unique ID.")),
          );
        } else {
          final group = groupId.trim().toUpperCase();
          final groupComponents = group
              .split('/')
              .map((e) => e.trim().toUpperCase())
              .toList()
            ..sort();

          final groupString = groupComponents.join('/');

          await FirebaseFirestore.instance
              .collection('students')
              .doc(studentId)
              .set({
            'id': studentId,
            'name': studentName,
            'group': groupString,
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Student added successfully!")),
          );
          _studentIdController.clear();
          _studentNameController.clear();
          Navigator.pop(context);
        }
      } catch (e) {
        print("Error adding student: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add student. Please try again.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter both Student ID and Name.")),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Student", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 28, 51, 95),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    GroupDetailsScreen(groupId: widget.groupId),
              ),
            );
          },
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _studentIdController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: "Student ID",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _studentNameController,
              decoration: InputDecoration(
                labelText: "Student Name",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      _addStudentToDatabase(widget.groupId);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 253, 200, 0),
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                textStyle: TextStyle(fontSize: 18),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Add Student", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        groupp: true,
      ),
    );
  }
}
