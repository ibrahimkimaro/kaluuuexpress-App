// packing_list.dart - With Date Range Filter

import 'package:flutter/material.dart';
import 'package:kaluu_bozen_cargo/screeens/createParkingList.dart';
import 'package:provider/provider.dart';
import 'package:kaluu_bozen_cargo/auths/auth_controller.dart';
import 'package:kaluu_bozen_cargo/auths/api_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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
  List<Map<String, dynamic>> _filteredPackingLists = [];
  bool _isLoading = true;

  // Filter variables
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isFilterActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthController>(context, listen: false).fetchProfile();
    });
    _loadPackingLists();
  }

  Future<void> _loadPackingLists() async {
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.get('/api/shipping/packing-lists/');

      if (response.isSuccess && response.data != null) {
        setState(() {
          _packingLists = List<Map<String, dynamic>>.from(response.data);
          _applyFilter();
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

  void _applyFilter() {
    if (_startDate == null && _endDate == null) {
      _filteredPackingLists = List.from(_packingLists);
      _isFilterActive = false;
    } else {
      _isFilterActive = true;
      _filteredPackingLists =
          _packingLists.where((packing) {
            try {
              final dateStr = packing['date'] as String;
              final packingDate = DateTime.parse(dateStr);

              if (_startDate != null && _endDate != null) {
                return packingDate.isAfter(
                      _startDate!.subtract(const Duration(days: 1)),
                    ) &&
                    packingDate.isBefore(
                      _endDate!.add(const Duration(days: 1)),
                    );
              } else if (_startDate != null) {
                return packingDate.isAfter(
                  _startDate!.subtract(const Duration(days: 1)),
                );
              } else if (_endDate != null) {
                return packingDate.isBefore(
                  _endDate!.add(const Duration(days: 1)),
                );
              }
              return true;
            } catch (e) {
              return false;
            }
          }).toList();
    }
  }

  void _showFilterDialog() {
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                              Icons.filter_alt_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Filter by Date',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: skyBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Start Date
                      const Text(
                        'From Date',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: tempStartDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
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
                            setDialogState(() => tempStartDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: skyBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                tempStartDate != null
                                    ? '${tempStartDate!.day}/${tempStartDate!.month}/${tempStartDate!.year}'
                                    : 'Select start date',
                                style: TextStyle(
                                  fontSize: 15,
                                  color:
                                      tempStartDate != null
                                          ? Colors.black87
                                          : Colors.grey[500],
                                ),
                              ),
                              const Spacer(),
                              if (tempStartDate != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    setDialogState(() => tempStartDate = null);
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // End Date
                      const Text(
                        'To Date',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: tempEndDate ?? DateTime.now(),
                            firstDate: tempStartDate ?? DateTime(2020),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
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
                            setDialogState(() => tempEndDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: skyBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                tempEndDate != null
                                    ? '${tempEndDate!.day}/${tempEndDate!.month}/${tempEndDate!.year}'
                                    : 'Select end date',
                                style: TextStyle(
                                  fontSize: 15,
                                  color:
                                      tempEndDate != null
                                          ? Colors.black87
                                          : Colors.grey[500],
                                ),
                              ),
                              const Spacer(),
                              if (tempEndDate != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    setDialogState(() => tempEndDate = null);
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _startDate = null;
                                  _endDate = null;
                                  _applyFilter();
                                });
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.grey),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Clear',
                                style: TextStyle(
                                  color: Colors.grey,
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
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _startDate = tempStartDate;
                                    _endDate = tempEndDate;
                                    _applyFilter();
                                  });
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Apply Filter',
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
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  Future<void> _downloadPDF(int id, String code) async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.downloadPackingList(id);

      if (response.isSuccess && response.data != null) {
        final output = await getTemporaryDirectory();
        final file = File('${output.path}/packing_list_$code.pdf');
        await file.writeAsBytes(response.data as List<int>);

        final result = await OpenFile.open(file.path);
        if (result.type != ResultType.done) {
          Fluttertoast.showToast(
            msg: 'Could not open PDF: ${result.message}',
            backgroundColor: Colors.red,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: 'Failed to download PDF',
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
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_alt_rounded),
                onPressed: _showFilterDialog,
              ),
              if (_isFilterActive)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter indicator
          if (_isFilterActive)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: skyBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: skyBlue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_alt, color: skyBlue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _startDate != null && _endDate != null
                          ? 'From ${_startDate!.day}/${_startDate!.month}/${_startDate!.year} to ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                          : _startDate != null
                          ? 'From ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                          : 'Until ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: skyBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                        _applyFilter();
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: skyBlue,
                  ),
                ],
              ),
            ),

          // List
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                      onRefresh: _loadPackingLists,
                      child:
                          _filteredPackingLists.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredPackingLists.length,
                                itemBuilder: (context, index) {
                                  return _buildPackingListCard(
                                    _filteredPackingLists[index],
                                  );
                                },
                              ),
                    ),
          ),
        ],
      ),
      floatingActionButton: Consumer<AuthController>(
        builder: (context, auth, child) {
          final canCreate =
              auth.userData?['can_create_packing_list'] == true ||
              auth.userData?['is_superuser'] == true;

          if (!canCreate) return const SizedBox.shrink();

          return FloatingActionButton.extended(
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
          );
        },
      ),
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
            _isFilterActive ? 'No results found' : 'No packing lists yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_isFilterActive) ...[
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filter',
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
          onTap: hasPdf ? () => _downloadPDF(packingList['id'], code) : null,
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
}
