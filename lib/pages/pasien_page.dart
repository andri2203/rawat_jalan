import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rawat_jalan/pages/appointment_form_page.dart';
import 'package:rawat_jalan/pages/detail_janji_temu.dart';
import 'package:rawat_jalan/pages/patient_card_page.dart';
import 'package:rawat_jalan/pages/user_data_page.dart';
import 'package:intl/intl.dart';

class PasienPage extends StatefulWidget {
  const PasienPage({super.key});

  @override
  State<PasienPage> createState() => _PasienPageState();
}

class _PasienPageState extends State<PasienPage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final userRef = FirebaseFirestore.instance.collection('users');
  final doctorRef = FirebaseFirestore.instance.collection('doctors');
  final appointmentRef = FirebaseFirestore.instance.collection('appointments');
  Map<String, dynamic>? user;
  Map<String, dynamic> doctors = {};

  @override
  void initState() {
    super.initState();
    getUserInformation();
    getDoctorInformation();
  }

  Future<void> getUserInformation() async {
    if (currentUser != null) {
      final snap = await userRef.doc(currentUser!.uid).get();

      setState(() {
        user = snap.data()!;
      });
    }
  }

  Future<void> getDoctorInformation() async {
    final snap = await doctorRef.get();

    setState(() {
      doctors = Map.fromEntries(
        snap.docs.map((doc) => MapEntry(doc.id, doc.data())),
      );
    });
  }

  String formattedDate(rawDate) {
    // Parsing string manual ke DateTime
    DateTime dateTime = rawDate.toDate();
    // Format ke tampilan yang kamu inginkan
    return DateFormat('dd MMMM yyyy h:mm:ss').format(dateTime);
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
            content: Text("Berhasil Logout"),
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
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
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
                    Text(
                      'Hi, ${user == null ? "" : user!['nama']}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'NIK : ${user == null ? "" : user!['nik']}',
                      style: TextStyle(fontSize: 14, color: Colors.white60),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: logout,
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
                _buildDashboardButton(
                  icon: Icons.add_circle_outline,
                  label: 'Buat Janji Temu',
                  onPressed: () {
                    if (user == null) {
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppointmentFormPage(),
                      ),
                    );
                  },
                ),
                _buildDashboardButton(
                  icon: Icons.credit_card,
                  label: 'Kartu Pasien',
                  onPressed: () {
                    if (user == null) {
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => PatientCardPage(
                              nik: user!['nik'],
                              name: user!['nama'],
                              birthDate: user!['tanggalLahir'],
                              address: user!['alamat'],
                              phone: user!['noHP'],
                            ),
                      ),
                    );
                  },
                ),
                _buildDashboardButton(
                  icon: Icons.person_outline,
                  label: 'Data Diri Saya',
                  onPressed: () {
                    if (user == null) {
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => UserDataPage(
                              user: currentUser!,
                              userData: user,
                              onFinished: () {
                                getUserInformation();
                              },
                            ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // History Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Riwayat Janji Temu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // History List Section
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream:
                  appointmentRef
                      .where('uid', isEqualTo: currentUser!.uid)
                      .orderBy('created_at', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.data == null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 5,
                    ),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: Center(
                          child: Text(
                            "Belum ada janji temu",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                final data =
                    snapshot.data?.docs.map((dt) {
                      return {'docID': dt.id, ...dt.data()};
                    }).toList();

                return ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  itemCount: data!.length,
                  itemBuilder: (context, index) {
                    final visit = data[index];
                    final janjiTemu =
                        visit['janji_temu'] as Map<String, dynamic>;
                    final doctor =
                        doctors[janjiTemu['doctor_id']]
                            as Map<String, dynamic>?;
                    bool isWaiting = visit['status'] == 'menunggu';
                    bool approved = visit['status'] == 'disetujui';
                    bool isDone = visit['status'] == 'selesai';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          isWaiting
                              ? "Permohonan sedang Diverifikasi"
                              : doctor != null
                              ? doctor['name']
                              : "-",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            if (approved || isDone)
                              Text(
                                doctor != null ? doctor['specialist'] : "-",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            if (approved || isDone) const SizedBox(height: 6),
                            if (approved || isDone)
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    formattedDate(janjiTemu["tanggal"]),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Icon(
                                    Icons.format_list_numbered,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    doctor != null
                                        ? 'Queue: ${doctor['room_code']}-${janjiTemu['antrian']}'
                                        : "-",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Janji Temu Anda Telah ${visit['status'] == 'menunggu'
                                        ? 'Dibuat'
                                        : visit['status'] == 'disetujui'
                                        ? 'Diverifikasi'
                                        : "Selesai"} Pada: ${formattedDate(visit["created_at"])}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
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
                        onTap: () {
                          // View visit details
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => DetailJanjiTemu(
                                    data: visit,
                                    doctor: doctor ?? {},
                                  ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, size: 32, color: Colors.green[700]),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[800], fontSize: 12),
          ),
        ],
      ),
    );
  }
}
