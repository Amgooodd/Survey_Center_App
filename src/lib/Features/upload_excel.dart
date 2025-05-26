import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';

class UploadProgressOverlay extends StatelessWidget {
  final String progressText;
  final VoidCallback onDismiss;
  final VoidCallback onCancel;

  const UploadProgressOverlay({
    Key? key,
    required this.progressText,
    required this.onDismiss,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Container(
          height: 60,
          color: Colors.black87,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Uploading Students...',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      progressText,
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
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size(0, 0),
                  foregroundColor: Colors.red,
                ),
                child: Text('STOP'),
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FileUploader {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ValueNotifier<String> _progressText = ValueNotifier<String>('');
  OverlayEntry? _overlayEntry;
  bool _isUploading = false;
  bool _isCancelled = false;

  
  Map<String, Map<String, dynamic>> _existingStudents = {};
  Set<String> _existingNameGroupPairs = {};

  
  Future<void> _initializeCache() async {
    _progressText.value = 'Preparing upload...';
    
    
    QuerySnapshot snapshot = await _firestore.collection('students').get();
    
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      _existingStudents[doc.id] = data;
      _existingNameGroupPairs.add('${data['name']}-${data['group']}');
    }
  }

  
  bool _studentExists(String id, String name, String group) {
    return _existingStudents.containsKey(id) || 
           _existingNameGroupPairs.contains('$name-$group');
  }

  
  Future<(int, int)> _processRowsInChunks(List<Map<String, dynamic>> rows, int chunkSize) async {
    List<List<Map<String, dynamic>>> chunks = [];
    for (var i = 0; i < rows.length; i += chunkSize) {
      chunks.add(
        rows.sublist(i, i + chunkSize > rows.length ? rows.length : i + chunkSize)
      );
    }

    int processedRows = 0;
    int skippedDuplicates = 0;
    int totalRows = rows.length;

    for (var chunk in chunks) {
      if (_isCancelled) {
        return (processedRows, skippedDuplicates);
      }

      WriteBatch batch = _firestore.batch();
      int batchSize = 0;

      for (var row in chunk) {
        if (_isCancelled) {
          if (batchSize > 0) {
            await batch.commit();
          }
          return (processedRows, skippedDuplicates);
        }

        String id = row['id'];
        String name = row['name'];
        String group = row['group'];

        if (!_studentExists(id, name, group)) {
          batch.set(_firestore.collection('students').doc(id), row);
          batchSize++;
          
          
          _existingStudents[id] = row;
          _existingNameGroupPairs.add('$name-$group');
        } else {
          skippedDuplicates++;
        }
        
        processedRows++;
        _progressText.value = 'Processing ${processedRows}/${totalRows} students...';
      }

      if (batchSize > 0) {
        await batch.commit();
      }
    }

    return (processedRows, skippedDuplicates);
  }

  Future<List<Map<String, dynamic>>> _prepareRowsFromCSV(String filePath, Map<String, int> columnIndices) async {
    final File file = File(filePath);
    final String contents = await file.readAsString();
    List<List<dynamic>> rows = const CsvToListConverter().convert(contents);
    
    List<Map<String, dynamic>> preparedRows = [];
    
    for (int i = 1; i < rows.length; i++) {
      if (rows[i].length >= rows[0].length) {
        String id = rows[i][columnIndices['id']!].toString().trim();
        String name = rows[i][columnIndices['name']!].toString().trim();
        String originalGroup = rows[i][columnIndices['group']!].toString().trim();
        
        if (id.isEmpty || name.isEmpty || originalGroup.isEmpty) continue;
        
        String mappedGroup = _mapGroupNameToEnglish(originalGroup);
        
        preparedRows.add({
          'id': id,
          'name': name,
          'group': mappedGroup,
          'originalGroup': originalGroup,
        });
      }
    }
    
    return preparedRows;
  }

  Future<List<Map<String, dynamic>>> _prepareRowsFromExcel(String filePath, Excel excel, Map<String, int> columnIndices) async {
    List<Map<String, dynamic>> preparedRows = [];
    
    for (var table in excel.tables.keys) {
      var rows = excel.tables[table]!.rows;
      if (rows.isEmpty) continue;

      for (int i = 1; i < rows.length; i++) {
        var row = rows[i];
        if (row.length >= rows[0].length) {
          String id = (row[columnIndices['id']!]?.value.toString() ?? "").trim();
          String name = (row[columnIndices['name']!]?.value.toString() ?? "").trim();
          String originalGroup = (row[columnIndices['group']!]?.value.toString() ?? "").trim();
          
          if (id.isEmpty || name.isEmpty || originalGroup.isEmpty) continue;
          
          String mappedGroup = _mapGroupNameToEnglish(originalGroup);
          
          preparedRows.add({
            'id': id,
            'name': name,
            'group': mappedGroup,
            'originalGroup': originalGroup,
          });
        }
      }
    }
    
    return preparedRows;
  }

  void _showProgressOverlay(BuildContext context) {
    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (context) => ValueListenableBuilder<String>(
        valueListenable: _progressText,
        builder: (context, value, child) {
          return UploadProgressOverlay(
            progressText: value,
            onDismiss: () {
              _overlayEntry?.remove();
              _overlayEntry = null;
            },
            onCancel: () async {
              await _showCancelConfirmation(context);
            },
          );
        },
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void showUploadProgress(BuildContext context) {
    if (_isUploading && _overlayEntry == null) {
      _showProgressOverlay(context);
    }
  }

  
  String _mapGroupNameToEnglish(String groupName) {
    
    final normalizedGroup = groupName.trim().toUpperCase();
    
    
    final groupMappings = {
      'برنامج الاحصاء الرياضي وعلوم الحاسب': 'CS/STAT',
      'برنامج علوم الحاسب والاحصاء': 'CS/STAT',
      'CS/STAT': 'CS/STAT',
      'برنامج الرياضيات': 'MATH',
      'الرياضيات': 'MATH',
      'MATH': 'MATH',
      'برنامج الرياضيات البحته وعلوم الحاسب': 'CS/MATH',
      'برنامج علوم الحاسب والرياضيات': 'CS/MATH',
      'CS/MATH': 'CS/MATH',
      'برنامج علوم الحاسب': 'CS',
      'علوم الحاسب': 'CS',
      'CS': 'CS',
      'برنامج الفيزياء وعلوم الحاسب': 'CS/PHY',
      'برنامج علوم الحاسب والفيزياء': 'CS/PHY',
      'CS/PHY': 'CS/PHY',
      
    };

    
    if (groupMappings.containsKey(groupName)) {
      return groupMappings[groupName]!;
    }

    
    for (var entry in groupMappings.entries) {
      if (entry.key.trim().toUpperCase() == normalizedGroup) {
        return entry.value;
      }
    }

    
    return groupName;
  }

  
  Map<String, int> _identifyColumns(List<dynamic> headers) {
    final headerMappings = {
      'group': ['group', 'اسم البرنامج', 'البرنامج', 'program', 'department'],
      'id': ['id', 'الرقم الجامعي', 'الرقم القومي/رقم جواز السفر', 'student id', 'university id'],
      'name': ['name', 'اسم الطالب', 'الاسم', 'student name', 'full name'],
    };

    Map<String, int> columnIndices = {};
    List<String> foundColumns = [];
    
    
    List<String> normalizedHeaders = headers.map((h) => h.toString().trim().toLowerCase()).toList();

    
    print('Found headers: $normalizedHeaders');

    
    headerMappings.forEach((key, possibleHeaders) {
      for (int i = 0; i < normalizedHeaders.length; i++) {
        if (possibleHeaders.contains(normalizedHeaders[i])) {
          columnIndices[key] = i;
          foundColumns.add('${normalizedHeaders[i]} (${headers[i]})');
          print('Found $key column at index $i: ${headers[i]}');
          break;
        }
      }
    });

    
    List<String> missingColumns = [];
    if (!columnIndices.containsKey('group')) missingColumns.add('Program/Group (اسم البرنامج)');
    if (!columnIndices.containsKey('id')) missingColumns.add('ID (الرقم القومي/رقم جواز السفر)');
    if (!columnIndices.containsKey('name')) missingColumns.add('Name (اسم الطالب)');

    if (missingColumns.isNotEmpty) {
      throw Exception('''
Required columns not found: ${missingColumns.join(', ')}
Found columns: ${foundColumns.join(', ')}
Please make sure your file contains all required columns.
Headers can be in Arabic or English.''');
    }

    return columnIndices;
  }

  Future<void> pickFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
    );

    if (result != null) {
      String? filePath = result.files.single.path;
      if (filePath != null) {
        _isUploading = true;
        _showProgressOverlay(context);

        try {
          if (filePath.endsWith('.csv')) {
            await _processCSV(filePath, context);
          } else if (filePath.endsWith('.xlsx')) {
            await _processExcel(filePath, context);
          }
        } finally {
          _isUploading = false;
          if (_overlayEntry != null) {
            _overlayEntry?.remove();
            _overlayEntry = null;
          }
          _showResultDialog(context);
        }
      }
    }
  }

  void _showResultDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Upload Complete'),
          content: Text('Students have been successfully uploaded.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _processCSV(String filePath, BuildContext context) async {
    try {
      _isCancelled = false;
      final File file = File(filePath);
      final String contents = await file.readAsString();
      List<List<dynamic>> rows = const CsvToListConverter().convert(contents);

      if (rows.isEmpty) {
        throw Exception('File is empty');
      }

      final columnIndices = _identifyColumns(rows[0]);
      
      
      await _initializeCache();
      
      
      _progressText.value = 'Preparing data...';
      List<Map<String, dynamic>> preparedRows = await _prepareRowsFromCSV(filePath, columnIndices);
      
      
      var (processedRows, skippedDuplicates) = await _processRowsInChunks(preparedRows, 500);
      
      _showResultMessage(context, processedRows, skippedDuplicates, _isCancelled);
    } catch (e) {
      _showErrorMessage(context, 'Error processing CSV: $e');
    }
  }

  Future<void> _processExcel(String filePath, BuildContext context) async {
    try {
      _isCancelled = false;
      final File file = File(filePath);
      final bytes = await file.readAsBytes();
      final Excel excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        throw Exception('File is empty');
      }

      var firstSheet = excel.tables.values.first;
      if (firstSheet.rows.isEmpty) {
        throw Exception('File is empty');
      }

      final columnIndices = _identifyColumns(
        firstSheet.rows[0].map((cell) => cell?.value.toString() ?? "").toList()
      );

      
      await _initializeCache();
      
      
      _progressText.value = 'Preparing data...';
      List<Map<String, dynamic>> preparedRows = await _prepareRowsFromExcel(filePath, excel, columnIndices);
      
      
      var (processedRows, skippedDuplicates) = await _processRowsInChunks(preparedRows, 500);
      
      _showResultMessage(context, processedRows, skippedDuplicates, _isCancelled);
    } catch (e) {
      _showErrorMessage(context, 'Error processing Excel: $e');
    }
  }

  Future<void> _showCancelConfirmation(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cancel Upload?'),
          content: Text('Are you sure you want to stop the upload process? Progress up to this point will be saved.'),
          actions: [
            TextButton(
              child: Text('No, Continue'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text('Yes, Stop'),
              onPressed: () {
                _isCancelled = true;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showResultMessage(BuildContext context, int processedRows, int skippedDuplicates, bool wasCancelled) {
    String message = wasCancelled 
        ? 'Upload stopped. Progress saved:\n'
        : 'Upload complete:\n';
    message += 'Successfully added $processedRows students';
    if (skippedDuplicates > 0) {
      message += '\nSkipped $skippedDuplicates duplicate${skippedDuplicates != 1 ? 's' : ''}';
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(wasCancelled ? 'Upload Stopped' : 'Upload Complete'),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorMessage(BuildContext context, String message) {
    _isUploading = false;
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
