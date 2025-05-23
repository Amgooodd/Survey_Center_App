import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class AdminManagementScreen extends StatefulWidget {
  final String currentAdminId;
  const AdminManagementScreen({super.key, required this.currentAdminId});

  @override
  _AdminManagementScreenState createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();

  Future<void> _addAdmin() async {
    if (!_formKey.currentState!.validate()) return;
    final adminId = _idController.text.trim();
    final name = _nameController.text.trim();
    final password = _generatePassword();
    final isEmailVerified = false;

    try {
      await _firestore.collection('admins').doc(adminId).set({
        'id': adminId,
        'name': name,
        'defaultPassword': password,
        'isSuperAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
        'isEmailVerified': isEmailVerified
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Admin $name created successfully')),
      );
      _idController.clear();
      _nameController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String _generatePassword() {
    const chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890!@#\$%^&*';
    final rnd = Random.secure();
    return String.fromCharCodes(Iterable.generate(
      12,
      (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
    ));
  }

  Future<void> _deleteAdmin(String adminId) async {
    if (adminId == widget.currentAdminId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete yourself')),
      );
      return;
    }
    await _firestore.collection('admins').doc(adminId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Management',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color.fromARGB(255, 28, 51, 95),
        icon: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        label: const Text(
          'Add admin',
          style: TextStyle(color: Colors.white),
        ),
        onPressed: () => showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              'Add new admin',
              style: TextStyle(
                fontSize: 22,
                color: Color.fromARGB(255, 28, 51, 95),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _idController,
                      decoration: const InputDecoration(
                        labelText: 'Admin ID (Manual Entry)',
                        labelStyle: TextStyle(
                          color: Color.fromARGB(255, 28, 51, 95),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color.fromARGB(255, 28, 51, 95),
                              width: 2.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color.fromARGB(255, 28, 51, 95),
                              width: 1.0),
                        ),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Admin ID is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: TextStyle(
                          color: Color.fromARGB(255, 28, 51, 95),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color.fromARGB(255, 28, 51, 95),
                              width: 2.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color.fromARGB(255, 28, 51, 95),
                              width: 1.0),
                        ),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 28, 51, 95),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(context);
                    _addAdmin();
                  }
                },
                child: const Text(
                  'Create Admin',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('admins')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No admins found'));
            }
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                return Card(
                  elevation: 4,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              data['name'] ?? 'No Name',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!(data['isSuperAdmin'] ?? false))
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteAdmin(doc.id),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ID: ${data['id']}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Chip(
                              label: Text(
                                data['isSuperAdmin'] ?? false
                                    ? 'Super Admin'
                                    : 'Admin',
                                style: const TextStyle(color: Colors.black),
                              ),
                              backgroundColor: data['isSuperAdmin'] ?? false
                                  ? Colors.blue
                                  : Color.fromARGB(255, 253, 200, 0),
                            ),
                          ],
                        ),
                        if (data['defaultPassword'] != null) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Default Password:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(
                                  ClipboardData(text: data['defaultPassword']));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Password copied to clipboard')),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    data['defaultPassword'],
                                    style: const TextStyle(
                                        fontFamily: 'monospace'),
                                  ),
                                  const Icon(Icons.copy, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
