import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rawat_jalan/pages/appointment_form_page.dart';

class DetailJanjiTemu extends StatefulWidget {
  final Map<String, dynamic> data;
  final Map<String, dynamic>? doctor;
  const DetailJanjiTemu({super.key, required this.data, this.doctor});

  @override
  State<DetailJanjiTemu> createState() => _DetailJanjiTemuState();
}

class _DetailJanjiTemuState extends State<DetailJanjiTemu> {
  Map<String, dynamic> data = {};
  Map<String, dynamic> doctor = {};
  Map<String, dynamic> janjiTemu = {};
  List<dynamic> keluhanList = [];
  DocumentReference<Map<String, dynamic>> appointmentRef() =>
      FirebaseFirestore.instance.collection('appointments').doc(data['docID']);
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    data = widget.data;
    doctor = widget.doctor ?? {};
    janjiTemu = data['janji_temu'] as Map<String, dynamic>? ?? {};
    keluhanList = (data['keluhan'] as List<dynamic>?) ?? [];
    isLoading = false;
  }

  String formattedDate(Timestamp rawDate) {
    DateTime dateTime = rawDate.toDate();
    return DateFormat('dd MMMM yyyy h:mm:ss').format(dateTime);
  }

  String status() {
    switch (data['status']) {
      case 'menunggu':
        return "Sedang Diverifikasi";
      case 'disetujui':
        return "Data Telah Diverifikasi pada ${formattedDate(data['created_at'])}";
      case 'selesai':
        return "Janji temu telah selesai pada ${formattedDate(data['created_at'])}";
      default:
        return "Sedang Diverifikasi";
    }
  }

  Future<void> batalkanJanjiTemu() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Batalkan Janji Temu"),
            content: const Text(
              "Apakah Anda yakin ingin membatalkan janji temu ini?",
            ),
            actions: [
              TextButton(
                child: const Text("Tidak"),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Ya, Batalkan"),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
    );

    // Jika user memilih 'Tidak' atau menutup dialog
    if (confirm != true) return;

    // Proses pembatalan
    try {
      await appointmentRef().delete();

      if (mounted) {
        Navigator.pop(context);

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

  Future<void> refreshData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final snapshot = await appointmentRef().get();

      setState(() {
        data = {'docID': snapshot.id, ...?snapshot.data()};
        janjiTemu = data['janji_temu'] as Map<String, dynamic>? ?? {};
        keluhanList = (data['keluhan'] as List<dynamic>?) ?? [];
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data berhasil di perbaharui'),
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
        title: const Text('Detail Janji Temu'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: refreshData,
          ),
        ],
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[600],
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ),
                        child: Text(
                          status(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      if (janjiTemu.isEmpty)
                        Card(
                          margin: const EdgeInsets.only(top: 12, bottom: 12),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            // contentPadding: const EdgeInsets.all(10),
                            title: Text(
                              "Pengajuan dibuat pada ${formattedDate(data['created_at'])}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),

                      if (janjiTemu.isNotEmpty)
                        Card(
                          margin: const EdgeInsets.only(top: 12, bottom: 12),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              doctor['name'] ?? '-',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  doctor["specialist"] ?? '-',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      janjiTemu["tanggal"] != null
                                          ? formattedDate(janjiTemu["tanggal"])
                                          : '-',
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
                                      'Queue: ${doctor['room_code']}-${janjiTemu['antrian']}',
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
                              Icons.local_hospital,
                              color: Colors.green[700],
                            ),
                          ),
                        ),

                      Container(
                        margin: EdgeInsets.symmetric(vertical: 10),
                        padding: EdgeInsets.all(10),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Keluhan Anda',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 15),
                            ListView.builder(
                              itemCount: keluhanList.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, i) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 5,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.circle, size: 10),
                                      const SizedBox(width: 10),
                                      Text(keluhanList[i].toString()),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      if (data['status'] == 'menunggu')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: batalkanJanjiTemu,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text(
                                "Batalkan Janji Temu",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (context) => AppointmentFormPage(
                                          isUpdate: true,
                                          docID: data['docID'],
                                          keluhan: keluhanList,
                                          onFinished: refreshData,
                                        ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text(
                                "Tambah Keluhan",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
    );
  }
}
