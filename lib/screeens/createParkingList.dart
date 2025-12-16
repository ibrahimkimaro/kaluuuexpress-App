// pubspec.yaml - Add these dependencies:
/*
dependencies:
  pdf: ^3.10.7
  printing: ^5.12.0
  path_provider: ^2.1.1
  open_file: ^3.3.2
*/

// create_packing_list.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:kaluu_Epreess_Cargo/auths/api_service.dart';

class CreatePackingListPage extends StatefulWidget {
  const CreatePackingListPage({super.key});

  @override
  State<CreatePackingListPage> createState() => _CreatePackingListPageState();
}

class _CreatePackingListPageState extends State<CreatePackingListPage> {
  static const Color skyBlue = Color(0xFF4A90E2);
  static const Color lightSkyBlue = Color(0xFF87CEEB);
  static const Color deepSkyBlue = Color(0xFF2E73B8);

  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  final List<PackingBox> _boxes = [];
  bool _isGenerating = false;
  File? _generatedPdf;

  @override
  void initState() {
    super.initState();
    _addBox();
  }

  void _addBox() {
    setState(() {
      final box = PackingBox();
      box.items.add(PackingItem());
      _boxes.add(box);
    });
  }

  void _addItemToBox(int boxIndex) {
    setState(() {
      _boxes[boxIndex].items.add(PackingItem());
    });
  }

  void _removeBox(int index) {
    if (_boxes.length > 1) {
      setState(() {
        _boxes[index].dispose();
        _boxes.removeAt(index);
      });
    }
  }

  void _removeItemFromBox(int boxIndex, int itemIndex) {
    if (_boxes[boxIndex].items.length > 1) {
      setState(() {
        _boxes[boxIndex].items[itemIndex].dispose();
        _boxes[boxIndex].items.removeAt(itemIndex);
      });
    }
  }

  double _calculateTotalWeight() {
    return _boxes.fold(0.0, (sum, box) {
      return sum +
          box.items.fold(0.0, (boxSum, item) {
            final weight = double.tryParse(item.weightController.text) ?? 0.0;
            return boxSum + weight;
          });
    });
  }

