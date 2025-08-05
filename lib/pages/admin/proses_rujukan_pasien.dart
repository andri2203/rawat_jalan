import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProsesRujukanPasien extends StatefulWidget {
  final Map<String, dynamic> patient;
  final List<Map<String, dynamic>> doctors;
  const ProsesRujukanPasien({
    super.key,
    required this.patient,
    required this.doctors,
  });

  @override
  State<ProsesRujukanPasien> createState() => _ProsesRujukanPasienState();
}

class _ProsesRujukanPasienState extends State<ProsesRujukanPasien> {
  List<Map<String, dynamic>> doctors = <Map<String, dynamic>>[];
  final _formKey = GlobalKey<FormState>();
  String? selectedDoctorId;
  DateTime? selectedDateTime;
  bool isLoading = false;
  bool isUpdate = false;
  bool isDone = false;

  @override
  void initState() {
    super.initState();
    doctors = widget.doctors;
    isDone = widget.patient['status'] == 'selesai';
  }

  String statusUpdate() {
    if (widget.patient['status'] == 'menunggu') {
      return 'disetujui';
    } else if (widget.patient['status'] == 'disetujui') {
      return 'selesai';
    } else {
      return 'menunggu';
    }
  }

  String formattedDate(rawDate) {
    // Parsing string manual ke DateTime
    DateTime dateTime = rawDate.toDate();
    // Format ke tampilan yang kamu inginkan
    return DateFormat('dd MMMM yyyy h:mm:ss').format(dateTime);
  }

