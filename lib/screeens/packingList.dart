// packing_list.dart - Main Packing List Page

import 'package:flutter/material.dart';
import 'package:kaluu_Epreess_Cargo/screeens/createParkingList.dart';
import 'package:provider/provider.dart';
import 'package:kaluu_Epreess_Cargo/auths/auth_controller.dart';
import 'package:kaluu_Epreess_Cargo/auths/api_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:open_file/open_file.dart'; // New import for opening files
import 'package:path_provider/path_provider.dart'; // New import for temporary directory
import 'dart:io'; // New import for File operations
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;

class PackingListPage extends StatefulWidget {
  const PackingListPage({super.key});

  @override
  State<PackingListPage> createState() => _PackingListPageState();
}

class _PackingListPageState extends State<PackingListPage> {
  static const Color skyBlue = Color(0xFF4A90E2);
  static const Color lightSkyBlue = Color(0xFF87CEEB);
  static const Color deepSkyBlue = Color(0xFF2E73B8);
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _packingLists = [];
  bool _isLoading = true;
  bool _isStaff = false;

  @override
  void initState() {
    super.initState();
    _checkStaffStatus();
    _loadPackingLists();
  }

  void _checkStaffStatus() {
    final authController = Provider.of<AuthController>(context, listen: false);
    // Check if user is staff from userData
    _isStaff = authController.userData?['full_name'] == "ibrahim kimaro";
  }

  Future<void> _loadPackingLists() async {
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.get('/api/shipping/packing-lists/');

      if (response.isSuccess && response.data != null) {
        setState(() {
          _packingLists = List<Map<String, dynamic>>.from(response.data);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(
          msg: 'Failed to load packing lists',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: 'Error: $e', backgroundColor: Colors.red);
    }
  }

  Future<void> _downloadPDF(int id, String code) async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.downloadPackingList(id);

      if (response.isSuccess && response.data != null) {
        // Get temporary directory
        final output = await getTemporaryDirectory();
        final file = File('${output.path}/packing_list_${code}.pdf');

        // Write bytes to file
        await file.writeAsBytes(response.data as List<int>);

        // Open file
        final result = await OpenFile.open(file.path);

        if (result.type != ResultType.done) {
          Fluttertoast.showToast(
            msg: 'Could not open PDF: ${result.message}',
            backgroundColor: Colors.red,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: 'Failed to download PDF: ${response.error ?? "Unknown error"}',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error downloading PDF: $e',
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() => _isLoading = false);
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
          'Packing Lists',
          style: TextStyle(color: skyBlue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadPackingLists,
                child:
                    _packingLists.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _packingLists.length,
                          itemBuilder: (context, index) {
                            return _buildPackingListCard(_packingLists[index]);
                          },
                        ),
              ),
      floatingActionButton:
          _isStaff
              ? FloatingActionButton.extended(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreatePackingListPage(),
                    ),
                  );
                  if (result == true) {
                    _loadPackingLists();
                  }
                },
                backgroundColor: skyBlue,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Create List',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
              : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No packing lists yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_isStaff) ...[
            const SizedBox(height: 8),
            Text(
              'Tap the button below to create one',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPackingListCard(Map<String, dynamic> packingList) {
    final code = packingList['code'] ?? '';
    final date = packingList['date'] ?? '';
    final totalCartons = packingList['total_cartons'] ?? 0;
    final totalWeight = packingList['total_weight'] ?? 0;
    final status = packingList['status'] ?? 'draft';
    final createdBy = packingList['created_by_name'] ?? 'Unknown';
    final hasPdf = packingList['pdf_file'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Show details dialog
            _showDetailsDialog(packingList);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [lightSkyBlue, skyBlue],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            code,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: skyBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                date,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            status == 'finalized'
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status == 'finalized' ? 'Finalized' : 'Draft',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color:
                              status == 'finalized'
                                  ? Colors.green
                                  : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        Icons.inbox_rounded,
                        'Cartons',
                        totalCartons.toString(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoChip(
                        Icons.scale_rounded,
                        'Weight',
                        '$totalWeight KG',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Created by: $createdBy',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (hasPdf) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadPDF(packingList['id'], code),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: skyBlue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(
                        Icons.download_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Text(
                        'Download PDF',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: skyBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: skyBlue.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: skyBlue),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: skyBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(Map<String, dynamic> packingList) {
    final items = List<Map<String, dynamic>>.from(packingList['items'] ?? []);

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 600),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [lightSkyBlue, skyBlue],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.inventory_2_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          packingList['code'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: skyBlue,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child:
                        items.isEmpty
                            ? const Center(child: Text('No items'))
                            : ListView.builder(
                              shrinkWrap: true,
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: skyBlue,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              item['item_code'] ?? '',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              item['client_name'] ?? '',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${item['weight']} KG',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: skyBlue,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item['item_description'] ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
