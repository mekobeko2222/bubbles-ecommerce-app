import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter and FilteringTextInputFormatter

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>(); // Key for form validation

  // Controllers for editable profile data (e.g., display name, shipping address, phone)
  final _displayNameController = TextEditingController(); // For display name
  String? _selectedArea; // For shipping area dropdown
  final _buildingNumberController = TextEditingController();
  final _floorNumberController = TextEditingController();
  final _apartmentNumberController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  bool _isLoading = true; // State to show loading indicator while fetching/saving data

  @override
  void initState() {
    super.initState();
    _loadUserProfileData(); // Load existing user data on screen initialization
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _buildingNumberController.dispose();
    _floorNumberController.dispose();
    _apartmentNumberController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  // Fetches user profile data from FirebaseAuth and Firestore
  Future<void> _loadUserProfileData() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false; // Stop loading if no user is logged in
      });
      return;
    }

    // Initialize display name from FirebaseAuth
    _displayNameController.text = user.displayName ?? '';

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!mounted) return;

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        final defaultAddress = userData['defaultAddress'] as Map<String, dynamic>?;

        // Populate shipping address fields from Firestore if available
        setState(() {
          _selectedArea = defaultAddress?['area'] as String?;
          _buildingNumberController.text = defaultAddress?['buildingNumber'] ?? '';
          _floorNumberController.text = defaultAddress?['floorNumber'] ?? '';
          _apartmentNumberController.text = defaultAddress?['apartmentNumber'] ?? '';
          _phoneNumberController.text = defaultAddress?['phoneNumber'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading user profile data: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile data: ${e.toString()}')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false; // Stop loading after data fetch attempt
      });
    }
  }

  // Saves user profile data to FirebaseAuth and Firestore
  Future<void> _saveUserProfileData() async {
    if (!_formKey.currentState!.validate()) {
      return; // Stop if form validation fails
    }

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in.')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Show loading indicator during save
    });

    try {
      // 1. Update display name in Firebase Authentication
      if (_displayNameController.text.trim() != (user.displayName ?? '')) {
        await user.updateDisplayName(_displayNameController.text.trim());
      }

      // 2. Update default address and phone in Firestore
      await _firestore.collection('users').doc(user.uid).set(
        {
          'defaultAddress': {
            'area': _selectedArea,
            'buildingNumber': _buildingNumberController.text.trim(),
            'floorNumber': _floorNumberController.text.trim(),
            'apartmentNumber': _apartmentNumberController.text.trim(),
            'phoneNumber': _phoneNumberController.text.trim(),
          },
          // You can add other user-specific data here if needed
        },
        SetOptions(merge: true), // Use merge: true to update existing fields without overwriting
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile data saved successfully!')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update authentication data: ${e.message}')),
      );
      print('Firebase Auth Error saving profile: $e');
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile data to database: ${e.message}')),
      );
      print('Firestore Error saving profile: $e');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: ${e.toString()}')),
      );
      print('General Error saving profile: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  // Basic validation for Egyptian phone numbers
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }
    final phoneRegex = RegExp(r'^(010|011|012|015)[0-9]{8}$'); // Matches 010/011/012/015 followed by 8 digits
    final cleanNumber = value.replaceAll(RegExp(r'[^0-9]'), ''); // Remove non-digits
    if (!phoneRegex.hasMatch(cleanNumber)) {
      return 'Please enter a valid Egyptian phone number (e.g., 010xxxxxxxxx)';
    }
    return null;
  }

  // Generic required field validator
  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      // Should not happen if navigation is guarded, but as a fallback
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          centerTitle: true,
        ),
        body: const Center(
          child: Text('You are not logged in. Please log in to view your profile.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading spinner
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Picture/Avatar
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: user.photoURL == null || user.photoURL!.isEmpty
                      ? Icon(
                    Icons.person,
                    size: 60,
                    color: Theme.of(context).colorScheme.primary,
                  )
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // Display Name Input (now editable)
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => _validateRequired(value, 'Display Name'),
              ),
              const SizedBox(height: 15),

              // User Email (Non-editable, for display)
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.email, color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Email: ${user.email ?? 'N/A'}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Text(
                'Default Shipping Address',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              // Area Dropdown
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('areas').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('Error loading areas: ${snapshot.error}');
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('No shipping areas available. Please contact support.');
                  }

                  final List<String> availableAreas = snapshot.data!.docs
                      .map((doc) => doc['name'] as String)
                      .toList();

                  // Ensure _selectedArea is valid if it was loaded from data
                  // Use WidgetsBinding.instance.addPostFrameCallback to avoid setState during build
                  if (_selectedArea != null && !availableAreas.contains(_selectedArea)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _selectedArea = null; // Clear if previously selected area is no longer valid
                      });
                    });
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedArea,
                    hint: const Text('Select Shipping Area'),
                    decoration: const InputDecoration(
                      labelText: 'Shipping Area',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    items: availableAreas.map((String area) {
                      return DropdownMenuItem<String>(
                        value: area,
                        child: Text(area),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedArea = newValue;
                      });
                    },
                    validator: (value) => _validateRequired(value, 'Shipping Area'),
                  );
                },
              ),
              const SizedBox(height: 15),

              // Building Number
              TextFormField(
                controller: _buildingNumberController,
                decoration: const InputDecoration(
                  labelText: 'Building Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  prefixIcon: Icon(Icons.apartment),
                ),
                validator: (value) => _validateRequired(value, 'Building Number'),
              ),
              const SizedBox(height: 15),

              // Floor Number
              TextFormField(
                controller: _floorNumberController,
                decoration: const InputDecoration(
                  labelText: 'Floor Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  prefixIcon: Icon(Icons.layers),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => _validateRequired(value, 'Floor Number'),
              ),
              const SizedBox(height: 15),

              // Apartment Number
              TextFormField(
                controller: _apartmentNumberController,
                decoration: const InputDecoration(
                  labelText: 'Apartment Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  prefixIcon: Icon(Icons.door_front_door),
                ),
                validator: (value) => _validateRequired(value, 'Apartment Number'),
              ),
              const SizedBox(height: 15),

              // Phone Number
              TextFormField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  prefixIcon: Icon(Icons.phone),
                  hintText: '010xxxxxxxxx', // Example hint for Egyptian number
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // Allow only digits
                  LengthLimitingTextInputFormatter(11), // Limit to 11 digits
                ],
                validator: _validatePhoneNumber,
              ),
              const SizedBox(height: 30),

              // Save Changes Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveUserProfileData, // Disable when loading
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: _isLoading ? const Text('Saving...') : const Text('Save Changes', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 5,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Optional: Section for changing password (placeholder/future feature)
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Change Password functionality (Coming Soon)!')),
                    );
                    // TODO: Implement actual password change logic or navigate to a dedicated screen
                  },
                  icon: const Icon(Icons.lock_reset),
                  label: const Text('Change Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