  int _calculateTotalItems() {
    return _boxes.fold(0, (sum, box) => sum + box.items.length);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: skyBlue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _generateAndPreviewPDF() async {
    if (!_formKey.currentState!.validate()) {
      Fluttertoast.showToast(
        msg: 'Please fill all required fields',
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      // Generate PDF
      final pdf = await _createPDF();

      // Save to temporary file
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/packing_list_preview.pdf');
      await file.writeAsBytes(await pdf.save());

      setState(() {
        _generatedPdf = file;
        _isGenerating = false;
      });

      // Show preview
      _showPreviewDialog();
    } catch (e) {
      setState(() => _isGenerating = false);
      Fluttertoast.showToast(
        msg: 'Error generating PDF: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<pw.Document> _createPDF() async {
    final pdf = pw.Document();

    // Load logo (if exists)
    pw.ImageProvider? logo;
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      logo = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      print('Logo not found, continuing without it');
    }

    // Load Material Icons font
    final iconFont = await PdfGoogleFonts.materialIcons();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return [
            // Header with logo and title
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: PdfColor.fromHex('#4A90E2'),
                    width: 3,
                  ),
                ),
              ),
              padding: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Logo section
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (logo != null)
                        pw.Container(
                          width: 60,
                          height: 60,
                          child: pw.Image(logo),
                        ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'KALUU EXPRESS CARGO',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#4A90E2'),
                        ),
                      ),
                      pw.Text(
                        'Air Cargo Services',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  // Title
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'PACKING LIST',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#4A90E2'),
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#E3F2FD'),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'Date: ${_selectedDate.day.toString().padLeft(2, '0')} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#4A90E2'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Summary section
            pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F5F5F5'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              padding: const pw.EdgeInsets.all(16),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    'TOTAL ITEMS',
                    '${_calculateTotalItems()}',
                    // Icons.inventory_2_rounded.codePoint,
                    iconFont,
                  ),
                  pw.Container(height: 40, width: 2, color: PdfColors.grey400),
                  _buildSummaryItem(
                    'TOTAL WEIGHT',
                    '${_calculateTotalWeight().toStringAsFixed(1)} KG',
                    // Icons.scale_rounded.codePoint,
                    iconFont,
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 25),

            // Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(40),
                1: const pw.FixedColumnWidth(60),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(2),
                5: const pw.FixedColumnWidth(60),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#4A90E2'),
                  ),
                  children: [
                    _buildHeaderCell('NO'),
                    _buildHeaderCell('CODE'),
                    _buildHeaderCell('CLIENT NAME'),
                    _buildHeaderCell('CONTACT'),
                    _buildHeaderCell('DESCRIPTION'),
                    _buildHeaderCell('WEIGHT\n(KG)'),
                  ],
                ),
                // Data rows
                ..._boxes.asMap().entries.expand((boxEntry) {
                  final boxIndex = boxEntry.key;
                  final box = boxEntry.value;
                  return box.items.asMap().entries.map((itemEntry) {
                    final itemIndex = itemEntry.key;
                    final item = itemEntry.value;
                    return _buildDataRow(
                      boxIndex + 1,
                      box,
                      item,
                      itemIndex == 0, // Show code only for first item
                      boxIndex % 2 == 0,
                    );
                  });
                }),
              ],
            ),

            pw.SizedBox(height: 20),

            // Footer
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: PdfColors.grey400, width: 1),
                ),
              ),
              padding: const pw.EdgeInsets.only(top: 15),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Contact Information:',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Email: Kaluuexpressaircargo@gmail.com',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        'Phone: +255 759 420 034',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Generated by Kaluu Express App',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey600,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                      pw.Text(
                        DateTime.now().toString().split('.')[0],
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildSummaryItem(
    String label,
    String value,
    // int iconCode,
    pw.Font iconFont,
  ) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        // pw.Text(
        //   String.fromCharCode(iconCode),
        //   style: pw.TextStyle(
        //     fontSize: 20,
        //     color: PdfColor.fromHex('#4A90E2'),
        //     font: iconFont,
        //   ),
        // ),
        pw.SizedBox(width: 10),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey700,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#4A90E2'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.TableRow _buildDataRow(
    int boxNumber,
    PackingBox box,
    PackingItem item,
    bool isFirstItem,
    bool isEven,
  ) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: isEven ? PdfColors.white : PdfColor.fromHex('#F9F9F9'),
      ),
      children: [
        _buildDataCell(
          isFirstItem ? boxNumber.toString() : '',
          alignment: pw.Alignment.center,
        ),
        _buildDataCell(
          isFirstItem ? box.codeController.text : '',
          alignment: pw.Alignment.center,
          bold: true,
        ),
        _buildDataCell(item.clientController.text),
        _buildDataCell(
          item.contactController.text.isEmpty
              ? 'NO COPY'
              : item.contactController.text,
          fontSize: 8,
        ),
        _buildDataCell(item.descriptionController.text),
        _buildDataCell(
          item.weightController.text,
          alignment: pw.Alignment.centerRight,
          bold: true,
        ),
      ],
    );
  }

  pw.Widget _buildDataCell(
    String text, {
    pw.Alignment alignment = pw.Alignment.centerLeft,
    bool bold = false,
    double fontSize = 9,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      alignment: alignment,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.grey900,
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[month - 1];
  }

  void _showPreviewDialog() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(10),
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [lightSkyBlue, skyBlue]),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.preview, color: Colors.white),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'PDF Preview',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // PDF Viewer
                  Expanded(
                    child:
                        _generatedPdf != null
                            ? PdfPreview(
                              build: (format) => _generatedPdf!.readAsBytes(),
                              canChangePageFormat: false,
                              canChangeOrientation: false,
                              canDebug: false,
                              allowSharing: false,
                              allowPrinting: false,
                            )
                            : const Center(child: CircularProgressIndicator()),
                  ),

                  // Action buttons
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // Go back to edit
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: skyBlue),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.edit, color: skyBlue),
                            label: const Text(
                              'Edit',
                              style: TextStyle(
                                color: skyBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [lightSkyBlue, skyBlue, deepSkyBlue],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _uploadToServer();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(
                                Icons.cloud_upload,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Upload',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _uploadToServer() async {
    if (_generatedPdf == null) return;

    setState(() => _isGenerating = true);

    try {
      final apiService = ApiService();
      await apiService.init();

      final fields = {
        'date': _selectedDate.toIso8601String().split('T')[0],
        'total_cartons': _boxes.length.toString(),
        'total_weight': _calculateTotalWeight().toString(),
      };

      final files = [
        await http.MultipartFile.fromPath(
          'pdf_file',
          _generatedPdf!.path,
          filename: 'packing_list.pdf',
        ),
      ];

      final response = await apiService.postMultipart(
        '/api/shipping/packing-lists/',
        fields: fields,
        files: files,
      );

      if (mounted) {
        setState(() => _isGenerating = false);

        if (response.isSuccess) {
          Fluttertoast.showToast(
            msg: 'Packing list uploaded successfully!',
            backgroundColor: Colors.green,
          );
          Navigator.pop(context, true);
        } else {
          Fluttertoast.showToast(
            msg: 'Failed to upload: ${response.error ?? response.message}',
            backgroundColor: Colors.red,
            toastLength: Toast.LENGTH_LONG,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        Fluttertoast.showToast(
          msg: 'Upload error: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: skyBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Packing List',
          style: TextStyle(color: skyBlue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Header with date and totals
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [lightSkyBlue, skyBlue]),
                boxShadow: [
                  BoxShadow(
                    color: skyBlue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Total Items',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_calculateTotalItems()}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Total Weight',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_calculateTotalWeight().toStringAsFixed(1)} KG',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Items list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _boxes.length,
                itemBuilder: (context, index) {
                  return _buildBoxCard(index);
                },
              ),
            ),

            // Bottom buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addBox,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: skyBlue),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add, color: skyBlue),
                      label: const Text(
                        'Add Box',
                        style: TextStyle(
                          color: skyBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [lightSkyBlue, skyBlue, deepSkyBlue],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: skyBlue.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed:
                            _isGenerating ? null : _generateAndPreviewPDF,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon:
                            _isGenerating
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Icon(
                                  Icons.preview,
                                  color: Colors.white,
                                ),
                        label: Text(
                          _isGenerating ? 'Generating...' : 'Preview PDF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoxCard(int boxIndex) {
    final box = _boxes[boxIndex];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: skyBlue.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [lightSkyBlue, skyBlue],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Box ${boxIndex + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              if (_boxes.length > 1)
                IconButton(
                  onPressed: () => _removeBox(boxIndex),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Code field (Manual Entry)
          TextFormField(
            controller: box.codeController,
            decoration: InputDecoration(
              labelText: 'Box Code',
              labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: const Icon(Icons.qr_code, color: skyBlue, size: 20),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: skyBlue, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Items List
          ...box.items.asMap().entries.map((entry) {
            return _buildItemRow(boxIndex, entry.key, entry.value);
          }),

          // Add Item Button
          Center(
            child: TextButton.icon(
              onPressed: () => _addItemToBox(boxIndex),
              icon: const Icon(Icons.add_circle_outline, color: skyBlue),
              label: const Text(
                'Add Item to Box',
                style: TextStyle(color: skyBlue, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(int boxIndex, int itemIndex, PackingItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Item ${itemIndex + 1}',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (_boxes[boxIndex].items.length > 1)
                InkWell(
                  onTap: () => _removeItemFromBox(boxIndex, itemIndex),
                  child: const Icon(Icons.close, size: 18, color: Colors.red),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Client Name
          TextFormField(
            controller: item.clientController,
            decoration: InputDecoration(
              labelText: 'Client Name',
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 11),

          // Contact
          TextFormField(
            controller: item.contactController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Contact',
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
              if (digitsOnly.length < 7 || digitsOnly.length > 10)
                return 'Invalid phone number must be 10 digts';
              return null;
            },
          ),
          const SizedBox(height: 11),

          // Description
          TextFormField(
            controller: item.descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 11),

          // Weight
          TextFormField(
            controller: item.weightController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Weight (KG)',
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              if (double.tryParse(value) == null) return 'Invalid';
              return null;
            },
          ),
        ],
      ),
    );
  }
}

// PackingItem class definition (missing from original code)
class PackingBox {
  final TextEditingController codeController;
  final List<PackingItem> items;

  PackingBox({String? code})
    : codeController = TextEditingController(text: code ?? ''),
      items = [];

  void dispose() {
    codeController.dispose();
    for (var item in items) {
      item.dispose();
    }
  }
}

class PackingItem {
  final TextEditingController clientController;
  final TextEditingController contactController;
  final TextEditingController descriptionController;
  final TextEditingController weightController;

  PackingItem()
    : clientController = TextEditingController(),
      contactController = TextEditingController(),
      descriptionController = TextEditingController(),
      weightController = TextEditingController();

  void dispose() {
    clientController.dispose();
    contactController.dispose();
    descriptionController.dispose();
    weightController.dispose();
  }
}
