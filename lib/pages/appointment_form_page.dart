import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppointmentFormPage extends StatefulWidget {
  final bool isUpdate;
  final String docID;
  final List keluhan;
  final VoidCallback onFinished;

  const AppointmentFormPage({
    super.key,
    this.isUpdate = false,
    this.docID = "",
    this.keluhan = const [],
    this.onFinished = _emptyCallback,
  });

  static void _emptyCallback() {}

  @override
  State<AppointmentFormPage> createState() => _AppointmentFormPageState();
}

class _AppointmentFormPageState extends State<AppointmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  List<TextEditingController> _complaintControllers = [];
  final currentUser = FirebaseAuth.instance.currentUser;
  final appointmentRef = FirebaseFirestore.instance.collection('appointments');
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.isUpdate == true) {
      _complaintControllers = List.generate(
        widget.keluhan.length,
        (i) => TextEditingController(text: widget.keluhan[i]),
      );
    } else {
      _complaintControllers = [TextEditingController()];
    }
  }

  Future<void> makeAppointment() async {
    if (_formKey.currentState!.validate()) {
      if (currentUser == null) {
        return;
      }

      setState(() {
        isLoading = true;
      });
      // Process the appointment
      final complaints = _complaintControllers.map((c) => c.text).toList();

      try {
        await appointmentRef.add({
          'uid': currentUser!.uid,
          'keluhan': complaints,
          'janji_temu': {},
          'created_at': DateTime.now(),
          'status': 'menunggu',
        });

        setState(() {
          isLoading = false;
        });

        if (mounted) {
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Janji temu berhasil dibuat. Nomor antrian, Dokter dan ruangan akan di tambahkan oleh admin.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Terjadi Kesalahan : ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> updateAppointment() async {
    if (_formKey.currentState!.validate()) {
      if (currentUser == null) {
        return;
      }

      setState(() {
        isLoading = true;
      });
      // Process the appointment
      final complaints = _complaintControllers.map((c) => c.text).toList();

      try {
        await appointmentRef.doc(widget.docID).update({'keluhan': complaints});

        setState(() {
          isLoading = false;
        });

        if (mounted) {
          widget.onFinished();
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Keluhan baru berhasil ditambahkan'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Terjadi Kesalahan : ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _addComplaintField() {
    setState(() {
      _complaintControllers.add(TextEditingController());
    });
  }

  void _removeComplaintField(int index) {
    if (_complaintControllers.length > 1) {
      setState(() {
        _complaintControllers[index].dispose();
        _complaintControllers.removeAt(index);
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _complaintControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Janji Temu'),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Complaints Section
              const Text(
                'Keluhan Medis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Jelaskan gejala dan kekhawatiran Anda',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 15),
              Column(
                children: List.generate(_complaintControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _complaintControllers[index],
                            maxLines: 3,
                            enabled: isLoading == false,
                            decoration: InputDecoration(
                              hintText: 'Penjelasan Keluhan ${index + 1}',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.green[700]!,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Tolong Jelaskan Keluhan ${index + 1}';
                              }
                              return null;
                            },
                          ),
                        ),
                        if (index > 0)
                          IconButton(
                            icon: Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _removeComplaintField(index),
                          ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _addComplaintField,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[50],
                    foregroundColor: Colors.green[700],
                  ),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Tambah Keluhan Lain'),
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      widget.isUpdate == true
                          ? updateAppointment
                          : makeAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child:
                      isLoading
                          ? CircularProgressIndicator()
                          : Text(
                            widget.isUpdate
                                ? "Update Keluhan"
                                : 'Buat Janji Temu',
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
