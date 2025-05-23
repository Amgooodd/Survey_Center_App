import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';

class FileUploader {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> pickFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
    );

    if (result != null) {
      String? filePath = result.files.single.path;
      if (filePath != null) {
        if (filePath.endsWith('.csv')) {
          await _processCSV(filePath, context);
        } else if (filePath.endsWith('.xlsx')) {
          await _processExcel(filePath, context);
        }
      }
    }
  }

  Future<void> _processCSV(String filePath, BuildContext context) async {
    final File file = File(filePath);
    final String contents = await file.readAsString();
    List<List<dynamic>> rows = const CsvToListConverter().convert(contents);

    for (int i = 1; i < rows.length; i++) {
      String group = rows[i][0].toString();
      String id = rows[i][1].toString();
      String name = rows[i][2].toString();

      await _firestore.collection('students').doc(id).set({
        'group': group,
        'id': id,
        'name': name,
      });
    }

    _showSuccessMessage(context);
  }

  Future<void> _processExcel(String filePath, BuildContext context) async {
    final File file = File(filePath);
    final bytes = await file.readAsBytes();
    final Excel excel = Excel.decodeBytes(bytes);

    for (var table in excel.tables.keys) {
      for (int i = 1; i < excel.tables[table]!.rows.length; i++) {
        var row = excel.tables[table]!.rows[i];

        if (row.length >= 3) {
          String group = row[0]?.value.toString() ?? "";
          String id = row[1]?.value.toString() ?? "";
          String name = row[2]?.value.toString() ?? "";

          await _firestore.collection('students').doc(id).set({
            'group': group,
            'id': id,
            'name': name,
          });
        }
      }
    }

    _showSuccessMessage(context);
  }

  void _showSuccessMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added successful ')),
    );
  }
}
