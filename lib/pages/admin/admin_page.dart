import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:rawat_jalan/pages/admin/cetak_laporan.dart';
import 'package:rawat_jalan/pages/admin/data_dokter.dart';
import 'package:rawat_jalan/pages/admin/proses_rujukan_pasien.dart';
import 'package:rawat_jalan/pages/admin/riwayat_rujukan.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
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
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    final snapPatiens = await patiensRef.get();
    final snapDoctor =
        await doctorsRef.orderBy('created_at', descending: true).get();
    final snapAppointments =
        await appointmentsRef
            .where('status', isNotEqualTo: 'selesai')
            .orderBy('created_at', descending: true)
            .get();

    if (!mounted) return;

    if (snapPatiens.docs.isEmpty && snapAppointments.docs.isEmpty) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (mounted) {
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
  }

  Future<void> logout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Yakin ingin keluar?"),
            content: const Text(
              "Apakah Anda yakin ingin keluar? Tenang, Anda dapat kembali nanti",
            ),
            actions: [
              TextButton(
                child: const Text("Tidak"),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Ya"),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Janji temu berhasil dibatalkan."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal membatalkan: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                    decoration: BoxDecoration(
                      color: Colors.green[700],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hello, Admin',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${patients.length} Pasien Mendaftar',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.white,
                              ),
                              onPressed: refresh,
                            ),
                            IconButton(
                              onPressed: logout,
                              icon: Icon(
                                Icons.exit_to_app,
                                color: Colors.red.shade600,
                                size: 30,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Button Section
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.history,
                          label: 'Riwayat Rujukan',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RiwayatRujukan(),
                              ),
                            ).then((_) {
                              if (mounted) {
                                refresh();
                              }
                            });
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.medical_services,
                          label: 'Data Dokter',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DataDokter(),
                              ),
                            ).then((_) {
                              if (mounted) {
                                refresh();
                              }
                            });
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.print_rounded,
                          label: 'Cetak Laporan',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CetakLaporan(),
                              ),
                            ).then((_) {
                              if (mounted) {
                                refresh();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // List Title
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 10),
                    margin: EdgeInsets.only(bottom: 10, left: 10, right: 10),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rujukan Pasien',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          'Lihat Semua',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (appointments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "Belum ada pengajuan. Pengajuan berstatus 'menunggu' atau 'disetujui' akan muncul disini",
                      ),
                    ),

                  // List Section
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    "Pengajuan ${patient['status'] == 'menunggu' ? 'dibuat' : patient['status']} pada ${formattedDate(patient['created_at'])}",
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
                  ),
                ],
              ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.green[50],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: Colors.green[700]),
          ),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(color: Colors.green[700])),
        ],
      ),
    );
  }
}
