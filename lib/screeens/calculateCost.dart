import 'package:flutter/material.dart';
import 'package:kaluu_bozen_cargo/auths/api_service.dart';

class Calculator extends StatefulWidget {
  const Calculator({super.key});

  @override
  State<Calculator> createState() => _CalculatorState();
}

class BlueSkyColors {
  static const Color skyBlue = Color(0xFF4A90E2);
  static const Color lightSkyBlue = Color(0xFF87CEEB);
  static const Color deepSkyBlue = Color(0xFF2E73B8);
}

class _CalculatorState extends State<Calculator>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();

  String? _selectedServiceTier;
  String? _selectedWeightHandling;
  double _calculatedCost = 0.0;
  bool _showResult = false;
  bool _isLoading = true;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  List<dynamic> _serviceTiers = [];
  List<dynamic> _weightHandling = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _fetchShippingConfig();
  }

  Future<void> _fetchShippingConfig() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService().getShippingConfig();
      if (response.isSuccess && response.data != null) {
        setState(() {
          _serviceTiers = response.data!['service_tiers'] ?? [];
          _weightHandling = response.data!['weight_handling'] ?? [];

          // Set defaults
          if (_serviceTiers.isNotEmpty) {
            _selectedServiceTier = _serviceTiers[0]['name'];
          }
          if (_weightHandling.isNotEmpty) {
            _selectedWeightHandling = _weightHandling[0]['name'];
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Failed to load configuration';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _calculateCost() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        double weight = double.parse(_weightController.text);

        // Find selected rates
        final tier = _serviceTiers.firstWhere(
          (t) => t['name'] == _selectedServiceTier,
          orElse: () => {'price_per_kg_usd': 0.0},
        );
        final handling = _weightHandling.firstWhere(
          (h) => h['name'] == _selectedWeightHandling,
          orElse: () => {'rate_tsh_per_kg': 0.0},
        );

        double baseRate = (tier['price_per_kg_usd'] as num).toDouble();
        double exchangeRate = (handling['rate_tsh_per_kg'] as num).toDouble();

        // Formula: (Shipment kg weight) × (Exchange rate per kg) × (Base rate per kg) = Total cost
        _calculatedCost = weight * exchangeRate * baseRate;
        _showResult = true;
        _animationController.forward(from: 0);
      });
    }
  }

  void _resetCalculator() {
    setState(() {
      _weightController.clear();
      if (_serviceTiers.isNotEmpty) {
        _selectedServiceTier = _serviceTiers[0]['name'];
      }
      if (_weightHandling.isNotEmpty) {
        _selectedWeightHandling = _weightHandling[0]['name'];
      }
      _calculatedCost = 0.0;
      _showResult = false;
    });
  }

  // Blue sky color scheme
  static const Color skyBlue = Color(0xFF4A90E2);
  static const Color lightSkyBlue = Color(0xFF87CEEB);
  static const Color deepSkyBlue = Color(0xFF2E73B8);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Calculate Shipping Cost',
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomRight,
              colors: [
                // BlueSkyColors.skyBlue,
                BlueSkyColors.deepSkyBlue,
                BlueSkyColors.lightSkyBlue,
              ],
            ),
          ),
        ),
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
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
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: colorScheme.error),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchShippingConfig,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  children: [
                    // Header section with gradient
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors:
                              isDark
                                  ? [
                                    colorScheme.primary,
                                    colorScheme.primaryContainer,
                                  ]
                                  : [
                                    const Color(0xFF87CEEB), // lightSkyBlue
                                    const Color(0xFF4A90E2), // skyBlue
                                    const Color(0xFF2E73B8), // deepSkyBlue
                                  ],
                        ),

                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.calculate,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Get Instant Pricing',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter your shipment details below',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Form section
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Service Tier Selection
                            Text(
                              'Service Tier',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        isDark
                                            ? Colors.black.withOpacity(0.2)
                                            : Colors.black.withOpacity(0.05),
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Column(
                                children:
                                    _serviceTiers.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final tier = entry.value;
                                      final isLast =
                                          index == _serviceTiers.length - 1;

                                      return Column(
                                        children: [
                                          _buildRadioTile(
                                            context,
                                            tier['name'],
                                            tier['description'],
                                            '\$${tier['price_per_kg_usd']}/kg',
                                            _selectedServiceTier ==
                                                tier['name'],
                                            () => setState(
                                              () =>
                                                  _selectedServiceTier =
                                                      tier['name'],
                                            ),
                                          ),
                                          if (!isLast)
                                            Divider(
                                              height: 1,
                                              color: colorScheme.outlineVariant,
                                            ),
                                        ],
                                      );
                                    }).toList(),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Weight Handling Selection
                            Text(
                              'Weight Handling',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        isDark
                                            ? Colors.black.withOpacity(0.2)
                                            : Colors.black.withOpacity(0.05),
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Column(
                                children:
                                    _weightHandling.asMap().entries.map((
                                      entry,
                                    ) {
                                      final index = entry.key;
                                      final handling = entry.value;
                                      final isLast =
                                          index == _weightHandling.length - 1;

                                      return Column(
                                        children: [
                                          _buildRadioTile(
                                            context,
                                            handling['name'],
                                            handling['description'],
                                            '${(handling['rate_tsh_per_kg'] as num).toInt()} TSh/kg',
                                            _selectedWeightHandling ==
                                                handling['name'],
                                            () => setState(
                                              () =>
                                                  _selectedWeightHandling =
                                                      handling['name'],
                                            ),
                                          ),
                                          if (!isLast)
                                            Divider(
                                              height: 1,
                                              color: colorScheme.outlineVariant,
                                            ),
                                        ],
                                      );
                                    }).toList(),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Shipment Weight Input
                            Text(
                              'Shipment Weight',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        isDark
                                            ? Colors.black.withOpacity(0.2)
                                            : Colors.black.withOpacity(0.05),
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _weightController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                style: TextStyle(color: colorScheme.onSurface),
                                decoration: InputDecoration(
                                  hintText: 'Enter weight',
                                  hintStyle: TextStyle(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.5,
                                    ),
                                  ),
                                  suffixText: 'kg',
                                  suffixStyle: TextStyle(
                                    color: colorScheme.onSurface,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.scale,
                                    color: colorScheme.primary,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: theme.cardColor,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter weight';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  if (double.parse(value) <= 0) {
                                    return 'Weight must be greater than 0';
                                  }
                                  return null;
                                },
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Calculate Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _calculateCost,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.error,
                                  foregroundColor: colorScheme.onError,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 3,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.calculate),
                                    SizedBox(width: 12),
                                    Text(
                                      'CALCULATE COST',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Result Section
                            if (_showResult) ...[
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors:
                                          isDark
                                              ? [
                                                colorScheme.primary,
                                                colorScheme.primaryContainer,
                                              ]
                                              : [
                                                const Color(0xFF1565C0),
                                                const Color(0xFF0D47A1),
                                              ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary.withOpacity(
                                          0.3,
                                        ),
                                        spreadRadius: 2,
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 50,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Estimated Total Cost',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'TSh ${_calculatedCost.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            _buildDetailRow(
                                              'Service Tier',
                                              _selectedServiceTier ?? '',
                                            ),
                                            const SizedBox(height: 8),
                                            _buildDetailRow(
                                              'Weight Handling',
                                              _selectedWeightHandling ?? '',
                                            ),
                                            const SizedBox(height: 8),
                                            _buildDetailRow(
                                              'Shipment Weight',
                                              '${_weightController.text} kg',
                                            ),
                                            const SizedBox(height: 8),
                                            _buildDetailRow('Base Rate', () {
                                              final tier = _serviceTiers
                                                  .firstWhere(
                                                    (t) =>
                                                        t['name'] ==
                                                        _selectedServiceTier,
                                                    orElse:
                                                        () => {
                                                          'price_per_kg_usd': 0,
                                                        },
                                                  );
                                              return '\$${tier['price_per_kg_usd']}/kg';
                                            }()),
                                            const SizedBox(height: 8),
                                            _buildDetailRow('Exchange Rate', () {
                                              final handling = _weightHandling
                                                  .firstWhere(
                                                    (h) =>
                                                        h['name'] ==
                                                        _selectedWeightHandling,
                                                    orElse:
                                                        () => {
                                                          'rate_tsh_per_kg': 0,
                                                        },
                                                  );
                                              return '${(handling['rate_tsh_per_kg'] as num).toInt()} TSh/kg';
                                            }()),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton(
                                          onPressed: _resetCalculator,
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                          ),
                                          child: const Text(
                                            'Calculate Again',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 30),

                            // Formula Explanation
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: colorScheme.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Calculation Formula',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Total Cost = Weight (kg) × Exchange Rate (TSh/kg) × Base Rate (\$/kg)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colorScheme.onSurface.withOpacity(
                                        0.7,
                                      ),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildRadioTile(
    BuildContext context,
    String title,
    String subtitle,
    String price,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colorScheme.primary : colorScheme.outline,
                  width: 2,
                ),
              ),
              child:
                  isSelected
                      ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.primary,
                          ),
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color:
                          isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color:
                    isSelected
                        ? colorScheme.error
                        : colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
