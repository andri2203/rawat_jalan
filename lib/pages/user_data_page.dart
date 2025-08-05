import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserDataPage extends StatefulWidget {
  final User user;
  final Map<String, dynamic>? userData;
  final VoidCallback onFinished;
  const UserDataPage({
    super.key,
    required this.user,
    required this.onFinished,
    this.userData,
  });

  @override
  State<UserDataPage> createState() => _UserDataPageState();
}

class _UserDataPageState extends State<UserDataPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final userRef = FirebaseFirestore.instance.collection('users');
  late DocumentReference<Map<String, dynamic>> docRef;

  @override
  void initState() {
    super.initState();
    docRef = userRef.doc(widget.user.uid);

    if (widget.userData == null) {
      _nameController.text = widget.user.displayName!;
    } else {
      _nikController.text = widget.userData!['nik'];
      _nameController.text = widget.userData!['nama'];
      _birthDateController.text = widget.userData!['tanggalLahir'];
      _addressController.text = widget.userData!['alamat'];
      _phoneController.text = widget.userData!['noHP'];
    }
  }

  Future<void> handleSavePatientInformation() async {
    Map<String, dynamic> input = {
      'nik': _nikController.text.trim(),
      'nama': _nameController.text.trim(),
      'tanggalLahir': _birthDateController.text.trim(),
      'alamat': _addressController.text.trim(),
      'noHP': _phoneController.text.trim(),
    };

    if (widget.userData == null) {
      await docRef.set(input);
    } else {
      if (widget.user.displayName != _nameController.text) {
        widget.user.updateDisplayName(_nameController.text);
      }
      await docRef.update(input);
      if (mounted) {
        Navigator.pop(context);
      }
    }

    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informasi Pasien'),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // NIK Field
              TextFormField(
                controller: _nikController,
                decoration: InputDecoration(
                  labelText: 'NIK',
                  prefixIcon: Icon(Icons.credit_card, color: Colors.green[700]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green[700]!),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your NIK';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Full Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person, color: Colors.green[700]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green[700]!),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Date of Birth Field
              TextFormField(
                controller: _birthDateController,
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  prefixIcon: Icon(
                    Icons.calendar_today,
                    color: Colors.green[700],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green[700]!),
                  ),
                ),
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    String formattedDate = DateFormat(
                      'dd-MM-yyyy',
                    ).format(pickedDate);
                    setState(() {
                      _birthDateController.text = formattedDate;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your birth date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Address Field
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.home, color: Colors.green[700]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green[700]!),
                  ),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Phone Number Field
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone, color: Colors.green[700]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green[700]!),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Process user data
                      handleSavePatientInformation();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Patient data saved successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Save Information',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nikController.dispose();
    _nameController.dispose();
    _birthDateController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
