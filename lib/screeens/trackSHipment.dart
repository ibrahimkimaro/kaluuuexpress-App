import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaluu_Epreess_Cargo/auths/api_service.dart';
import 'package:intl/intl.dart';

class TrackingShipment extends StatefulWidget {
  const TrackingShipment({super.key});

  @override
  State<TrackingShipment> createState() => _TrackingShipmentState();
}

class _TrackingShipmentState extends State<TrackingShipment> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _shipments = [];

  @override
  void initState() {
    super.initState();
    _fetchShipments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Format date to show only day, month, and year
  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _fetchShipments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService().getShipments();
      if (!mounted) return;

      if (response.isSuccess && response.data != null) {
        setState(() {
          _shipments = response.data as List<dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Failed to load shipments';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Connection error: $e';
        _isLoading = false;
      });
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'intransit':
      case 'in_transit':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'intransit':
      case 'in_transit':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  String getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'intransit':
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      default:
        return status;
    }
  }

  double getRouteProgress(dynamic shipment) {
    // Try to get route_progress from API
    if (shipment['route_progress'] != null) {
      final progress = shipment['route_progress'];
      if (progress is num) {
        return progress.toDouble();
      } else if (progress is String) {
        return double.tryParse(progress) ?? 0.0;
      }
    }

    // Fallback to calculating from current_route_stage
    final stage = shipment['current_route_stage'] ?? '';
    const stages = ['china', 'ethiopia', 'zanzibar', 'dar_es_salaam'];
    int index = stages.indexOf(stage);
    if (index == -1) return 0.0;
    return (index + 1) / stages.length;
  }

  void _showShipmentDetails(Map<String, dynamic> shipment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShipmentDetailsSheet(shipment: shipment),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final filteredShipments =
        _shipments.where((shipment) {
          if (_selectedFilter != 'all' &&
              shipment['status'] != _selectedFilter) {
            return false;
          }
          if (_searchController.text.isNotEmpty) {
            return shipment['tracking_code'].toString().toLowerCase().contains(
              _searchController.text.toLowerCase(),
            );
          }
          return true;
        }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Track Shipments',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  isDark
                      ? [colorScheme.primary, colorScheme.primaryContainer]
                      : [const Color(0xFF0EA5E9), const Color(0xFF0284C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              )
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchShipments,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Search and Filter Section
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors:
                            isDark
                                ? [
                                  colorScheme.primary,
                                  colorScheme.primaryContainer,
                                ]
                                : [
                                  const Color(0xFF0EA5E9),
                                  const Color(0xFF0284C7),
                                ],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                    child: Column(
                      children: [
                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) => setState(() {}),
                            style: TextStyle(color: colorScheme.onSurface),
                            decoration: InputDecoration(
                              hintText: 'Search by tracking code...',
                              hintStyle: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.5),
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: colorScheme.primary,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 15,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        // Status Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip(context, 'All', 'all'),
                              _buildFilterChip(context, 'Pending', 'pending'),
                              _buildFilterChip(
                                context,
                                'In Transit',
                                'intransit',
                              ),
                              _buildFilterChip(
                                context,
                                'Delivered',
                                'delivered',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Shipments List
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _fetchShipments,
                      color: colorScheme.primary,
                      child:
                          filteredShipments.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inbox_outlined,
                                      size: 80,
                                      color: colorScheme.onSurface.withOpacity(
                                        0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No shipments found',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: colorScheme.onSurface
                                            .withOpacity(0.6),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : ListView.builder(
                                padding: const EdgeInsets.all(20),
                                itemCount: filteredShipments.length,
                                itemBuilder: (context, index) {
                                  final shipment = filteredShipments[index];
                                  return _buildShipmentCard(context, shipment);
                                },
                              ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.black38,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
        backgroundColor: Colors.white.withOpacity(0.2),
        selectedColor: Colors.black.withOpacity(0.3),
        checkmarkColor: Colors.blue,
        side: BorderSide(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
          width: 2,
        ),
      ),
    );
  }

  Widget _buildShipmentCard(
    BuildContext context,
    Map<String, dynamic> shipment,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showShipmentDetails(shipment),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tracking Code
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.qr_code,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            shipment['tracking_code'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: getStatusColor(
                          shipment['status'],
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: getStatusColor(
                            shipment['status'],
                          ).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            getStatusIcon(shipment['status']),
                            size: 14,
                            color: getStatusColor(shipment['status']),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            shipment['status_display'] ??
                                getStatusLabel(shipment['status']),
                            style: TextStyle(
                              color: getStatusColor(shipment['status']),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Customer Name
                Text(
                  shipment['customer_full_name'] ??
                      shipment['customer_name'] ??
                      'N/A',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 12),

                // Route Info
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${shipment['origin'] ?? 'N/A'} → ${shipment['destination'] ?? 'N/A'}',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Date
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Registered: ${formatDate(shipment['registered_date'])}',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Route Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Route Progress',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${(getRouteProgress(shipment) * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: getRouteProgress(shipment),
                        backgroundColor: colorScheme.outlineVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          getStatusColor(shipment['status']),
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // View Details Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showShipmentDetails(shipment),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('View Details'),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Admin Notes Section
  Widget _buildAdminNotes(String adminNotes) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.note_alt,
                  color: Colors.amber,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Admin Notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withOpacity(0.2)),
            ),
            child: Text(
              adminNotes,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1F2937),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Shipment Details Bottom Sheet
class ShipmentDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> shipment;

  const ShipmentDetailsSheet({super.key, required this.shipment});

  // Format date to show only day, month, and year
  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Shipment Details',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: colorScheme.onSurface),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Tracking Code Card
                    _buildInfoCard(
                      context,
                      icon: Icons.qr_code_2,
                      iconColor: colorScheme.primary,
                      title: 'Tracking Code',
                      value: shipment['tracking_code'],
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(text: shipment['tracking_code']),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Tracking code copied!'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: colorScheme.primary,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Customer Info Card
                    _buildInfoCard(
                      context,
                      icon: Icons.person,
                      iconColor: Colors.blue,
                      title: 'Customer Information',
                      children: [
                        _buildDetailRow(
                          context,
                          'Name',
                          shipment['customer_full_name'] ??
                              shipment['customer_name'] ??
                              'N/A',
                        ),
                        _buildDetailRow(
                          context,
                          'Email',
                          shipment['customer_email'] ?? 'N/A',
                        ),
                        _buildDetailRow(
                          context,
                          'Phone',
                          shipment['customer_phone'] ?? 'N/A',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Shipment Info Card
                    _buildInfoCard(
                      context,
                      icon: Icons.inventory_2,
                      iconColor: Colors.orange,
                      title: 'Shipment Information',
                      children: [
                        _buildDetailRow(
                          context,
                          'Origin',
                          shipment['origin'] ?? 'N/A',
                        ),
                        _buildDetailRow(
                          context,
                          'Destination',
                          shipment['destination'] ?? 'N/A',
                        ),
                        _buildDetailRow(
                          context,
                          'Weight',
                          '${shipment['weight'] ?? 'N/A'}${shipment['weight'] != null ? ' kg' : ''}',
                        ),
                        _buildDetailRow(
                          context,
                          'Registered',
                          formatDate(shipment['registered_date']),
                        ),
                        _buildDetailRow(
                          context,
                          'Est. Delivery',
                          formatDate(shipment['estimated_delivery']),
                        ),
                        if (shipment['actual_delivery_date'] != null)
                          _buildDetailRow(
                            context,
                            'Actual Delivery',
                            formatDate(shipment['actual_delivery_date']),
                          ),
                        if (shipment['description'] != null)
                          _buildDetailRow(
                            context,
                            'Description',
                            shipment['description'],
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Route Timeline
                    _buildRouteTimeline(
                      context,
                      shipment['current_route_stage'] ?? '',
                      shipment['current_route_stage_display'],
                    ),

                    // Status Updates (if available)
                    if (shipment['status_updates'] != null &&
                        (shipment['status_updates'] as List).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildStatusUpdates(
                        context,
                        shipment['status_updates'] as List,
                      ),
                    ],

                    // Admin Notes (if available)
                    if (shipment['admin_notes'] != null &&
                        shipment['admin_notes'].toString().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildAdminNotes(context, shipment['admin_notes']),
                    ],

                    const SizedBox(height: 24),

                    // Close Button
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? value,
    List<Widget>? children,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: iconColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.content_copy,
                        size: 18,
                        color: colorScheme.onSurface.withOpacity(0.4),
                      ),
                  ],
                ),
                if (value != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                ],
                if (children != null) ...[
                  const SizedBox(height: 12),
                  ...children,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteTimeline(
    BuildContext context,
    String currentStage,
    String? currentStageDisplay,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final stages = [
      {'id': 'china', 'name': 'China', 'icon': Icons.flight_takeoff},
      {'id': 'ethiopia', 'name': 'Ethiopia', 'icon': Icons.connecting_airports},
      {'id': 'zanzibar', 'name': 'Zanzibar', 'icon': Icons.airport_shuttle},
      {
        'id': 'dar_es_salaam',
        'name': 'Dar es Salaam',
        'icon': Icons.flight_land,
      },
    ];

    int currentIndex = stages.indexWhere((s) => s['id'] == currentStage);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary.withOpacity(0.1), theme.cardColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.route, color: colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Shipping Route',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...List.generate(stages.length, (index) {
            final stage = stages[index];
            final isActive = index <= currentIndex;
            final isCurrent = index == currentIndex;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            isActive
                                ? colorScheme.primary
                                : colorScheme.outlineVariant,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCurrent ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow:
                            isCurrent
                                ? [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                                : null,
                      ),
                      child: Icon(
                        stage['icon'] as IconData,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    if (index < stages.length - 1)
                      Container(
                        width: 2,
                        height: 40,
                        color:
                            isActive
                                ? colorScheme.primary
                                : colorScheme.outlineVariant,
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stage['name'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                isActive
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                        if (isCurrent && currentStageDisplay != null)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              currentStageDisplay,
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatusUpdates(BuildContext context, List updates) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.update, color: Colors.purple, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Status Updates',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...updates.map((update) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.purple,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          update['message'] ?? update.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (update['timestamp'] != null)
                          Text(
                            update['timestamp'],
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Admin Notes Section
  Widget _buildAdminNotes(BuildContext context, String adminNotes) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.note_alt,
                  color: Colors.amber,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Admin Notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withOpacity(0.2)),
            ),
            child: Text(
              adminNotes,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