  Future<void> _selectDateTime(BuildContext context) async {
    // Step 1: pilih tanggal
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    // Step 2: jika user batal memilih, keluar
    if (pickedDate == null) return;

    // Step 3: pilih waktu
    final pickedTime = await showTimePicker(
      // ignore: use_build_context_synchronously
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );

    // Step 4: jika user batal, keluar
    if (pickedTime == null) return;

    // Step 5: pastikan widget masih hidup
    if (!context.mounted) return;

    // Step 6: setState aman dipanggil
    setState(() {
      selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      // Fetch existing appointments for the selected doctor
      QuerySnapshot existingAppointments =
          await FirebaseFirestore.instance
              .collection('appointments')
              .where('janji_temu.doctor_id', isEqualTo: selectedDoctorId)
              .get();

      // Determine the next queue number
      int nextQueueNumber = 1; // Default to 1 if no existing appointments
      if (existingAppointments.docs.isNotEmpty) {
        // Find the highest queue number
        List<int> queueNumbers =
            existingAppointments.docs.map((doc) {
              final dynamic value = doc['janji_temu']['antrian'];
              if (value is int) return value;
              if (value is String) return int.tryParse(value) ?? 0;
              return 0;
            }).toList();
        nextQueueNumber =
            queueNumbers.isNotEmpty
                ? queueNumbers.reduce((a, b) => a > b ? a : b) + 1
                : 1;
      }

      Map<String, dynamic> updateData = {
        'janji_temu': {
          'doctor_id': selectedDoctorId,
          'tanggal': selectedDateTime,
          'antrian': nextQueueNumber,
        },
        'status': isUpdate ? "disetujui" : statusUpdate(),
        'created_at': DateTime.now(),
      };

      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.patient['appointmentUID'])
          .update(updateData);

      if (mounted) {
        // JIa Sukses
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('gagal Update: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool isTodayOrPast(DateTime visitDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final visit = DateTime(visitDate.year, visitDate.month, visitDate.day);

    return visit.isBefore(today) || visit.isAtSameMomentAs(today);
  }

  int countDaysFromToday(DateTime visitDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final visit = DateTime(visitDate.year, visitDate.month, visitDate.day);

    return visit.difference(today).inDays;
  }

  Future<void> pemeriksaanSelesai() async {
    setState(() {
      isLoading = true;
    });
    if (!isTodayOrPast(
      (widget.patient['janji_temu']['tanggal'] as Timestamp).toDate(),
    )) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pemeriksaan Pasien Masih ${countDaysFromToday((widget.patient['janji_temu']['tanggal'] as Timestamp).toDate())} hari lagi',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.patient['appointmentUID'])
          .update({'status': "selesai", 'created_at': DateTime.now()});

      if (mounted) {
        // JIa Sukses
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('gagal Update: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
        title: const Text('Proses Rujukan Pasien'),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Card(
                color: isDone ? Colors.green[300] : Colors.grey.shade200,
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: ListTile(
                    title: Text(
                      widget.patient['pasien']['nama'],
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Keluhan Pasien :',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Column(
                          children:
                              widget.patient['keluhan']
                                  .map<Widget>(
                                    (keluhan) => Row(
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          size: 8,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          keluhan,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.format_list_numbered,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Status: ${widget.patient['status']}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if ((widget.patient['janji_temu'] as Map<String, dynamic>)
                  .isNotEmpty)
                cardDoctor(context),
              if ((widget.patient['janji_temu'] as Map<String, dynamic>)
                      .isEmpty ||
                  isUpdate == true)
                formPengajuan(context),
              if (widget.patient['status'] == 'disetujui')
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isLoading) return;
                      pemeriksaanSelesai();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child:
                        isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : const Text(
                              'Pemeriksaan Selesai',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget cardDoctor(BuildContext context) {
    final visit = widget.patient;
    final janjiTemu = visit['janji_temu'] as Map<String, dynamic>;
    final doctor = doctors.firstWhere(
      (doc) => doc['docID'] == janjiTemu['doctor_id'],
      orElse: () => {}, // akan return Map kosong jika tidak ketemu
    );

    return Card(
      color: Colors.green[100],
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          doctor['name'] ?? 'Dokter tidak ditemukan',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              doctor['specialist'],
              style: TextStyle(color: Colors.grey[800], fontSize: 13),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[800]),
                const SizedBox(width: 5),
                Text(
                  formattedDate(janjiTemu["tanggal"]),
                  style: TextStyle(color: Colors.grey[800], fontSize: 13),
                ),
                const SizedBox(width: 15),
                Icon(
                  Icons.format_list_numbered,
                  size: 14,
                  color: Colors.grey[800],
                ),
                const SizedBox(width: 5),
                Text(
                  'Queue: ${doctor['room_code']}-${janjiTemu['antrian']}',
                  style: TextStyle(color: Colors.grey[800], fontSize: 13),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  '${visit['status'] == 'menunggu' ? 'dibuat' : visit['status']} pada: ${formattedDate(visit["created_at"])}',
                  style: TextStyle(color: Colors.grey[800], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          isDone ? Icons.check : Icons.edit,
          color: Colors.green[700],
        ),
        onTap: () {
          if (isDone == false) {
            setState(() {
              isUpdate = true;
              selectedDoctorId = doctor['docID'];
              selectedDateTime = (janjiTemu["tanggal"] as Timestamp).toDate();
            });
          }
        },
      ),
    );
  }

  Widget formPengajuan(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Selection Dropdown
            DropdownButtonFormField<String?>(
              value: selectedDoctorId,
              decoration: InputDecoration(
                labelText: 'Select Doctor',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items:
                  doctors.map((doctor) {
                    return DropdownMenuItem<String?>(
                      value: doctor['docID'],
                      child: Text(
                        "${doctor['name']} - ${doctor['specialist']}",
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedDoctorId = value;
                  });
                }
              },
              validator: (value) {
                if (value == null || value == '') {
                  return 'Please select a doctor';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),

            // DateTime Picker
            TextFormField(
              onTap: () => _selectDateTime(context),
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Appointment Date',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _selectDateTime(context),
                ),
              ),
              controller: TextEditingController(
                text:
                    selectedDateTime != null
                        ? "${selectedDateTime!.day}/${selectedDateTime!.month}/${selectedDateTime!.year} ${selectedDateTime!.hour}:${selectedDateTime!.minute}"
                        : '',
              ),
              validator: (value) {
                if (selectedDateTime == null) {
                  return 'Please select a date';
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
                onPressed: isLoading ? () {} : _submitForm,
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
                          isUpdate == true ? "Update" : 'Submit',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
              ),
            ),
            const SizedBox(height: 10),
            // Cancel Update Button
            if (isUpdate == true)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isUpdate = false;
                      selectedDoctorId = null;
                      selectedDateTime = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
