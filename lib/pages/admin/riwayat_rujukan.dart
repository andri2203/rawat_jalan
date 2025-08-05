import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rawat_jalan/pages/admin/proses_rujukan_pasien.dart';

class RiwayatRujukan extends StatefulWidget {
  const RiwayatRujukan({super.key});

  @override
  State<RiwayatRujukan> createState() => _RiwayatRujukanState();
}

class _RiwayatRujukanState extends State<RiwayatRujukan> {
  final patiensRef = FirebaseFirestore.instance.collection('users');
  final doctorsRef = FirebaseFirestore.instance.collection('doctors');
  final appointmentsRef = FirebaseFirestore.instance.collection('appointments');

  Map<String, dynamic> patients = {};
  List<Map<String, dynamic>> doctors = [];
  List<Map<String, dynamic>> appointments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  String formattedDate(rawDate) {
    // Parsing string manual ke DateTime
    DateTime dateTime = rawDate.toDate();
    // Format ke tampilan yang kamu inginkan
    return DateFormat('dd MMMM yyyy h:mm:ss').format(dateTime);
  }

  Future<void> refresh() async {
    setState(() {
      isLoading = true;
    });
    final snapPatiens = await patiensRef.get();
    final snapDoctor =
        await doctorsRef.orderBy('created_at', descending: true).get();
    final snapAppointments =
        await appointmentsRef.orderBy('created_at', descending: true).get();

    if (snapPatiens.docs.isEmpty && snapAppointments.docs.isEmpty) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    setState(() {
      patients = Map.fromEntries(
        snapPatiens.docs
            .where((doc) => doc.id != "fsFmGfyYYhMNHPX3NYIzv1TUqBu1")
            .map((doc) => MapEntry(doc.id, doc.data())),
      );
      doctors =
          snapDoctor.docs
              .where((doc) => doc.data()['active'] == true)
              .map((doc) => {'docID': doc.id, ...doc.data()})
              .toList();
      if (snapAppointments.docs.isNotEmpty) {
        appointments =
            snapAppointments.docs.map((doc) {
              return {
                'appointmentUID': doc.id,
                'pasien': patients[doc['uid']],
                ...doc.data(),
              };
            }).toList();
      }
      isLoading = false;
    });
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
        title: const Text('Riwayat Rujukan'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: refresh,
          ),
        ],
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 15,
                ),
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final patient = appointments[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ProsesRujukanPasien(
                                    patient: patient,
                                    doctors: doctors,
                                  ),
                            ),
                          ).then((_) {
                            if (mounted) {
                              refresh();
                            }
                          });
                        },
                        title: Text(
                          patient['pasien']['nama'],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              "Pengajuan dibuat pada ${formattedDate(patient['created_at'])}",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
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
                                  'Status: ${patient['status']}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
