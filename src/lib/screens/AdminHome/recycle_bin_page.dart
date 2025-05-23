import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RecycleBinPage extends StatefulWidget {
  @override
  _RecycleBinPageState createState() => _RecycleBinPageState();
}

class _RecycleBinPageState extends State<RecycleBinPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Set<String> _selectedSurveys = {};

  Future<void> _restoreSurvey(String surveyId) async {
    final backupDoc = await _firestore.collection('backup').doc(surveyId).get();
    if (backupDoc.exists) {
      await _firestore.collection('surveys').doc(surveyId).set(
            backupDoc.data()!,
            SetOptions(merge: true),
          );
      await _firestore.collection('backup').doc(surveyId).delete();
      setState(() {
        _selectedSurveys.remove(surveyId);
      });
    }
  }

  Future<void> _deletePermanently(String surveyId) async {
    await _firestore.collection('backup').doc(surveyId).delete();
    setState(() {
      _selectedSurveys.remove(surveyId);
    });
  }

  Future<void> _handleBulkAction(String action) async {
    if (_selectedSurveys.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm ${action == 'restore' ? 'Restore' : 'Delete'}"),
        content: Text(
          action == 'restore'
              ? 'Are you sure you want to restore ${_selectedSurveys.length} surveys?'
              : 'Are you sure you want to permanently delete ${_selectedSurveys.length} surveys?',
        ),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text(
              "Confirm",
              style: TextStyle(
                color: action == 'delete' ? Colors.red : Colors.blue,
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final selectedCopy = Set<String>.from(_selectedSurveys);
    int successCount = 0;
    String actionText =
        action == 'restore' ? 'restored' : 'permanently deleted';

    try {
      for (var id in selectedCopy) {
        try {
          if (action == 'restore') {
            await _restoreSurvey(id);
          } else {
            await _deletePermanently(id);
          }
          successCount++;
        } catch (e) {
          print('Failed to $actionText survey $id: $e');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Successfully $actionText $successCount/${selectedCopy.length} surveys'),
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _selectedSurveys.clear());
    }
  }

  Future<void> _handleBulkAllAction(String action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Bulk Action"),
        content: Text(
            "This will ${action.replaceAll('_', ' ')} ALL surveys in recycle bin"),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text("Confirm", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final snapshot = await _firestore.collection('backup').get();
    int total = snapshot.docs.length;
    int successCount = 0;
    String actionText =
        action.contains('restore') ? 'restored' : 'permanently deleted';

    for (var doc in snapshot.docs) {
      try {
        if (action == 'restore_all') {
          await _restoreSurvey(doc.id);
        } else {
          await _deletePermanently(doc.id);
        }
        successCount++;
      } catch (e) {
        print('Failed to $actionText survey ${doc.id}: $e');
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully $actionText $successCount/$total surveys'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Recycle Bin",
          style: TextStyle(color: Colors.white),
        ),
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
        actions: [
          if (_selectedSurveys.isNotEmpty)
            Row(
              children: [
                Text("${_selectedSurveys.length} selected",
                    style: TextStyle(
                        fontSize: 16,
                        color: const Color.fromARGB(255, 0, 0, 0))),
                IconButton(
                  icon: Icon(Icons.restore, size: 28, color: Colors.blue),
                  onPressed: () => _handleBulkAction('restore'),
                  tooltip: 'Restore selected',
                ),
                IconButton(
                  icon: Icon(Icons.delete_forever, size: 28, color: Colors.red),
                  onPressed: () => _handleBulkAction('delete'),
                  tooltip: 'Delete selected',
                ),
              ],
            )
          else
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.white),
              onSelected: _handleBulkAllAction,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'restore_all',
                  child: ListTile(
                    leading: Icon(Icons.restore, color: Colors.blue),
                    title: Text('Restore All'),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete_all',
                  child: ListTile(
                    leading: Icon(Icons.delete_forever, color: Colors.red),
                    title:
                        Text('Delete All', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('backup').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('Recycle Bin is empty',
                  style: TextStyle(fontSize: 18, color: Colors.grey)),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final date = (data['backupTimestamp'] as Timestamp).toDate();
              final formattedDate =
                  DateFormat('MMM dd, yyyy - HH:mm').format(date);

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ExpansionTile(
                  key: ValueKey(doc.id),
                  leading: Checkbox(
                    activeColor: Color.fromARGB(255, 28, 51, 95),
                    value: _selectedSurveys.contains(doc.id),
                    onChanged: (value) => setState(() {
                      if (value!) {
                        _selectedSurveys.add(doc.id);
                      } else {
                        _selectedSurveys.remove(doc.id);
                      }
                    }),
                  ),
                  title: Text(
                    data['name'] ?? 'Unnamed Survey',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Deleted: $formattedDate',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  childrenPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  tilePadding: EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Divider(color: Colors.grey[300]),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        'Questions:',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                    ...(data['questions'] as List<dynamic>).map((q) => Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('• ', style: TextStyle(fontSize: 16)),
                                  Expanded(
                                    child: Text(
                                      q['title'] ?? 'No question title',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (q['type'] == 'multiple_choice' &&
                                  q['options'] != null)
                                Padding(
                                  padding: EdgeInsets.only(left: 16, top: 4),
                                  child: Column(
                                    children: (q['options'] as List<dynamic>)
                                        .map(
                                          (opt) => Padding(
                                            padding: EdgeInsets.only(bottom: 4),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text('◦ ',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                    )),
                                                Expanded(
                                                  child: Text(
                                                    opt.toString(),
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                            ],
                          ),
                        )),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
