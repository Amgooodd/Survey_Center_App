import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnswerViewPage extends StatelessWidget {
  final String surveyId;
  const AnswerViewPage({super.key, required this.surveyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
    title: Text(
      'Student Responses',
      style: TextStyle(
        color: Colors.white, 
      ),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    backgroundColor: const Color.fromARGB(255, 28, 51, 95),
  ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students_responses')
            .where('surveyId', isEqualTo: surveyId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final responses = snapshot.data!.docs;
          if (responses.isEmpty) {
            return const Center(child: Text('No responses yet.'));
          }
          return ListView.builder(
            itemCount: responses.length,
            itemBuilder: (context, index) {
              final response = responses[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student Name: ${response['studentName']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color.fromARGB(255, 28, 51, 95),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Student ID: ${response['studentId']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color.fromARGB(255, 23, 23, 23),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ExpansionTile(
                        title: const Text(
                          'Answers',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color.fromARGB(255, 28, 51, 95),
                          ),
                        ),
                        children: [
                          ...response['answers'].entries.map(
                            (entry) {
                              return ListTile(
                                dense: true,
                                title: Text(
                                  'Question: ${entry.key}',
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 28, 51, 95), 
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14                         ),
                                ),
                                subtitle: RichText(
            text: TextSpan(
              style: const TextStyle(color: Color.fromARGB(255, 34, 34, 34)), 
              children: [
                const TextSpan( 
                  text: 'Answer: ',
                  style: TextStyle(color: Colors.red),
                ),
                TextSpan( 
                  text: entry.value,
                ),
              ],
            ),
          ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}