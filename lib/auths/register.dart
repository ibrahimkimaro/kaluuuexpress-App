import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kaluu_Epreess_Cargo/auths/auth_controller.dart';
import 'package:kaluu_Epreess_Cargo/screeens/screenNavigation.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();

  // Country -> cities mapping
  final Map<String, List<String>> _countryCities = {
    'Tanzania': ['Dar es Salaam', 'Mwanza', 'Dodoma', 'Shinyanga', 'Arusha'],
    'Congo': ['Kinshasa', 'Lubumbashi', 'Goma', 'Kisangani', 'Bukavu'],
    'Kenya': ['Nairobi', 'Mombasa', 'Kisumu', 'Nakuru', 'Eldoret'],
    'Rwanda': ['Kigali', 'Huye', 'Rubavu', 'Musanze', 'Rwamagana'],
    'Burundi': ['Bujumbura', 'Gitega', 'Ngozi', 'Muyinga', 'Ruyigi'],
  };

  // Country dialing codes for phone normalization
  final Map<String, String> _countryDialCodes = {
    'Tanzania': '+255',
    'Congo': '+243',
    'Kenya': '+254',
    'Rwanda': '+250',
    'Burundi': '+257',
  };

  // Country flags (you can use emoji or asset images)
  final Map<String, String> _countryFlags = {
    'Tanzania': '🇹🇿',
    'Congo': '🇨🇩',
    'Kenya': '🇰🇪',
    'Rwanda': '🇷🇼',
    'Burundi': '🇧🇮',
  };

  String? _selectedCountry;
  String? _selectedCity;
  String? _selectedCountryCode;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  // Blue sky color scheme
  static const Color skyBlue = Color(0xFF4A90E2);
  static const Color lightSkyBlue = Color(0xFF87CEEB);
  static const Color deepSkyBlue = Color(0xFF2E73B8);

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Set default country
    _selectedCountry = 'Tanzania';
    _selectedCountryCode = _countryDialCodes[_selectedCountry];

    final defaultCities = _countryCities[_selectedCountry];
    _selectedCity =
        (defaultCities != null && defaultCities.isNotEmpty)
            ? defaultCities.first
            : null;
    _countryController.text = _selectedCountry ?? '';
    _cityController.text = _selectedCity ?? '';

    // Set phone controller listener to format number
    _phoneController.addListener(_formatPhoneNumber);
  }

  void _formatPhoneNumber() {
    // Remove listener to prevent infinite loop
    _phoneController.removeListener(_formatPhoneNumber);

    String text = _phoneController.text;
    final code = _selectedCountryCode ?? '+255';

    // Remove all non-digits except plus
    String digitsOnly = text.replaceAll(RegExp(r'[^0-9+]'), '');

    // If starts with 0, remove it
    if (digitsOnly.startsWith('0')) {
      digitsOnly = digitsOnly.substring(1);
    }

    // Remove country code if user typed it
    final codeDigits = code.replaceAll('+', '');
    if (digitsOnly.startsWith(codeDigits)) {
      digitsOnly = digitsOnly.substring(codeDigits.length);
    }

    // Limit to reasonable length
    if (digitsOnly.length > 10) {
      digitsOnly = digitsOnly.substring(0, 10);
    }

    // Update text without country code prefix in the field
    _phoneController.value = _phoneController.value.copyWith(
      text: digitsOnly,
      selection: TextSelection.collapsed(offset: digitsOnly.length),
    );

    // Re-add listener
    _phoneController.addListener(_formatPhoneNumber);
  }

  String _getFormattedPhoneNumber() {
    String phoneDigits = _phoneController.text.trim();
    if (phoneDigits.isEmpty) return '';

    // Remove any non-digit characters
    phoneDigits = phoneDigits.replaceAll(RegExp(r'[^0-9]'), '');

    // If starts with 0, remove it
    if (phoneDigits.startsWith('0')) {
      phoneDigits = phoneDigits.substring(1);
    }

    // Add country code
    final code = _selectedCountryCode ?? '+255';
    return '$code$phoneDigits';
  }

  String _getPhoneDisplayText() {
    String phoneDigits = _phoneController.text.trim();
    if (phoneDigits.isEmpty) return '';

    // Format for display: e.g., 076 123 4567
    if (phoneDigits.length <= 3) {
      return phoneDigits;
    } else if (phoneDigits.length <= 6) {
      return '${phoneDigits.substring(0, 3)} ${phoneDigits.substring(3)}';
    } else {
      return '${phoneDigits.substring(0, 3)} ${phoneDigits.substring(3, 6)} ${phoneDigits.substring(6)}';
    }
  }

  Future<void> _handleRegister() async {
    if (!_acceptTerms) {
      Fluttertoast.showToast(
        msg: 'Please accept terms and conditions',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final authController = Provider.of<AuthController>(
        context,
        listen: false,
      );

      // Get formatted phone number with country code
      final formattedPhone = _getFormattedPhoneNumber();

      final success = await authController.register(
        email: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        phoneNumber: formattedPhone,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        country: _countryController.text.trim(),
        city: _cityController.text.trim(),
      );

      if (mounted) {
        if (success) {
          Fluttertoast.showToast(
            msg: 'Account created successfully!',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.TOP,
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreeenNav()),
            (route) => false,
          );
        } else {
          Fluttertoast.showToast(
            msg: authController.errorMessage ?? 'Registration failed',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.TOP,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      }
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
      prefixIcon: Icon(icon, color: skyBlue, size: 20),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: skyBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: isSmallScreen ? 20 : 32),

                  // Logo and Title
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 58,
                        height: 80,
                        child: Image.asset("assets/images/logo.png"),
                      ),
                      const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: skyBlue,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: isSmallScreen ? 10 : 18),

                  // Full Name
                  TextFormField(
                    controller: _fullNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _buildInputDecoration(
                      'Full Name',
                      Icons.person_outline_rounded,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (value.length < 3) return 'Min 3 characters';
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _buildInputDecoration(
                      'Email Address',
                      Icons.email_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (!value.contains('@') || !value.contains('.'))
                        return 'Invalid email';
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  // Phone Number with Country Code
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phone Number',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Country Code Dropdown
                          Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCountry,
                                items:
                                    _countryCities.keys.map((country) {
                                      return DropdownMenuItem<String>(
                                        value: country,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                _countryFlags[country] ??
                                                    '🇺🇳',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                _countryDialCodes[country] ??
                                                    '+255',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _selectedCountry = value;
                                    _selectedCountryCode =
                                        _countryDialCodes[value];
                                    _countryController.text = value;
                                    // Update city list
                                    final cities = _countryCities[value];
                                    _selectedCity =
                                        (cities != null && cities.isNotEmpty)
                                            ? cities.first
                                            : null;
                                    _cityController.text = _selectedCity ?? '';
                                  });
                                },
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: skyBlue,
                                ),
                                isDense: true,
                                isExpanded: false,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Phone Number Input
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                hintText: '76 123 4567',
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: skyBlue,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 1,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: const Icon(
                                  Icons.phone_outlined,
                                  color: skyBlue,
                                  size: 20,
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'Required';
                                final digitsOnly = value.replaceAll(
                                  RegExp(r'[^0-9]'),
                                  '',
                                );
                                if (digitsOnly.length < 7)
                                  return 'Invalid phone number';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Full number: ${_getFormattedPhoneNumber().isEmpty ? "Will be displayed here" : _getFormattedPhoneNumber()}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Country and City in a Row
                  DropdownButtonFormField<String>(
                    value: _selectedCountry,
                    items:
                        _countryCities.keys.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Row(
                              children: [
                                Text(_countryFlags[c] ?? '🇺🇳'),
                                const SizedBox(width: 8),
                                Text(c, style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedCountry = value;
                        _selectedCountryCode = _countryDialCodes[value];
                        _countryController.text = value;
                        final cities = _countryCities[value];
                        _selectedCity =
                            (cities != null && cities.isNotEmpty)
                                ? cities.first
                                : null;
                        _cityController.text = _selectedCity ?? '';
                      });
                    },
                    decoration: _buildInputDecoration(
                      'Country',
                      Icons.public_rounded,
                    ),
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedCity,
                    items:
                        (_selectedCountry != null
                                ? _countryCities[_selectedCountry] ?? []
                                : [])
                            .map<DropdownMenuItem<String>>((city) {
                              return DropdownMenuItem<String>(
                                value: city,
                                child: Text(
                                  city,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            })
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCity = value;
                        _cityController.text = value ?? '';
                      });
                    },
                    decoration: _buildInputDecoration(
                      'City',
                      Icons.location_city_rounded,
                    ),
                    validator: (value) => value == null ? 'Required' : null,
                  ),

                  const SizedBox(height: 12),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: _buildInputDecoration(
                      'Password',
                      Icons.lock_outline_rounded,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        onPressed:
                            () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (value.length < 6) return 'Min 6 characters';
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  // Confirm Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: _buildInputDecoration(
                      'Confirm Password',
                      Icons.lock_outline_rounded,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        onPressed:
                            () => setState(
                              () =>
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                            ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (value != _passwordController.text)
                        return 'Passwords must match';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Terms Checkbox
                  Row(
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: Checkbox(
                          value: _acceptTerms,
                          onChanged:
                              (value) =>
                                  setState(() => _acceptTerms = value ?? false),
                          activeColor: skyBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap:
                              () =>
                                  setState(() => _acceptTerms = !_acceptTerms),
                          child: Text(
                            'I agree to the Terms & Conditions',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: isSmallScreen ? 20 : 24),

                  // Register Button
                  Consumer<AuthController>(
                    builder: (context, auth, child) {
                      return Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [lightSkyBlue, skyBlue, deepSkyBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: skyBlue.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child:
                              auth.isLoading
                                  ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Text(
                                    'CREATE ACCOUNT',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: isSmallScreen ? 16 : 20),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      TextButton(
                        onPressed:
                            () => Navigator.pushReplacementNamed(
                              context,
                              '/login',
                            ),
                        style: TextButton.styleFrom(
                          foregroundColor: skyBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: isSmallScreen ? 16 : 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
