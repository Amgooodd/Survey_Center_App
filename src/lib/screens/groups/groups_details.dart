import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:student_questionnaire/asset_map.dart';
import 'package:student_questionnaire/screens/groups/add_student.dart';
import '../../widgets/Bottom_bar.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String groupId;
  const GroupDetailsScreen({required this.groupId, super.key});

  @override
  _GroupDetailsScreenState createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupId, style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 28, 51, 95),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushNamed(context, '/groupp');
          },
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              width: 350,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(6),
                image: DecorationImage(
                  image: AssetImage(
                      'assets/${assetMap[widget.groupId.toLowerCase().replaceAll("/", "_")]}.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              "List of ${widget.groupId} students",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('students')
                  .where('group', isEqualTo: widget.groupId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                final students = snapshot.data?.docs ?? [];
                return Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student =
                          students[index].data() as Map<String, dynamic>;
                      final studentId = student['id'];
                      final studentName = student['name'];
                      return StudentCard(
                        studentId: studentId,
                        studentName: studentName,
                        groupId: widget.groupId,
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditStudentScreen(
                                studentId: studentId,
                                studentName: studentName,
                                groupId: widget.groupId,
                              ),
                            ),
                          );
                        },
                        onDelete: () async {
                          await FirebaseFirestore.instance
                              .collection('students')
                              .doc(studentId)
                              .delete();
                        },
                      );
                    },
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddStudentScreen(groupId: widget.groupId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 253, 200, 0),
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                textStyle: TextStyle(fontSize: 18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.black),
                  SizedBox(width: 5),
                  Text("Add to the group",
                      style: TextStyle(color: Colors.black)),
                ],
              ),
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

class StudentCard extends StatelessWidget {
  final String studentId;
  final String studentName;
  final String groupId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const StudentCard({
    required this.studentId,
    required this.studentName,
    required this.groupId,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(Icons.person),
        title: Text(studentName),
        subtitle: Text("ID: $studentId"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class EditStudentScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String groupId;

  const EditStudentScreen({
    required this.studentId,
    required this.studentName,
    required this.groupId,
    super.key,
  });

  @override
  _EditStudentScreenState createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends State<EditStudentScreen> {
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _studentNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _studentIdController.text = widget.studentId;
    _studentNameController.text = widget.studentName;
  }

  Future<void> _updateStudentInDatabase() async {
    final String newStudentId = _studentIdController.text.trim();
    final String newStudentName = _studentNameController.text.trim();

    if (newStudentId.isNotEmpty && newStudentName.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('students')
            .doc(widget.studentId)
            .update({
          'name': newStudentName,
        });

        if (newStudentId != widget.studentId) {
          await FirebaseFirestore.instance
              .collection('students')
              .doc(newStudentId)
              .set({
            'id': newStudentId,
            'name': newStudentName,
            'group': widget.groupId,
          });
          await FirebaseFirestore.instance
              .collection('students')
              .doc(widget.studentId)
              .delete();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Student updated successfully!")),
        );
        Navigator.pop(context);
      } catch (e) {
        print("Error updating student: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed to update student. Please try again.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter both Student ID and Name.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Student", style: TextStyle(color: Colors.white)),
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
              onPressed: () {
                _updateStudentInDatabase();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 253, 200, 0),
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                textStyle: TextStyle(fontSize: 18),
              ),
              child:
                  Text("Update Student", style: TextStyle(color: Colors.black)),
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
