import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FormDokter extends StatefulWidget {
  final Map<String, dynamic>? dataDoctor;
  const FormDokter({super.key, this.dataDoctor});

  @override
  State<FormDokter> createState() => _FormDokterState();
}

class _FormDokterState extends State<FormDokter> {
  final doctorsRef = FirebaseFirestore.instance.collection('doctors');
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _specialistController = TextEditingController();
  final TextEditingController _roomCodeController = TextEditingController();
  String docID = "";
  bool isLoading = false;
  bool isUpdate = false;

  @override
  void initState() {
    super.initState();
    if (widget.dataDoctor != null) {
      isUpdate = true;
      docID = widget.dataDoctor!['docID'];
      _nameController.text = widget.dataDoctor!['name'];
      _specialistController.text = widget.dataDoctor!['specialist'];
      _roomCodeController.text = widget.dataDoctor!['room_code'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specialistController.dispose();
    _roomCodeController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        if (isUpdate) {
          await doctorsRef.doc(docID).update({
            'name': _nameController.text,
            'specialist': _specialistController.text,
            'room_code': _roomCodeController.text,
            'active': true,
            'created_at': DateTime.now(),
          });
        } else {
          await doctorsRef.add({
            'name': _nameController.text,
            'specialist': _specialistController.text,
            'room_code': _roomCodeController.text,
            'active': true,
            'created_at': DateTime.now(),
          });
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Doctor information saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Clear the form fields
        _nameController.clear();
        _specialistController.clear();
        _roomCodeController.clear();
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving doctor information: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        title: Text('${isUpdate ? "Ubah Data" : 'Tambah'} Dokter'),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
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
                    return 'Please enter the doctor\'s name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _specialistController,
                decoration: InputDecoration(
                  labelText: 'Specialist',
                  prefixIcon: Icon(
                    Icons.medical_services,
                    color: Colors.green[700],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green[700]!),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the specialist field';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _roomCodeController,
                decoration: InputDecoration(
                  labelText: 'Room Code',
                  prefixIcon: Icon(Icons.room, color: Colors.green[700]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green[700]!),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the room code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child:
                      isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                            isUpdate ? "Update" : 'Submit',
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
}
