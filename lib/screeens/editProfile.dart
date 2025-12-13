import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kaluu_Epreess_Cargo/auths/auth_controller.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _EmailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // Blue sky color scheme
  static const Color skyBlue = Color(0xFF4A90E2);
  static const Color lightSkyBlue = Color(0xFF87CEEB);
  static const Color deepSkyBlue = Color(0xFF2E73B8);

  // Country -> cities mapping
  final Map<String, List<String>> _countryCities = {
    'Tanzania': ['Dar es Salaam', 'Mwanza', 'Dodoma', 'Shinyanga', 'Arusha'],
    'Congo': ['Kinshasa', 'Lubumbashi', 'Goma', 'Kisangani', 'Bukavu'],
    'Kenya': ['Nairobi', 'Mombasa', 'Kisumu', 'Nakuru', 'Eldoret'],
    'Rwanda': ['Kigali', 'Huye', 'Rubavu', 'Musanze', 'Rwamagana'],
    'Burundi': ['Bujumbura', 'Gitega', 'Ngozi', 'Muyinga', 'Ruyigi'],
  };

  String? _selectedCountry;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final auth = Provider.of<AuthController>(context, listen: false);
    _fullNameController.text = auth.userName ?? '';
    _EmailController.text = auth.userEmail ?? '';
    _phoneController.text = auth.phoneNumber ?? '';
    _selectedCountry = auth.country ?? 'Tanzania';
    _selectedCity = auth.city ?? 'Dar es Salaam';
    _countryController.text = _selectedCountry ?? '';
    _cityController.text = _selectedCity ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _EmailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to pick image: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Choose Photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: skyBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt, color: skyBlue),
              ),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: skyBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library, color: skyBlue),
              ),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpdateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthController>(context, listen: false);
      
      final success = await auth.updateProfile(
        fullName: _fullNameController.text.trim(),
        email: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        city: _selectedCity ?? '',
        country: _selectedCountry ?? '',
        profilePicture: _selectedImage?.path,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        
        if (success) {
          Fluttertoast.showToast(
            msg: 'Profile updated successfully!',
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
          Navigator.pop(context);
        } else {
          Fluttertoast.showToast(
            msg: auth.errorMessage ?? 'Failed to update profile',
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(
          msg: 'Error: $e',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: skyBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: skyBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Profile Picture Section
                Consumer<AuthController>(
                  builder: (context, auth, child) {
                    return Stack(
                      children: [
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                lightSkyBlue.withOpacity(0.3),
                                skyBlue.withOpacity(0.2)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: skyBlue.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: _selectedImage != null
                              ? ClipOval(
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                    width: 130,
                                    height: 130,
                                  ),
                                )
                              : auth.profilePicture != null &&
                                      auth.profilePicture!.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        auth.profilePicture!,
                                        fit: BoxFit.cover,
                                        width: 130,
                                        height: 130,
                                        errorBuilder: (context, error, stack) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [lightSkyBlue, skyBlue],
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Colors.white,
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [lightSkyBlue, skyBlue],
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.white,
                                      ),
                                    ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showImageSourceDialog,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [lightSkyBlue, skyBlue],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: skyBlue.withOpacity(0.4),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 10),
                Text(
                  'Tap to change photo',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 30),

                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _buildInputDecoration('Full Name', Icons.person_outline_rounded),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (value.length < 3) return 'Min 3 characters';
                    return null;
                  },
                ),

                const SizedBox(height: 16),
                 TextFormField(
                  controller: _EmailController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _buildInputDecoration('Email', Icons.email_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (value.length < 3) return 'Min 3 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Phone Number
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _buildInputDecoration('Phone Number', Icons.phone_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (value.length < 10) return 'Invalid phone';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

            // Country and City in a Row
                DropdownButtonFormField<String>(
                  value: _selectedCountry,
                  items: _countryCities.keys
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c, style: const TextStyle(fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedCountry = value;
                      _countryController.text = value;
                      final cities = _countryCities[value];
                      _selectedCity = (cities != null && cities.isNotEmpty)
                          ? cities.first
                          : null;
                      _cityController.text = _selectedCity ?? '';
                    });
                  },
                  decoration: _buildInputDecoration('Country', Icons.public_rounded),
                  validator: (value) => value == null ? 'Required' : null,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: (_selectedCity != null &&
                          _selectedCountry != null &&
                          _countryCities[_selectedCountry]?.contains(_selectedCity) == true)
                      ? _selectedCity
                      : null,
                  items: (_selectedCountry != null ? _countryCities[_selectedCountry] ?? <String>[] : <String>[])
                      .map<DropdownMenuItem<String>>((city) => DropdownMenuItem<String>(
                            value: city,
                            child: Text(city, style: const TextStyle(fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCity = value;
                      _cityController.text = value ?? '';
                    });
                  },
                  decoration: _buildInputDecoration('City', Icons.location_city_rounded),
                  validator: (value) => value == null ? 'Required' : null,
                ),

                const SizedBox(height: 40),

                // Update Button
                Container(
                  height: 52,
                  width: double.infinity,
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
                    onPressed: _isLoading ? null : _handleUpdateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'UPDATE PROFILE',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}