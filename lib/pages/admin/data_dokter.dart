import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rawat_jalan/pages/admin/form_dokter.dart';

class DataDokter extends StatefulWidget {
  const DataDokter({super.key});

  @override
  State<DataDokter> createState() => _DataDokterState();
}

class _DataDokterState extends State<DataDokter> {
  final doctorsRef = FirebaseFirestore.instance.collection('doctors');
  List<Map<String, dynamic>> doctors = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() {
      isLoading = true;
    });

    final snapshot =
        await doctorsRef.orderBy('created_at', descending: true).get();

    if (snapshot.docs.isEmpty) {
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data Docter Belum ada'),
            backgroundColor: Colors.red,
          ),
        );
      }

      return;
    }

    final dataDoctors =
        snapshot.docs.map((doc) => {'docID': doc.id, ...doc.data()}).toList();

    setState(() {
      doctors = dataDoctors;
      isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil memuat data docter'),
          backgroundColor: Colors.green,
        ),
      );
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
        title: const Text('Data Dokter'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FormDokter()),
              ).then((_) {
                if (mounted) {
                  refresh();
                }
              });
            },
          ),
        ],
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 15,
                ),
                itemCount: doctors.length,
                itemBuilder: (context, i) {
                  final doctor = doctors[i];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      title: Text(
                        doctor['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      trailing:
                          doctor['active'] == true
                              ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => FormDokter(
                                                dataDoctor: doctor,
                                              ),
                                        ),
                                      ).then((_) {
                                        if (mounted) {
                                          refresh();
                                        }
                                      });
                                    },
                                    child: Icon(
                                      Icons.edit,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () async {
                                      final isDelete = await showDialog<bool>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text(
                                              "Yakin ingin di hapus / di non aktifkan?",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            content: const Text(
                                              "Dokter akan dihapus jika belum memiliki riyawat rujukan. dan di nonaktifkan jika telah memiliki riwayat rujukan.",
                                            ),
                                            actions: [
                                              TextButton(
                                                child: const Text("Tidak"),
                                                onPressed:
                                                    () => Navigator.of(
                                                      context,
                                                    ).pop(false),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                ),
                                                child: const Text("Ya"),
                                                onPressed:
                                                    () => Navigator.of(
                                                      context,
                                                    ).pop(true),
                                              ),
                                            ],
                                          );
                                        },
                                      );

                                      if (isDelete == true) {
                                        setState(() {
                                          isLoading = true;
                                        });
                                        try {
                                          // Cek apakah doctor_id masih dipakai di appointments
                                          final appointmentCheck =
                                              await FirebaseFirestore.instance
                                                  .collection('appointments')
                                                  .where(
                                                    'janji_temu.doctor_id',
                                                    isEqualTo: doctor['docID'],
                                                  )
                                                  .limit(1)
                                                  .get();

                                          // Jika ditemukan appointment yang masih pakai doctor ini
                                          if (appointmentCheck
                                              .docs
                                              .isNotEmpty) {
                                            await doctorsRef
                                                .doc(doctor['docID'])
                                                .update({'active': false});

                                            refresh();

                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    "Doctor ${doctor['name']} Di non Aktifkan.",
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            }

                                            return; // hentikan proses hapus
                                          } else {
                                            await doctorsRef
                                                .doc(doctor['docID'])
                                                .delete();

                                            refresh();

                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    "Doctor ${doctor['name']} Berhasil di hapus.",
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            }
                                          }
                                        } catch (e) {
                                          setState(() {
                                            isLoading = false;
                                          });
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "Terjadi Kesalahan: $e",
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    },
                                    child: Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              )
                              : TextButton.icon(
                                onPressed: () async {
                                  setState(() {
                                    isLoading = true;
                                  });
                                  try {
                                    await doctorsRef
                                        .doc(doctor['docID'])
                                        .update({'active': true});

                                    refresh();

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Doctor ${doctor['name']} Di Aktifkan Kembali.",
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setState(() {
                                      isLoading = false;
                                    });
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Terjadi Kesalahan: $e",
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                label: Text("Aktifkan Kembali"),
                                icon: Icon(
                                  Icons.check_box,
                                  color: Colors.green,
                                ),
                              ),
                      subtitle:
                          doctor['active'] == true
                              ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        doctor['specialist'],
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Icon(
                                        Icons.local_hospital,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Koda Ruangan: ${doctor['room_code']}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                              : Text(
                                'Status Dokter: Tidak Aktif',
                                style: TextStyle(
                                  color: Colors.red[600],
                                  fontSize: 13,
                                ),
                              ),
                    ),
                  );
                },
              ),
    );
  }
}
