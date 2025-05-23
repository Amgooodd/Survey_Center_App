import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

class SurveyExporter {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> exportSurveyResponses(String surveyId) async {
    xlsio.Workbook? workbook;
    try {
      
      final surveyDoc = await _firestore.collection('surveys').doc(surveyId).get();
      if (!surveyDoc.exists) {
        throw Exception('Survey not found');
      }

      final surveyData = surveyDoc.data()!;
      final surveyName = surveyData['name']?.toString() ?? 'Unnamed_Survey';
      final safeFileName = _sanitizeFileName(surveyName);
      final questions = List<Map<String, dynamic>>.from(surveyData['questions'] ?? []);
      final questionTitles = questions.map((q) => q['title'].toString()).toList();

      
      final responsesSnapshot = await _firestore
          .collection('students_responses')
          .where('surveyId', isEqualTo: surveyId)
          .get();

      
      workbook = xlsio.Workbook();
      final sheet = workbook.worksheets[0];
      sheet.name = 'Survey Responses';

      
      final headers = [
        'Student ID',
        'Student Name',
        'Student Group',
        ...questionTitles
      ];
      _addSurveyHeader(sheet, surveyName, responsesSnapshot.size, headers);

      
      sheet.setColumnWidthInPixels(1, 120); 
      sheet.setColumnWidthInPixels(2, 150); 
      sheet.setColumnWidthInPixels(3, 100); 
      for (int i = 0; i < questionTitles.length; i++) {
        sheet.setColumnWidthInPixels(4 + i, 220); 
      }

      
      final xlsio.Style headerStyle = workbook.styles.add('HeaderStyle');
      headerStyle.backColor = '#4472C4';
      headerStyle.fontColor = '#FFFFFF';
      headerStyle.fontName = 'Calibri';
      headerStyle.fontSize = 12;
      headerStyle.bold = true;
      headerStyle.hAlign = xlsio.HAlignType.center;
      headerStyle.vAlign = xlsio.VAlignType.center;
      headerStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
      headerStyle.borders.all.color = '#FFFFFF';

      sheet.importList(headers, 4, 1, false);
      sheet.getRangeByName('A4:${_getExcelColumnName(headers.length)}4').cellStyle = headerStyle;

      
      int rowIndex = 5;
      for (var doc in responsesSnapshot.docs) {
        final data = doc.data();
        final studentId = data['studentId'].toString();

        final studentDoc = await _firestore.collection('students').doc(studentId).get();
        final studentData = studentDoc.data() ?? {};
        final studentName = studentData['name']?.toString() ?? 'Unknown';
        final studentGroup = studentData['group']?.toString() ?? 'Unknown';

        final answers = Map<String, dynamic>.from(data['answers'] ?? {});
        final row = [
          studentId,
          studentName,
          studentGroup,
          ...questionTitles.map((q) => answers[q]?.toString() ?? 'N/A')
        ];

        sheet.importList(row, rowIndex, 1, false);

        
        final xlsio.Style rowStyle = workbook.styles.add('RowStyle$rowIndex');
        rowStyle.fontName = 'Calibri';
        rowStyle.fontSize = 11;
        rowStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
        rowStyle.borders.all.color = '#BFBFBF';
        rowStyle.backColor = rowIndex % 2 == 0 ? '#D9E1F2' : '#FFFFFF';
        
        final rowRange = sheet.getRangeByName('A$rowIndex:${_getExcelColumnName(headers.length)}$rowIndex');
        rowRange.cellStyle = rowStyle;

        
        for (int col = 1; col <= headers.length; col++) {
          final cell = sheet.getRangeByIndex(rowIndex, col);
          cell.cellStyle.vAlign = xlsio.VAlignType.top; 
          cell.cellStyle.wrapText = true; 
          
          
          if (col >= 4) {
            cell.cellStyle.hAlign = xlsio.HAlignType.center;
          } else if (col == 1 || col == 3) { 
            cell.cellStyle.hAlign = xlsio.HAlignType.center;
          } else {
            cell.cellStyle.hAlign = xlsio.HAlignType.left;
          }
        }
        rowIndex++;
      }

      
      final filterRange = sheet.getRangeByName('A4:${_getExcelColumnName(headers.length)}4');
      sheet.autoFilters.addFilter(0, filterRange);
      sheet.setFreezePanes(5, 1);

      
      sheet.pageSetup.orientation = xlsio.ExcelPageOrientation.landscape;
      sheet.pageSetup.fitToPagesWide = 1;
      sheet.pageSetup.fitToPagesTall = 0;
      sheet.pageSetup.topMargin = 0.5;
sheet.pageSetup.bottomMargin = 0.5;
sheet.pageSetup.leftMargin = 0.3;
sheet.pageSetup.rightMargin = 0.3;
      
      if (headers.isNotEmpty) {
        final lastColumn = _getExcelColumnName(headers.length);
        sheet.pageSetup.printTitleRows = '\$A\$4:\$${lastColumn}\$4';
      }

      
      final directoryPath = await FilePicker.platform.getDirectoryPath();
      final savePath = directoryPath != null 
          ? '$directoryPath/$safeFileName.xlsx' 
          : '${(await getExternalStorageDirectory())!.path}/$safeFileName.xlsx';
      
      final file = File(savePath);
      final bytes = workbook.saveAsStream();
      await file.writeAsBytes(bytes, flush: true);
      print('✅ Excel file saved: ${file.path}');
      
    } catch (e) {
      print('❌ Export error: $e');
      rethrow;
    } finally {
      workbook?.dispose();
    }
  }

  void _addSurveyHeader(
    xlsio.Worksheet sheet,
    String surveyName,
    int responseCount,
    List<String> headers
  ) {
    final lastColumn = _getExcelColumnName(headers.length);

    void formatHeaderRow(xlsio.Range range, String text, [int fontSize = 16]) {
      range.merge();
      range.setText(text);
      range.cellStyle.bold = true;
      range.cellStyle.vAlign = xlsio.VAlignType.center;
      range.cellStyle.hAlign = xlsio.HAlignType.center;
    }

        formatHeaderRow(sheet.getRangeByName('A1:${lastColumn}1'), 'SURVEY RESPONSE REPORT', 30);
        formatHeaderRow(sheet.getRangeByName('A2:${lastColumn}2'), 'Survey: $surveyName', 18);
        
        final dateRange = sheet.getRangeByName('A3:${lastColumn}3');
        dateRange.merge();
        dateRange.setText('Total Responses: $responseCount | Generated on: ${DateTime.now()}');
        dateRange.cellStyle.italic = true;
        dateRange.cellStyle.fontSize = 12;
        dateRange.cellStyle.hAlign = xlsio.HAlignType.center;
        dateRange.cellStyle.vAlign = xlsio.VAlignType.center;
      }

  String _sanitizeFileName(String name) => 
    name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');

  String _getExcelColumnName(int columnNumber) {
    String columnName = '';
    while (columnNumber > 0) {
      int modulo = (columnNumber - 1) % 26;
      columnName = String.fromCharCode('A'.codeUnitAt(0) + modulo) + columnName;
      columnNumber = (columnNumber - modulo) ~/ 26;
    }
    return columnName;
  }
}

extension on xlsio.AutoFilterCollection {
  void addFilter(int i, xlsio.Range filterRange) {}
}

extension on xlsio.Worksheet {
  void setFreezePanes(int i, int j) {}
}